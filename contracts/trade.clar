;; Trade contract 
;; Users can buy or sell tokens 

;; Store user balances
(define-map balances 
    principal 
    uint
)

;; Track total supply
(define-data-var total-supply uint u0)

;; ------------------------------------------------------------
;; PUBLIC: Buy tokens
;; Users can buy tokens - only gas fees required
;; ------------------------------------------------------------
(define-public (buy (amount uint))
    (let (
          (sender tx-sender)
          (current-balance (default-to u0 (map-get? balances sender)))
         )
        (begin
            ;; Update user balance
            (map-set balances sender (+ current-balance amount))
            
            ;; Update total supply
            (var-set total-supply (+ (var-get total-supply) amount))
            
            (ok { 
                action: "buy", 
                amount: amount, 
                new-balance: (+ current-balance amount)
            })
        )
    )
)

;; ------------------------------------------------------------
;; PUBLIC: Sell tokens
;; Users can sell tokens - only gas fees required
;; ------------------------------------------------------------
(define-public (sell (amount uint))
    (let (
          (sender tx-sender)
          (current-balance (default-to u0 (map-get? balances sender)))
         )
        (begin
            ;; Check if user has enough balance
            (asserts! (>= current-balance amount) (err u1))
            
            ;; Update user balance
            (map-set balances sender (- current-balance amount))
            
            ;; Update total supply
            (var-set total-supply (- (var-get total-supply) amount))
            
            (ok { 
                action: "sell", 
                amount: amount, 
                new-balance: (- current-balance amount)
            })
        )
    )
)

;; ------------------------------------------------------------
;; READ-ONLY: Get user balance
;; ------------------------------------------------------------
(define-read-only (get-balance (user principal))
    (ok (default-to u0 (map-get? balances user)))
)

;; ------------------------------------------------------------
;; READ-ONLY: Get total supply
;; ------------------------------------------------------------
(define-read-only (get-total-supply)
    (ok (var-get total-supply))
)
