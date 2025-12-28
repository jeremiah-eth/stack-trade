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
        created-at: uint
    }
)

;; Market pools: market-id -> pool data
(define-map market-pools
    uint
    {
        yes-pool: uint,
        no-pool: uint,
        total-yes-tokens: uint,
        total-no-tokens: uint
    }
)

;; ============================================
;; INITIALIZATION
;; ============================================

;; Initialize contract with market counter at 0
;; Markets will start from ID 1
