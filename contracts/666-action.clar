(define-constant congress .congress)

;; Deposit
;; Vote

(define-public (execute) 
  (begin 
    (asserts! (is-eq contract-caller congress) 
      (err u1000))
    (ok none)))