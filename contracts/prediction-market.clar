;; Prediction Market Contract
;; Decentralized prediction markets with binary outcomes (YES/NO)

;; ============================================
;; CONSTANTS
;; ============================================

;; Market status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-RESOLVED u2)
(define-constant STATUS-CANCELLED u3)

;; Market outcomes
(define-constant OUTCOME-YES u1)
(define-constant OUTCOME-NO u2)

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Error codes
(define-constant ERR-INVALID-QUESTION (err u100))
(define-constant ERR-INVALID-DATE (err u101))

;; ============================================
;; DATA STRUCTURES
;; ============================================

;; Market counter for unique IDs
(define-data-var market-counter uint u0)

;; Markets map: market-id -> market data
(define-map markets
    uint
    {
        question: (string-ascii 256),
        creator: principal,
        resolution-date: uint,
        status: uint,
        outcome: (optional uint),
        created-at: uint,
    }
)

;; Market pools: market-id -> pool data
(define-map market-pools
    uint
    {
        yes-pool: uint,
        no-pool: uint,
        total-yes-tokens: uint,
        total-no-tokens: uint,
    }
)

;; User positions: market-id + user -> balance data
(define-map user-positions
    {
        market-id: uint,
        user: principal,
    }
    {
        yes-balance: uint,
        no-balance: uint,
    }
)

;; Market stats: market-id -> volume data
(define-map market-stats
    uint
    {
        volume: uint,
        tx-count: uint,
    }
)

;; ============================================
;; INITIALIZATION
;; ============================================

;; Initialize contract with market counter at 0
;; Markets will start from ID 1

;; ============================================
;; PUBLIC FUNCTIONS
;; ============================================

;; Create a new prediction market
(define-public (create-market
        (question (string-ascii 256))
        (resolution-date uint)
    )
    (let ((new-id (+ (var-get market-counter) u1)))
        ;; Validations
        (asserts! (> (len question) u0) ERR-INVALID-QUESTION)
        ;; Resolution date must be in the future (using block height)
        (asserts! (> resolution-date block-height) ERR-INVALID-DATE)

        ;; Create market
        (map-insert markets new-id {
            question: question,
            creator: tx-sender,
            resolution-date: resolution-date,
            status: STATUS-ACTIVE,
            outcome: none,
            created-at: block-height,
        })

        ;; Transfer initial liquidity (20 STX) from creator
        (try! (stx-transfer? u20000000 tx-sender (as-contract tx-sender)))

        ;; Initialize market pool with 10 STX worth of YES and NO
        (map-insert market-pools new-id {
            yes-pool: u10000000,
            no-pool: u10000000,
            total-yes-tokens: u10000000,
            total-no-tokens: u10000000,
        })

        ;; Initialize market stats
        (map-insert market-stats new-id {
            volume: u0,
            tx-count: u0,
        })

        ;; Update counter
        (var-set market-counter new-id)

        (ok new-id)
    )
)

;; Buy YES tokens
(define-public (buy-yes (market-id uint) (amount uint))
    (let
        (
            (market-data (unwrap! (map-get? markets market-id) (err u404)))
            (pool-data (unwrap! (map-get? market-pools market-id) (err u404)))
            (user-data (default-to {yes-balance: u0, no-balance: u0} (map-get? user-positions {market-id: market-id, user: tx-sender})))
            
            ;; Fee calculation (2%)
            (fee (/ (* amount u2) u100))
            (net-amount (- amount fee))
            
            ;; Pool state
            (yes-pool (get yes-pool pool-data))
            (no-pool (get no-pool pool-data))
            
            ;; CPMM Calculation
            ;; Mint `net-amount` YES and NO tokens
            ;; Swap `net-amount` NO tokens for YES tokens
            ;; dy = yes_pool - (yes_pool * no_pool) / (no_pool + net_amount)
            (dy (- yes-pool (/ (* yes-pool no-pool) (+ no-pool net-amount))))
            (tokens-out (+ net-amount dy))
        )
        ;; Checks
        (asserts! (is-eq (get status market-data) STATUS-ACTIVE) (err u403))
        
        ;; Transfer STX
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update Maps
        
        ;; 1. Update Pools
        ;; yes-pool decreases by dy (gave out YES)
        ;; no-pool increases by net-amount (received NO from mint stake)
        (map-set market-pools market-id
            (merge pool-data {
                yes-pool: (- yes-pool dy),
                no-pool: (+ no-pool net-amount),
                total-yes-tokens: (+ (get total-yes-tokens pool-data) net-amount)
            })
        )
        
        ;; 2. Update User Position
        (map-set user-positions {market-id: market-id, user: tx-sender}
            (merge user-data {
                yes-balance: (+ (get yes-balance user-data) tokens-out)
            })
        )
        
        ;; 3. Update Stats
        (let
            (
                (stats (default-to {volume: u0, tx-count: u0} (map-get? market-stats market-id)))
            )
            (map-set market-stats market-id
                {
                    volume: (+ (get volume stats) amount),
                    tx-count: (+ (get tx-count stats) u1)
                }
            )
        )
        
        (ok tokens-out)
    )
)

