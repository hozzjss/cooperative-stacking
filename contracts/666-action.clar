(define-constant bear-contract .bear-contract)

;; Deposit STX
;; Deposit NFTS
;; Deposit FTS
;; Opinions
;; Election over a constitution
;; Vote


(define-public (execute) 
  (begin 
    (asserts! (is-eq contract-caller bear-contract) 
      (err u1000))
    ;; transfer money to someone to buy a laptop
    (ok none)))