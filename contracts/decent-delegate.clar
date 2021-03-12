;; this token would be awarded at the end of each successful cycle
;; and would be taken away if the cycle failed to produce the promised STX
;; in the same way this would be for a delegate who failed to
;; deliver on their pledge
;; the decent token is burnt
;; a delegate gets only 12 chances of being a decent person
(define-fungible-token decent-delegate-reputation u12)
(ft-mint? decent-delegate-reputation u12 contract-address)




;; TODO: ENV
;; (define-constant first-burnchain-block-height u666050)
;; (define-constant reward-cycle-length u2100)
;; (define-constant prepare-cycle-length u100)
(define-constant reward-cycle-length u50)
(define-constant first-burnchain-block-height u1931620)
(define-constant prepare-cycle-length u10)

(define-constant ERROR-ummm-this-is-a-PEOPLE-contract u1000)
(define-constant ERROR-you-poor-lol u1001)
(define-constant ERROR-this-aint-a-donation-box u1002)
(define-constant ERROR-wtf-stacks!!! u1003)
(define-constant ERROR-not-my-president! u1004)
(define-constant ERROR-didnt-we-just-go-through-this-the-other-day u1005)
(define-constant ERROR-only-current-cycle-bro! u1006)
(define-constant ERROR-i-have-never-met-this-man-in-my-life u1007)
(define-constant ERROR-you-cant-get-any-awesomer u1008)
(define-constant ERROR-you-had-12-chances-wtf! u1009)
(define-constant ERROR-you-are-not-welcome-here u1010)
(define-constant ERROR-this-number-is-a-disgrace!! u1011)

;; replace this with your public key hash pay to public key hash p2pkh, i learnt that yesterday

;; (define-constant pox-address {hash: 0x0000000000000000000000000000000000000000, version: 0x00})

(define-constant contract-address (as-contract tx-sender))
(define-constant stacker tx-sender)
(define-constant min-pledge (to-ustx u10000))
;; opinionated: pool which could be granted reputation points
(define-constant minimum-viable-pool-reward (to-ustx u5000))

;; how many blocks till collateral and delegation expire

(define-constant lock-collateral-period-min u200)

(define-map stacking-offer-details 
  {
    cycle: uint
  }
  {
    pledged-payout: uint,
    minimum-stake: uint,
    cycle-count: uint,
    collateral: uint,
    deposited-collateral: uint,
    lock-collateral-period: uint,
    lock-started-at: uint,
    total-required-stake: uint,
    pox-address: {version: (buff 1), hash: (buff 20),},
  })

(define-map cycles-locked-amounts {cycle: uint} {locked-amount: uint})


(define-map delegators 
  {delegator: principal, cycle: uint} 
  {
    did-withdraw-rewards: bool,
    locked-amount: uint,
  })


(define-public 
  (create-decent-pool
    (pledged-payout uint)
    (minimum-stake uint)
    (cycle-count uint)
    (collateral uint)
    (lock-collateral-period uint)
    (total-required-stake uint)
    (pox-address {hash: (buff 20), version: (buff 1)}))

  (let
    ((balance (stx-get-balance tx-sender))
    (next-cycle (get-next-cycle-id)))

    (asserts! (is-not-called-by-another-contract)
      (err ERROR-ummm-this-is-a-PEOPLE-contract))
    (asserts! (is-creator)
      (err ERROR-not-my-president!))

    (asserts! (>= pledged-payout min-pledge)
      (err ERROR-this-number-is-a-disgrace!!))
    (asserts! (>= balance collateral)
      (err ERROR-you-poor-lol))
    (asserts! (is-none (map-get? stacking-offer-details {cycle: next-cycle})) 
      (err ERROR-didnt-we-just-go-through-this-the-other-day))

    (asserts! (deposit collateral)
      (err ERROR-wtf-stacks!!!))
    (map-set cycles-locked-amounts {cycle: next-cycle} {locked-amount: u0})
    (ok (map-set stacking-offer-details 
      {
        cycle: next-cycle,
      } 
      {
        pledged-payout: pledged-payout, 
        minimum-stake: minimum-stake,
        cycle-count: cycle-count,
        collateral: collateral,
        deposited-collateral: u0,
        lock-collateral-period: lock-collateral-period,
        lock-started-at: block-height,
        total-required-stake: total-required-stake,
        pox-address: pox-address,
      })))
  )

