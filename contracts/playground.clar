(define-read-only (get-my-balance (address principal)) 
  (ok (stx-get-balance address)))