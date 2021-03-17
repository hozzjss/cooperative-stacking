;; How much a subscription costs
;; TODO: Make this a variable that can be changed by the contract creator
(define-constant subscription-value-in-ustx u100000000)
;; The contract address in the blockchain
(define-constant contract (as-contract tx-sender))

(define-constant creator tx-sender)

(define-constant ERR-UNAUTHORIZED u401)
(define-constant ERR-PAYMENT-FAILED u402)


;; The subscribers registry
(define-map subscribers 
  {id: principal}

  {valid-until: uint}
)

(define-public (subscribe (months uint)) 
  (let (
    ;; How much uSTX is a subscriber supposed to pay
    ;; for the totality of months they want to subscribe
    (total-cost (* months subscription-value-in-ustx))
    
    ;; For how long will this subscription be valid
    ;; TODO: Extend current subscriptions
    (subscriber-data (default-to {valid-until: block-height} (map-get? subscribers {id: tx-sender})))
    (current-sub-validity (get valid-until subscriber-data))
    (is-renewing (< current-sub-validity block-height))
    
    (valid-until (+ block-height (* u5000 months)))

    ;; Transfer the money to the contract to complete the payment
    (did-send-payment 
      (is-ok (stx-transfer? total-cost tx-sender contract)))
  ) 

    ;; Check if the payment was processed successfully or not
    (asserts! did-send-payment 
    
    ;; if not through a payment error
      (err ERR-PAYMENT-FAILED))

    ;; if the payment was processed add the subscriber to the registry
    (map-set subscribers {id: tx-sender} {valid-until: valid-until})
    (ok true)))


;; only the owner of this contract may collect its revenue
(define-public (collect-revenue) 
  (begin 
    (asserts! (is-owner) (err ERR-UNAUTHORIZED))
    (stx-transfer? (get-revenue) contract creator)))


;; anyone can audit how much money the subscription made
(define-read-only (get-revenue) 
  (stx-get-balance contract))


(define-private (is-owner) 
  (is-eq tx-sender creator))
