(define-public (execute-action)
  (stx-burn? (stx-get-balance tx-sender) tx-sender))