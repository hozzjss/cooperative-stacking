(use-trait congress-action .action-trait.congress-action)

(define-constant ACTION-STATUS-INCOMPLETE u0)
(define-constant ACTION-STATUS-COMPLETE u1)
(define-constant ACTION-STATUS-REJECTED u2)
(define-constant REJECTION-THRESHOLD u25)
(define-constant ERROR-UNAUTHORIZED u1000)
(define-constant ERROR-CONTRACT-INACTIVE u1001)
(define-constant contract-address (as-contract tx-sender))
(define-constant action-initial-data {status: ACTION-STATUS-INCOMPLETE, votes: u0})
(define-constant DISAGREEMENT-INTERVAL u2000)


(define-data-var population-count uint u0)
(define-data-var is-active bool true)

(define-private (increase-pop)
  (var-set population-count (+ (var-get population-count) u1)))

(define-map population-data 
  {
    id: principal,
  }
  {
    kicked: bool,
  }
)

(define-map congress-actions
  {
    action: principal,
  }
  {
    created-at: uint,
    status: uint,
  })

(map-insert congress-actions {action: contract-address} {status: ACTION-STATUS-INCOMPLETE})

(define-public (vote-against (action <congress-action>))
  (let
    (
      (action-data (map-get? congress-actions {action: action}))
      (action-existed-beforehand (is-some action-data))
    )
    (asserts! (is-contract-active) 
      (err ERROR-CONTRACT-INACTIVE))
    (asserts! (is-a-member tx-sender)
      (err ERROR-UNAUTHORIZED))
    (asserts! action-existed-beforehand
      (err ERROR-UNAUTHORIZED))
    (map-set congress-actions {action: action} 
      (merge (unwrap-panic action-data) {status: ACTION-STATUS-REJECTED}))))


(define-public (execute-action (action <congress-action>))
  (let
    (
      (action-data (map-get? congress-actions {action: action}))
      (action-existed-beforehand (is-some action-data))
    )
    (asserts! (is-contract-active) 
      (err ERROR-CONTRACT-INACTIVE))
    (asserts! (is-a-member tx-sender)
      (err ERROR-UNAUTHORIZED))
    (asserts! action-existed-beforehand
      (err ERROR-UNAUTHORIZED))
    (let (
      (action-unwrapped (unwrap-panic action-data))
      (status (get status action-unwrapped))
      (created-at (get created-at action-unwrapped))
    )
      (asserts! (is-eq status ACTION-STATUS-INCOMPLETE)
        (err ERROR-UNAUTHORIZED))
      (asserts! (> (+ created-at DISAGREEMENT-INTERVAL) block-height)
        (err ERROR-UNAUTHORIZED))
      (contract-call? action execute)
    )
)

(define-public (schedule-action (action <congress-action>)) 
  (let
    (
      (action-existed-beforehand (is-some (map-get? congress-actions {action: action})))
    )
    (asserts! (is-contract-active) 
      (err ERROR-CONTRACT-INACTIVE))
    (asserts! (and (is-a-member tx-sender) (not action-existed-beforehand))
      (err ERROR-UNAUTHORIZED))
    
    ;; Either the action is delayed until it has no disagreements
    ;; or it would have voting
    (map-set congress-actions {action: action} {created-at: block-height, status: ACTION-STATUS-INCOMPLETE})))



(define-public (add-person (person-id principal)) 
  (begin
    (asserts! (is-contract-active) 
      (err ERROR-CONTRACT-INACTIVE))
    (asserts! (is-a-member tx-sender) 
      (err ERROR-UNAUTHORIZED))
    (map-insert population-data {id: person-id} {kicked: false})
    (increase-pop)
    ))

(define-public (deactivate) 
  (begin 
    (asserts! (is-contract-active) 
      (err ERROR-CONTRACT-INACTIVE))
    (asserts! (is-a-member tx-sender) 
      (err ERROR-UNAUTHORIZED))
    (var-set is-active false)))



(define-read-only (is-a-member (id principal)) 
  (is-some (map-get? population-data {id: tx-sender})))

(define-read-only (is-contract-active)  
  (var-get is-active))


(begin 
  (map-insert population-data {id: tx-sender} {kicked: false})
  (increase-pop)
)