;; Buy NO tokens
(define-public (buy-no (market-id uint) (amount uint))
    (let
        (
            (market-data (unwrap! (map-get? markets market-id) (err u404)))
            (pool-data (unwrap! (map-get? market-pools market-id) (err u404)))
            (user-data (default-to {yes-balance: u0, no-balance: u0} (map-get? user-positions {market-id: market-id, user: tx-sender})))
            
            ;; Fee calculation (2%)
            (fee (/ (* amount u2) u100))
            (net-amount (- amount fee))
            
            ;; Pool state
            (yes-pool (get yes-pool pool-data))
            (no-pool (get no-pool pool-data))
            
            ;; CPMM Calculation
            ;; Mint `net-amount` YES and NO tokens
            ;; Swap `net-amount` YES tokens for NO tokens
            ;; dy = no_pool - (no_pool * yes_pool) / (yes_pool + net_amount)
            (dy (- no-pool (/ (* no-pool yes-pool) (+ yes-pool net-amount))))
            (tokens-out (+ net-amount dy))
        )
        ;; Checks
        (asserts! (is-eq (get status market-data) STATUS-ACTIVE) (err u403))
        
        ;; Transfer STX
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Update Maps
        
        ;; 1. Update Pools
        ;; no-pool decreases by dy (gave out NO)
        ;; yes-pool increases by net-amount (received YES from mint stake)
        (map-set market-pools market-id
            (merge pool-data {
                yes-pool: (+ yes-pool net-amount),
                no-pool: (- no-pool dy),
                total-no-tokens: (+ (get total-no-tokens pool-data) net-amount)
            })
        )
        
        ;; 2. Update User Position
        (map-set user-positions {market-id: market-id, user: tx-sender}
            (merge user-data {
                no-balance: (+ (get no-balance user-data) tokens-out)
            })
        )
        
        ;; 3. Update Stats
        (let
            (
                (stats (default-to {volume: u0, tx-count: u0} (map-get? market-stats market-id)))
            )
            (map-set market-stats market-id
                {
                    volume: (+ (get volume stats) amount),
                    tx-count: (+ (get tx-count stats) u1)
                }
            )
        )
        
        (ok tokens-out)
    )
)

;; Resolve market (Creator only)
(define-public (resolve-market (market-id uint) (outcome uint))
    (let
        (
            (market-data (unwrap! (map-get? markets market-id) (err u404)))
        )
        ;; Checks
        ;; 1. Only creator can resolve (or contract owner if needed)
        (asserts! (is-eq tx-sender (get creator market-data)) (err u401))
        ;; 2. Market must be active
        (asserts! (is-eq (get status market-data) STATUS-ACTIVE) (err u403))
        ;; 3. Resolution date must be reached
        (asserts! (>= block-height (get resolution-date market-data)) (err u405))
        ;; 4. Valid outcome
        (asserts! (or (is-eq outcome OUTCOME-YES) (is-eq outcome OUTCOME-NO)) (err u400))
        
        ;; Update market status
        (map-set markets market-id
            (merge market-data {
                status: STATUS-RESOLVED,
                outcome: (some outcome)
            })
        )
        (ok true)
    )
)

;; Claim winnings
(define-public (claim-winnings (market-id uint))
    (let
        (
            (market-data (unwrap! (map-get? markets market-id) (err u404)))
            (user-data (unwrap! (map-get? user-positions {market-id: market-id, user: tx-sender}) (err u404)))
            (outcome (unwrap! (get outcome market-data) (err u400)))
            (claimer tx-sender)
        )
        ;; Checks
        ;; 1. Market must be resolved
        (asserts! (is-eq (get status market-data) STATUS-RESOLVED) (err u403))
        
        ;; 2. Determine winning amount
        (let
            (
                (winning-amount (if (is-eq outcome OUTCOME-YES)
                                    (get yes-balance user-data)
                                    (get no-balance user-data)))
            )
            ;; 3. Must have winnings
            (asserts! (> winning-amount u0) (err u404))
            
            ;; 4. Update user position to 0 to prevent double claim
            (map-set user-positions {market-id: market-id, user: claimer}
                (merge user-data {
                    yes-balance: u0,
                    no-balance: u0
                })
            )
            
            ;; 5. Transfer STX
            (as-contract (stx-transfer? winning-amount tx-sender claimer))
        )
    )
)
