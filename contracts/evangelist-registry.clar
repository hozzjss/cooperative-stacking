;; an action shouldn't exceed these limits
(define-constant points-estimations (list u1 u2 u3 u5 u8 u13))

(define-constant REFERRING-LIMIT u3)
(define-constant ERR-NO-SUCH-EVANGELIST u1001)
(define-constant ERR-APPLICATIONS-CLOSED u1002)
(define-constant ERR-EXCEEDED-REFER-LIMIT u1003)


(define-data-var applicants-count uint u0)
(define-map evangelists 
  {
    evangelist-address: principal
  } 
  {
    ;; current points that are not redeemed as of yet
    ;; points are cleared each time after pox ends by 200 blocks
    ;; or might be cleared after submitting the reward distribution tx hash
    ;; at some point adding points should be frozen so that clearing it can happen
    ;; in an easy manner
    ;; after the points lock period when releasing btc funds ends e.g. 100 blocks
    ;; you can submit new actions and new estimations
    ;; the choice of int here is for people with low reputation or malicious people
    ;; this system would prevent such people from doing malicious activity
    ;; and would ban them automatically from receiving rewards
    ;; negative points shall not be cleared
    ;; having such an environment would encourage dogoodery and discourage malicious activity
    points: int,
    ;; all user points ever
    reputation: int,
    ;; the user would set their preferred payout btc address
    btc-address: (string-utf8 100),
    ;; an evangelist might refer a max of 3 applicants per cycle
    referred-this-cycle: uint
  }
)

(define-map evangelist-applicants 
  {
    evangelist-address: principal
  }
  {
    ;; totals should reach a threshold
    ;; if the applicant kept that threshold they're accepted
    total-points: int
  }
)
(define-private (is-evangelist) 
  (if
    (is-some (map-get? evangelists {evangelist-address: tx-sender}))
    (ok true)
    (err ERR-NO-SUCH-EVANGELIST)
  ))

(define-private (is-there-capacity) 
  (if 
    (< (var-get applicants-count) u10)
    (ok true)
    (err ERR-APPLICATIONS-CLOSED)))


(define-private (is-evangelist-not-past-referring-limit) 
  (let 
    (
      (evangelist (map-get? evangelists {evangelist-address: tx-sender}))
      (referred-count (get referred-this-cycle evangelist))
    )
    (if (< referred-count REFERRING-LIMIT)
      (ok true)
    (err ERR-EXCEEDED-REFER-LIMIT)))


(define-private (check-err  (result (response bool uint))
                            (prior (response bool uint)))
  (match prior  ok-value result
                err-value (err err-value)))

(define-private (add-applicant (id principal))
  (map-set evangelist-applicants {id: id} {total-points: 0}))

(define-public (refer-evangelist (id principal)) 
  ;; current applicants number must not exceed 10 at a time
  (if 
    (unwrap-panic 
      (fold check-err 
        (list
          (is-there-capacity)
          (is-evangelist)
          (is-evangelist-not-past-referring-limit)) (ok true)))
    (ok (add-applicant id))
  (err EXCEEDS-CAPACITY)))
