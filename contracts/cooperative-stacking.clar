(define-public (stack-stx) 
    (contract-call? 
        'ST000000000000000000002AMW42H.pox 
        stack-stx u100000000000000 {hashbytes: 0x83a2c9ebbdedebd6f2c4fde942f1e1141140aeaa, version: 0x6f} burn-block-height u1
    )))

(define-public (deposit (amount uint))
    (stx-transfer? tx-sender (as-contract tx-sender) amount))


(define-read-only (get-balance)
    (stx-get-balance (as-contract tx-sender)))