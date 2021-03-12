;; a delegatee would say that they would payout delegators
;; an X amount of STX and would provide half or a portion of that STX in advance
;; delegators then would delegate to the contract their STX and based on their percentage
;; of the total stake they would receive rewards or the locked STX
;; each delegatee would have one pool at a time and would have one collateral pool as well
;; the collateral is locked until N cycles (whatever cycle defined in the pool) pass
;; and within the cycle the delegatee would progressively fill up the rest of the promised
;; stx rewards
;; in a conversation with @heynky
;; let's call them dan and hoz
;; since these names are easier and dan is doing boom pool
;; so dan would promise that they would payout 15000 STX for one cycle of stacking
;; both the payout and the cycles are variables
;; dan would also say that they're willing to put 7500 STX as collateral
;; and that he would need 1 million stx to distribute these STX rewards
;; not btc
;; so the pool starts out with dan depositing his collateral, that collateral would be locked for 200 or whatever blocks for example
;; during this period people would delegate to the contract their funds
;; after that period passes if the 1M STX goal was fulfilled then dan's collateral would be locked for the next cycle 2000 blocks or until the amount of STX promised is deposited, it would not be used for stacking, the delegated amounts are then locked and stacked
;; and during that period dan might deposit into the collateral if he chose to convert btc he got into the pool, maybe he got lucky and the price dropped vs btc
;; if the total amount matches the amount promised then hoz or any one else who delegated might call the get reward method to get their promised reward
;; if the 1M goal was not reached dan's locked collateral would be unlocked and the contract's delegated funds would be rendered unusable
;; since dan didn't get to the goal
;; the reputation part tho
;; when the pool is filled (dan can only deposit STX into the collateral not the other way around) the contract would give dan one stacking reputation point or maybe an nft
;; I haven't thought about that yet
;; and since people trust contracts more than people they would know that dan got that because dan delivered on his promise
;; that's the best case scenario
;; the worst dan can do in this system is not deposit any stx and use up the btc in the cycle
;; in that case at the end of the cycle whether dan completed part of his promise or not, the contract is ruthless, and would give dan a negative stacker nft or something
;; that way people might know that dan is not trustworthy and they wouldn't work with him
;; and if dan delivered on his promise consistently people would trust him for longer cycles
;; UI can be built around this to facilitate shit

;; later
;;     (get-stacker-info (principal)
;;       (optional {
;;         amount-ustx: uint, 
;;         first-reward-cycle: uint, 
;;         lock-period: uint, 
;;         pox-addr: { hash: (buff 20), version: (buff 1) }
;;       } none))

;; why am i doing this to myself?!
;; (define-trait pox-fns ((get-pox-info () 
;;   (response 
;;       {
;;         current-rejection-votes: uint, 
;;         first-burnchain-block-height: uint, 
;;         min-amount-ustx: uint, 
;;         prepare-cycle-length: uint, 
;;         rejection-fraction: uint, 
;;         reward-cycle-id: uint, 
;;         reward-cycle-length: uint, 
;;         total-liquid-supply-ustx: uint
;;       }

;;       {
;;         current-rejection-votes: uint, 
;;         first-burnchain-block-height: uint, 
;;         min-amount-ustx: uint, 
;;         prepare-cycle-length: uint, 
;;         rejection-fraction: uint, 
;;         reward-cycle-id: uint, 
;;         reward-cycle-length: uint, 
;;         total-liquid-supply-ustx: uint
;;       }
;; ))))


