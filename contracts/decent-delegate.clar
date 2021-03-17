;; this token would be awarded at the end of each successful cycle
;; and would be taken away if the cycle failed to produce the promised STX
;; in the same way this would be for a delegate who failed to
;; deliver on their pledge
;; the decent token is burnt
;; a delegate gets only 12 chances of being a decent person


;; (asserts! 
;;   (is-ok 
;;     (contract-call? 'ST000000000000000000002AMW42H.pox delegate-stx amount contract-address none none))
;;   (err ERROR-wtf-stacks!!!))
;; (asserts! 
;;   (is-ok 
;;     (contract-call? 'ST000000000000000000002AMW42H.pox 
;;       delegate-stack-stx tx-sender amount pox-address burn-block-height cycle-count))
;;   (err ERROR-wtf-stacks!!!))
;; now the contract would stack itself
;; instead of pox complications
;; this way if people wanted to take their funds after the cycle ends
;; or the cycle didn't reach its goal and the collateral-lock-period
;; expired


(define-fungible-token decent-delegate-reputation u12)
(ft-mint? decent-delegate-reputation u12 contract-address)




;; TODO: ENV
;; (define-constant first-burnchain-block-height u666050)
;; (define-constant reward-cycle-length u2100)
;; (define-constant prepare-cycle-length u100)
(define-constant reward-cycle-length u50)
(define-constant first-burnchain-block-height u1931620)
(define-constant prepare-cycle-length u10)

(define-constant ERROR-ummm-this-is-a-PEOPLE-contract 1000)
(define-constant ERROR-you-poor-lol 1001)
(define-constant ERROR-this-aint-a-donation-box 1002)
(define-constant ERROR-wtf-stacks!!! 1003)
(define-constant ERROR-not-my-president! 1004)
(define-constant ERROR-didnt-we-just-go-through-this-the-other-day 1005)
(define-constant ERROR-only-current-cycle-bro! 1006)
(define-constant ERROR-i-have-never-met-this-man-in-my-life 1007)
(define-constant ERROR-you-cant-get-any-awesomer 1008)
(define-constant ERROR-you-had-12-chances-wtf! 1009)
(define-constant ERROR-you-are-not-welcome-here 1010)
(define-constant ERROR-this-number-is-a-disgrace!! 1011)
(define-constant ERROR-better-luck-next-time 1012)
(define-constant ERROR-we-need-a-lot-but-not-THAT-much 1013)
(define-constant ERROR-requires-padding 1014)
(define-constant ERROR-LOCKED-have-a-little-faith 1015)
(define-constant ERROR-UNAUTHORIZED 1016)

;; replace this with your public key hashbytes pay to public key hashbytes p2pkh, i learnt that yesterday

;; (define-constant pox-address {hashbytes: 0x0000000000000000000000000000000000000000, version: 0x00})

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
    minimum-delegator-stake: uint,
    cycle-count: uint,
    collateral: uint,
    deposited-collateral: uint,
    lock-collateral-period: uint,
    lock-started-at: uint,
    total-required-stake: uint,
    pox-address: {version: (buff 1), hashbytes: (buff 20),},
  })

(define-map cycle-stx-vault {cycle: uint} {locked-amount: uint, is-stacked: bool})


(define-map delegators 
  {delegator: principal, cycle: uint} 
  {
    did-withdraw-rewards: bool,
  })

(define-map delegator-stx-vault 
  {delegator: principal} 
  {
    locked-amount: uint,
  })