(define-read-only (get-locked-amount (cycle-id uint)) 
  (map-get? cycles-locked-amounts {cycle: cycle-id}))

(define-public (deposit-to-collateral (amount uint)) 
  (let 
    ((balance (stx-get-balance tx-sender))) 

    (asserts! (is-creator)
      (err ERROR-this-aint-a-donation-box))

    (asserts! (is-not-called-by-another-contract)
      (err ERROR-ummm-this-is-a-PEOPLE-contract))

    (asserts! (>= balance amount)
      (err ERROR-you-poor-lol))

    (asserts! (deposit amount)
      (err ERROR-wtf-stacks!!!))

    (increase-deposit amount)))
      
    


;; if you want you could get your cut but 
;; you won't be eligible to get the rest of the rewards
;; they would be reserved for the stacker
(define-public (redeem-reward (cycle uint) (delegator principal))
  ;; if within the cycle when not enough funds 
  (let ((delegator-info (unwrap-panic (map-get? delegators {cycle: cycle, delegator: delegator})))
        (locked-amount (get locked-amount delegator-info))
        (cycle-info (get-cycle cycle))
        (total-stake (get total-required-stake cycle-info))
        (was-patient (unwrap-panic (is-pool-expired cycle)))
        (reward-info (calculate-cycle-rewards cycle locked-amount total-stake))
        (patient-reward (get rewards-if-patient reward-info))
        (impatient-reward (get rewards-if-impatient reward-info))
        (reward-to-payout (if was-patient patient-reward impatient-reward)))
    (asserts! (is-eq tx-sender delegator) 
      (err ERROR-you-are-not-welcome-here))
    (asserts! (> reward-to-payout u0) 
      (err ERROR-you-poor-lol))
    (asserts! (is-ok (stx-transfer? reward-to-payout contract-address delegator))
      (err ERROR-wtf-stacks!!!))
    (map-set delegators 
      {
        delegator: delegator, 
        cycle: cycle
      }
      {
        did-withdraw-rewards: true,
        locked-amount: locked-amount,
      })
    ;; have been deposited and still in the pox cycle
    ;; only the delegator themselves might request to redeem
    ;; if the cycle ended the delegate might call this to payout
    ;; the delegator
    (ok true))
  )

(define-read-only (is-pool-expired (cycle uint)) 
  (ok (> (get-next-cycle-id) cycle)))


(define-public (delegate (amount uint)) 
    (let 
      ((cycle-id (get-next-cycle-id))
      (cycle-info (get-cycle cycle-id))
      (pox-address (get pox-address cycle-info))
      (cycle-count (get cycle-count cycle-info))
      (minimum-stake (get minimum-stake cycle-info))
      (until-block-height (get-cycle-start (+ cycle-id u1)))
      (is-new-delegator (is-none (map-get? delegators {cycle: cycle-id, delegator: tx-sender})))
      (cycle-locked-amount (get locked-amount (unwrap-panic (map-get? cycles-locked-amounts {cycle: cycle-id}))))
      
      (balance (stx-get-balance tx-sender)))
      
      (asserts! (is-eq amount minimum-stake) 
        (err ERROR-you-poor-lol))
      
      (asserts! (>= balance amount) 
        (err ERROR-you-poor-lol))
      
      (asserts! is-new-delegator 
        (err ERROR-didnt-we-just-go-through-this-the-other-day))
      
      (contract-call? 
        'ST000000000000000000002AMW42H.pox 
        delegate-stx 
          amount
          (as-contract tx-sender)
          until-block-ht 
          pox-address)
      
      (contract-call? 
        'ST000000000000000000002AMW42H.pox 
        delegate-stack-stx
          tx-sender
          amount
          pox-address
          burn-block-height
          (as-contract tx-sender)
          until-block-ht
          cycle-count)
      (map-set cycles-locked-amounts {cycle: cycle-id} {locked-amount: (+ cycle-locked-amount amount)})
      (ok (map-set delegators {
        delegator: tx-sender,
        cycle: (get-next-cycle-id)
      } 
      {
        did-withdraw-rewards: false,
        locked-amount: amount
      }))))
    ;; (ok true))



;; util
;; MY EYES MY EYES!!!
;; ustx might have greater value in the future
;; now it's just a nuisance of many many zeroes
(define-read-only (to-ustx (amount uint)) (* amount u1000000))

