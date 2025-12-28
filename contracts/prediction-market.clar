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

        ;; Initialize market pool
        (map-insert market-pools new-id {
            yes-pool: u0,
            no-pool: u0,
            total-yes-tokens: u0,
            total-no-tokens: u0,
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