(define-public 
  (create-decent-pool
    (pledged-payout uint)
    (minimum-delegator-stake uint)
    (cycle-count uint)
    (collateral uint)
    (lock-collateral-period uint)
    (total-required-stake uint)
    (pox-address {hashbytes: (buff 20), version: (buff 1)}))

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
    (map-set cycle-stx-vault {cycle: next-cycle} {locked-amount: u0, is-stacked: false})
    (ok (map-set stacking-offer-details 
      {
        cycle: next-cycle,
      } 
      {
        pledged-payout: pledged-payout, 
        minimum-delegator-stake: minimum-delegator-stake,
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
  (map-get? cycle-stx-vault {cycle: cycle-id}))

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
(define-public (redeem-reward (cycle uint))
  ;; if within the cycle when not enough funds 
  (let ((delegator tx-sender)
        (delegator-vault-info (unwrap-panic (map-get? delegator-stx-vault {delegator: delegator})))
        (locked-amount (get locked-amount delegator-vault-info))
        (cycle-info (get-cycle cycle))
        (total-required-stake (get total-required-stake cycle-info))
        (was-patient (unwrap-panic (is-pool-expired cycle)))
        (reward-info (calculate-cycle-rewards cycle locked-amount total-required-stake))
        (patient-reward (get rewards-if-patient reward-info))
        (impatient-reward (get rewards-if-impatient reward-info))
        (reward-to-payout (if was-patient patient-reward impatient-reward)))
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
      })
    ;; have been deposited and still in the pox cycle
    ;; only the delegator themselves might request to redeem
    ;; if the cycle ended the delegate might call this to payout
    ;; the delegator
    (ok reward-info))
  )

(define-read-only (is-pool-expired (cycle uint)) 
  (ok (> (get-next-cycle-id) cycle)))

(define-read-only (get-delegator-info (cycle-id uint) (delegator principal)) 
  (map-get? delegators {cycle: cycle-id, delegator: delegator}))

(define-read-only (is-cycle-expired (cycle-id uint)) 
  (let 
    ((cycle-info (get-cycle cycle-id))
    (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
    (lock-collateral-period (get lock-collateral-period cycle-info))
    (lock-started-at (get lock-started-at cycle-info))
    (total-required-stake (get total-required-stake cycle-info))
    (collateral-lock-expired (>= block-height (+ lock-started-at lock-collateral-period)))
    (cycle-locked-amount (get-locked-amount cycle-id)))
  (and collateral-lock-expired (< (get locked-amount (unwrap-panic cycle-locked-amount)) total-required-stake)))
)

(define-public (withdraw-stake (cycle-id uint))
  (let ((stake-info (map-get? delegator-stx-vault {delegator: tx-sender}))
    (delegator-info (get-delegator-info cycle-id tx-sender))
        (stake-exists (is-some stake-info)))
    (asserts! (is-not-called-by-another-contract)
      (err ERROR-ummm-this-is-a-PEOPLE-contract))
    (asserts! stake-exists
      (err ERROR-i-have-never-met-this-man-in-my-life))
    (asserts! (is-cycle-expired cycle-id)
      (err ERROR-LOCKED-have-a-little-faith))
    (asserts!
      (let ((stake (get locked-amount (unwrap-panic stake-info))))
        (and
          (is-ok (stx-transfer? stake contract-address tx-sender))
          (is-ok (ft-burn? stacked-stx stake tx-sender))))
    (err ERROR-wtf-stacks!!!))
    (ok true)))

(define-public (delegate (amount uint) (sacrifice-stx-for-padding bool)) 
    (let 
      ((cycle-id (get-next-cycle-id))
      (cycle-info (get-cycle cycle-id))
      (pox-address (get pox-address cycle-info))
      (cycle-count (get cycle-count cycle-info))
      (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
      (lock-collateral-period (get lock-collateral-period cycle-info))
      (lock-started-at (get lock-started-at cycle-info))
      (total-required-stake (get total-required-stake cycle-info))
      (collateral-lock-valid (< block-height (+ lock-started-at lock-collateral-period)))
      ;; (until-block-ht (get-cycle-start (+ cycle-id u1)))
      (delegator-info (get-delegator-info cycle-id tx-sender))
      ;; default to zero stake to avoid complications
      (stake (default-to {locked-amount: u0} (map-get? delegator-stx-vault {delegator: tx-sender})))
      (is-new-delegator (is-none delegator-info))
      (cycle-locked-amount (get-locked-amount cycle-id))
      
      (balance (stx-get-balance tx-sender)))

      (asserts! (>= amount minimum-delegator-stake) 
        (err {code: ERROR-you-poor-lol, message: ""}))
      ;; you can't delegate your stx if the cycle expired after not
      ;; completing the amount required to start stacking
      (asserts! collateral-lock-valid
        (err {code: ERROR-better-luck-next-time, message: ""}))
      ;; The cycle must have existed before delegating
      (asserts! (is-some cycle-locked-amount) 
        (err {code: ERROR-i-have-never-met-this-man-in-my-life, message: ""}))
      ;; Must have enough balance to delegate
      (asserts! (>= balance amount) 
        (err {code: ERROR-you-poor-lol, message: ""}))

      (let 

        (
            ;; you can add the difference if you've contributed before
            (can-safely-add-padding (or sacrifice-stx-for-padding (not is-new-delegator)))

            ;; Reach goal after getting the amount of stacks required before starting
            (locked-amount (get locked-amount (unwrap-panic cycle-locked-amount)))
            (has-not-reached-goal (< locked-amount total-required-stake))
            

            ;; How much stx are required to fulfill stacking
            (remaining-required-stake (- total-required-stake locked-amount))
            
            ;; The max possible STX a delegator can put in
            ;; this would make it possible for fixed sets of
            ;; collateralized pools
            ;; so that the distribution is fair
            (max-possible-addition 

              (if (> amount remaining-required-stake) remaining-required-stake amount))

            ;; get the old locked balance
            (delegator-sum-stake 

              (if is-new-delegator 

                  max-possible-addition

                  (+ max-possible-addition (get locked-amount stake))))

            ;; Sometimes a small fraction is required, a delegator
            ;; or the stacker might add that small fraction
            (requires-padding (< max-possible-addition minimum-delegator-stake)))
        ;; stacker would then append padding and start stacking
        (asserts!


          (or

            ;; it either does not require padding
            (not requires-padding)

            ;; or requires and the delegator chose to sacrifice
            ;; their stx to pad
            (and requires-padding can-safely-add-padding)) 

          (err {code: ERROR-requires-padding, message: ""}))


        (asserts!


          (is-ok 

            ;; You know this
            (stx-transfer? max-possible-addition tx-sender contract-address)) 

        (err 
          {
            code: ERROR-wtf-stacks!!!,
            message: "Couldn't transfer funds from delegator" 
          }))

        (asserts!


          (is-ok 

            ;; This token would represent the tokens and could be redistibuted
            ;; So that the STX network could use this token in transactions
            (ft-mint? stacked-stx max-possible-addition tx-sender))

          (err 
            {
              code: ERROR-wtf-stacks!!!,
              message: "Couldn't mint stacked-stx to delegator" 
            }))

        (let
          ((new-total-locked-amount (+ locked-amount max-possible-addition))
          (reached-goal (print (>= new-total-locked-amount total-required-stake)))
          
          ;; This has preplexed me for a while now
          (stacking-response
            (if reached-goal
              ;; just for testing since clarity vscode analysis
              ;; is upset with contract calls
              ;; (ok true)
              (as-contract 
                (contract-call? 
                  'ST000000000000000000002AMW42H.pox 
                  stack-stx new-total-locked-amount pox-address burn-block-height cycle-count))
              (err ERROR-wtf-stacks!!!)))
          (did-stack (is-ok stacking-response)))
          (asserts! 

            ;; it either stacked or didn't stack
            (or (and reached-goal did-stack) (not reached-goal))
              (err {
                code: (unwrap-err-panic stacking-response), 
                message: "PoX contract stack-stx failed", 
                }))

          (map-set 

            cycle-stx-vault

            {cycle: cycle-id} 

            {locked-amount: new-total-locked-amount, is-stacked: did-stack})
            (map-set 
              delegators 
              { delegator: tx-sender, cycle: cycle-id } 
              { did-withdraw-rewards: false, })
            (map-set 
              delegator-stx-vault
              { delegator: tx-sender } 
              { locked-amount: delegator-sum-stake, })
            (ok
              {
                cycle: cycle-id,
                delegator: tx-sender,
                delegated-amount: delegator-sum-stake,
                time-until-cycle-expiry: (- lock-collateral-period block-height)
              } 
            )))))



;; util
;; MY EYES MY EYES!!!
;; ustx might have greater value in the future
;; now it's just a nuisance of many many zeroes
(define-read-only (to-ustx (amount uint)) (* amount u1000000))

(define-private (deposit (amount uint)) 
  (is-ok (stx-transfer? amount tx-sender contract-address)))

(define-read-only (get-current-deposit) 
  (get deposited-collateral (get-next-cycle-info stacker)))


(define-private (set-current-deposit (amount uint))
  (set-deposit amount))

(define-private (increase-deposit (amount uint)) 
  (let ((new-collateral-amount (+ (get-current-deposit tx-sender) amount))
        (cycle-info (get-next-cycle-info tx-sender))
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
        (asserts! (is-ok (award-reputation))
          (err ERROR-wtf-stacks!!!))
        (ok true))
      (err ERROR-you-poor-lol))))

(define-private (award-reputation) 
  (let ((supply (ft-get-balance decent-delegate-reputation contract-address)))
    (if (> supply u0)
      (ft-transfer? decent-delegate-reputation u1 contract-address stacker) 
      (ok true))))    

(define-read-only (get-next-cycle-info) 
  (get-cycle (get-next-cycle-id)))

(define-read-only (get-next-cycle-id)
  (+ (burn-height-to-reward-cycle burn-block-height) u1))


(define-read-only (get-next-pox-start) 
  (let ((next-cycle (get-next-cycle-id)))
    (get-cycle-start next-cycle)))

(define-read-only (get-cycle-start (cycle uint)) 
  (if (<= cycle u1) first-burnchain-block-height
    (let ((fixed-height (- first-burnchain-block-height prepare-cycle-length))
        (cycle-start (+ fixed-height (* cycle u2100))))
      cycle-start)))

(define-private (burn-height-to-reward-cycle (height uint))
    (/ (- height first-burnchain-block-height) reward-cycle-length))


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
  (let ((current-cycle-info (get-next-cycle-info stacker)))

    (map-set stacking-offer-details 
      {cycle: (get-next-cycle-id)}
      (merge 
        current-cycle-info 
        { deposited-collateral: deposited-collateral,}))))


;; This should make stacked stx liquid

(define-fungible-token stacked-stx)


(define-public (transfer (amount uint) (from principal) (to principal))
    (let
      ;; do I owe you money?
      ((sender-vault (map-get? delegator-stx-vault {delegator: from}))
      ;; is this a new member of our crew?
        (recepient-vault (map-get? delegator-stx-vault {delegator: to})))
      ;; I don't owe you anything
      (asserts! (is-some sender-vault) 
        (err ERROR-i-have-never-met-this-man-in-my-life))
      ;; IMPOSTER!!!
      (asserts! (is-eq from tx-sender)
          (err ERROR-UNAUTHORIZED))
      ;; here are your frozen tokens, have fun!
      (asserts! (is-ok (ft-transfer? stacked-stx amount from to)) 
        (err ERROR-you-poor-lol))
      ;; now let's do some accounting
      ;; we are gonna transfer this much from your account
      ;; to your friend's account
      (let ((sender-balance (get locked-amount (unwrap-panic sender-vault)))
            ;; weird no?
            ;; if you find a better way let me know right away!
            (recepient-balance (get locked-amount (default-to {locked-amount: u0} recepient-vault)))
            ;; let's take the money from here
            (sender-new-balance (- sender-balance amount))
            ;; aaaand put it there!
            (recepient-new-balance (+ recepient-balance amount)))
          ;; and submit that to our nice little ledger
          (map-set delegator-stx-vault {delegator: from} {locked-amount: sender-new-balance})
          (map-set delegator-stx-vault {delegator: to} {locked-amount: recepient-new-balance})
          (ok true)
        )
        
    )
)

;; stolen from jude

(define-read-only (get-name)
    (ok "Stacked-STX"))

(define-read-only (get-symbol)
    (ok "DDX"))

(define-read-only (get-decimals)
    (ok u6))

(define-read-only (get-balance-of (user principal))
    (ok (ft-get-balance stacked-stx user)))

(define-read-only (get-total-supply)
    (ok (stx-get-balance (as-contract tx-sender))))

(define-read-only (get-token-uri)
    (ok none))