(define-private (deposit (amount uint)) 
  (is-ok (stx-transfer? amount tx-sender contract-address)))

(define-read-only (get-current-deposit) 
  (get deposited-collateral (get-current-cycle-info stacker)))


(define-private (set-current-deposit (amount uint))
  (set-deposit amount))

(define-private (increase-deposit (amount uint)) 
  (let ((new-collateral-amount (+ (get-current-deposit tx-sender) amount))
        (cycle-info (get-current-cycle-info tx-sender))
        (promised-rewards (get pledged-payout cycle-info))
        (cycle-count (get cycle-count cycle-info))
        (cycle-expired (unwrap-panic (is-pool-expired)))
        (reputation (ft-get-balance decent-delegate-reputation stacker))
        (no-more-rep (reputation-no-mo!))
        (is-promise-fulfilled (>= new-collateral-amount promised-rewards)))
    (asserts! (not cycle-expired) 
      (err ERROR-didnt-we-just-go-through-this-the-other-day))
    (set-current-deposit new-collateral-amount)
    (if (>= promised-rewards minimum-viable-pool-reward)
      (begin 
        (asserts! (is-eq reputation u12) 
          (err ERROR-you-cant-get-any-awesomer))
        (asserts! (and no-more-rep (is-eq reputation u0)) 
          (err ERROR-you-had-12-chances-wtf!))
        (award-reputation))
      (ok true))))

(define-private (award-reputation) 
  (let ((supply (ft-get-balance decent-delegate-reputation contract-address)))
    (if (> supply u0)
      (ft-transfer? decent-delegate-reputation u1 contract-address stacker) 
      (ok true))))    

(define-read-only (get-current-cycle-info) 
  (get-cycle (get-next-cycle-id)))

(define-read-only (get-next-cycle-id)
  (let ((fixed-bht (+ prepare-cycle-length burn-block-height))
        (pox-age (- fixed-bht first-burnchain-block-height))
        (next-cycle (/ pox-age reward-cycle-length)))
      next-cycle))  


(define-read-only (get-next-pox-start) 
  (let ((next-cycle (get-next-cycle-id)))
    (get-cycle-start next-cycle)))

(define-read-only (get-cycle-start (cycle uint)) 
  (if (<= cycle u1) first-burnchain-block-height
    (let ((fixed-height (- first-burnchain-block-height prepare-cycle-length))
        (cycle-start (+ fixed-height (* cycle u2100))))
      cycle-start)))

(define-read-only (is-creator) 
  (is-eq stacker tx-sender))

(define-read-only (is-not-called-by-another-contract) 
  (is-eq contract-caller tx-sender))

;; what rewards you could get right now
;; and what rewards you could get later
(define-read-only (calculate-cycle-rewards (cycle uint) (personal-stake uint) (total-stake uint)) 
  (let (
        (current-cycle-info (get-cycle cycle))
        (pledged-payout (get pledged-payout current-cycle-info))
        (current-funds (get deposited-collateral current-cycle-info))
        (rewards-if-patient (/ (* personal-stake pledged-payout) total-stake))
        (rewards-if-impatient (/ (* personal-stake current-funds) total-stake))
        )
    {rewards-if-patient: rewards-if-patient, rewards-if-impatient: rewards-if-impatient}))

(define-read-only (get-cycle (cycle uint)) 
  (unwrap-panic (map-get? stacking-offer-details {cycle: cycle})))

(define-read-only (reputation-no-mo!) 
  (is-eq (ft-get-supply decent-delegate-reputation) u0))


;; I know I know
(define-private (set-deposit
                  (deposited-collateral  uint))
  (let ((current-cycle-info (get-current-cycle-info stacker)))

    (map-set stacking-offer-details 
      {cycle: (get-next-cycle-id)}
      {
        deposited-collateral: deposited-collateral,
        pledged-payout: (get pledged-payout current-cycle-info),
        minimum-stake: (get minimum-stake current-cycle-info),
        cycle-count: (get cycle-count current-cycle-info),
        collateral: (get collateral current-cycle-info),
        lock-collateral-period: (get lock-collateral-period current-cycle-info),
        lock-started-at: (get total-required-stake current-cycle-info),
        total-required-stake: (get lock-started-at current-cycle-info),
        pox-address: (get pox-address current-cycle-info),
      })))
    
