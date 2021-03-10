(define-private (to-ustx (stx uint))
    (* stx u1000000))

;; should be voted on
(define-data-var minmum-ustx-threshold uint (to-ustx u100))

(define-map evangelist {} {})

(define-private (do-delegate (amount uint) (until-block-ht uint)) 
    (contract-call? 'ST000000000000000000002AMW42H.pox delegate-stx (to-ustx amount) (as-contract tx-sender) until-block-ht none))

;; user must send allow-contract caller before anything
(define-public (delegate-for-me (amount uint) (until-block-ht uint)) 
    ())
    
