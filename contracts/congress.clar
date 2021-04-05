(use-trait congress-action .action-trait.congress-action)

(define-constant ACTION-STATUS-COMPLETE u0)
(define-constant ACTION-STATUS-REJECTED u1)
(define-constant REJECTION-THRESHOLD u25)


(define-data-var population-count uint u0)

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


(define-public (add-person (person-id principal)) 
  (begin 
    (map-insert population-data {id: person-id} {kicked: false})
    (increase-pop)
    ))


(define-map congress-actions
  {
    action: principal,
  }
  {
    status: uint,
  })


;; TODO: Implement decision making algorthim that then
;; executes this function



(define-private (execute-action (action <congress-action>)) 
  (begin 
    (asserts! (is-ok (contract-call? action execute))
      (err u0))
    (map-set congress-actions {action: action} {status: ACTION-STATUS-COMPLETE})))