;; this token would be awarded at the end of each successful cycle
;; and would be taken away if the cycle failed to produce the promised STX
;; in the same way this would be for a delegate who failed to
;; deliver on their pledge
;; the decent token is burnt
;; a delegate gets only 12 chances of being a decent person
(define-fungible-token decent-delegate-reputation u12)



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
    (next-cycle (get-next-cycle-id))
    (minimum-stake-for-cycle (get-pox-info))) 

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

    (ok (map-set stacking-offer-details 
      {
        cycle: (get-next-cycle-id),
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

(define-public (is-pool-expired (cycle uint)) 
  (ok (> (get-current-cycle-id) cycle)))


(define-public (do-delegate (amount uint)) 
    (let 
      ((cycle-info (get-cycle (get-next-cycle-id)))
      (pox-address (get pox-address cycle-info))
      (cycle-count (get cycle-count cycle-info))
      (minimum-stake (get minimum-stake cycle-info))
      (balance (stx-get-balance tx-sender)))
      (asserts! (is-eq amount minimum-stake) 
        (err ERROR-you-poor-lol))
      (asserts! (>= balance amount) 
        (err ERROR-you-poor-lol))
      (contract-call? 
        'ST000000000000000000002AMW42H.pox 
        delegate-stx 
          (to-ustx amount) 
          (as-contract tx-sender)
          until-block-ht 
          pox-address)
      (contract-call? 
        'ST000000000000000000002AMW42H.pox 
        delegate-stack-stx
          tx-sender
          (to-ustx amount) 
          pox-address
          burn-block-height
          (as-contract tx-sender)
          until-block-ht
          cycle-count)
      (ok (map-set delegators {
        delegator: tx-sender,
        cycle: (get-next-cycle-id)
      } 
      {
        did-withdraw-rewards: false,
        locked-amount: amount
      }))
      ))
    ;; (ok true))



;; util
;; MY EYES MY EYES!!!
;; ustx might have greater value in the future
;; now it's just a nuisance of many many zeroes
(define-private (to-ustx (amount uint)) (* amount u1000000))

(define-private (deposit (amount uint)) 
  (is-ok (stx-transfer? amount tx-sender contract-address)))

(define-private (get-current-deposit) 
  (get deposited-collateral (get-current-cycle-info stacker)))


(define-private (set-current-deposit (amount uint))
  (set-deposit amount))

(define-private (increase-deposit (amount uint)) 
  (let ((new-collateral-amount (+ (get-current-deposit tx-sender) amount))
        (promised-rewards (get pledged-payout (get-current-cycle-info tx-sender)))
        (cycle-count (get cycle-count (get-current-cycle-info tx-sender)))
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
        (ft-mint? decent-delegate-reputation cycle-count stacker))
      (ok true))))
    

(define-private (get-current-cycle-info) 
  (get-cycle (get-current-cycle-id)))

;; (define-private (get-pox-info-signature (pox-contract <pox-fns>)) 
;;   (contract-call? pox-contract get-pox-info))

(define-private (get-pox-info) 
  (contract-call? 'ST000000000000000000002AMW42H.pox get-pox-info))
  ;; (ok {
  ;;       current-rejection-votes: u0, 
  ;;       first-burnchain-block-height: u0, 
  ;;       min-amount-ustx: u0, 
  ;;       prepare-cycle-length: u0, 
  ;;       rejection-fraction: u0, 
  ;;       reward-cycle-id: u0, 
  ;;       reward-cycle-length: u0, 
  ;;       total-liquid-supply-ustx: u0
  ;;     }))

(define-private (get-minimum-stacking-amount) 
  (get min-amount-ustx (unwrap-panic (get-pox-info))))

(define-private (get-current-cycle-id) 
  (get reward-cycle-id (unwrap-panic (get-pox-info))))

(define-private (get-next-cycle-id) 
  (+ (get-current-cycle-id) u1))

(define-private (get-stacker-info (delegator principal)) 
  (contract-call? 'ST000000000000000000002AMW42H.pox get-stacker-info delegator))
  ;; (some {
  ;;       amount-ustx: u700, 
  ;;       first-reward-cycle: u1,
  ;;       delegator: delegator,
  ;;       lock-period: u2000, 
  ;;       pox-addr: { hash: 0x00, version: 0x00 }
  ;;     }))


(define-private (is-creator) 
  (is-eq stacker tx-sender))

(define-private (is-not-called-by-another-contract) 
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

;; obsolete can't create stacking pool if collateral isn't there 
;; (define-read-only (has-delegate-locked-collateral (stacker principal) (cycle uint)) 
;;   (let ((collateral (get collateral (get-cycle stacker cycle)))) 
;;     (>= (get deposited-collateral (get-cycle stacker cycle)) collateral)))

(define-read-only (reputation-no-mo!) 
  (is-eq (ft-get-supply decent-delegate-reputation) u0))

(define-private (set-deposit (new-deposit uint)) 
  (set-current-cycle (some new-deposit)))


;; I know I know
(define-private (set-current-cycle
                  (deposited-collateral (optional uint))
                  (pledged-payout (optional uint))
                  (minimum-stake (optional uint))
                  (cycle-count (optional uint))
                  (collateral (optional uint))
                  (lock-collateral-period (optional uint))
                  (lock-started-at (optional uint))
                  (total-required-stake (optional uint))
                  (pox-address (optional {hash: (buff 20), version: (buff 1)})))

  (let (
        (current-cycle-info (get-current-cycle-info stacker))
        (default-deposited-collateral (get deposited-collateral current-cycle-info))
        (default-pledged-payout (get pledged-payout current-cycle-info))
        (default-minimum-stake (get minimum-stake current-cycle-info))
        (default-cycle-count (get cycle-count current-cycle-info))
        (default-collateral (get collateral current-cycle-info))
        (default-lock-collateral-period (get lock-collateral-period current-cycle-info))
        (default-total-required-stake (get total-required-stake current-cycle-info))
        (default-lock-started-at (get lock-started-at current-cycle-info))
        (default-pox-address (get pox-address current-cycle-info)))

    (map-set stacking-offer-details 
      {cycle: (get-next-cycle-id)}
      {
        deposited-collateral: (default-to default-deposited-collateral deposited-collateral),
        pledged-payout: (default-to default-pledged-payout pledged-payout),
        minimum-stake: (default-to default-minimum-stake minimum-stake),
        cycle-count: (default-to default-cycle-count cycle-count),
        collateral: (default-to default-collateral collateral),
        lock-collateral-period: (default-to default-lock-collateral-period lock-collateral-period),
        lock-started-at: (default-to default-lock-started-at lock-started-at),
        total-required-stake: (default-to default-total-required-stake total-required-stake),
        pox-address: (default-to default-pox-address pox-address),
      })))
    
