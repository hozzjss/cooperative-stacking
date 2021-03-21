;; now the contract would stack itself
;; instead of pox complications
;; this way if people wanted to take their funds after the cycle ends
;; or the cycle didn't reach its goal and the collateral-lock-period
;; expired

;; TODO: change this when changing to mainnet
;; (impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-10-ft-standard.ft-trait)
;; (impl-trait .sip-10-ft-standard.ft-trait)


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
(define-constant ERROR-better-luck-next-time u1012)
(define-constant ERROR-we-need-a-lot-but-not-THAT-much u1013)
(define-constant ERROR-requires-padding u1014)
(define-constant ERROR-LOCKED-have-a-little-faith u1015)
(define-constant ERROR-UNAUTHORIZED u1016)

;; replace this with your public key hashbytes pay to public key hashbytes p2pkh, i learnt that yesterday

;; (define-constant pox-address {hashbytes: 0x0000000000000000000000000000000000000000, version: 0x00})

(define-constant contract-address (as-contract tx-sender))
(define-constant stacker tx-sender)

;; how many blocks till collateral and delegation expire
;; How many blocks before locking starts
(define-constant stacking-grace-period (print (/ (get-reward-cycle-length) u2)))



;; this token would be awarded at the end of each successful cycle
;; and would be taken away if the cycle failed to produce the promised STX
;; in the same way this would be for a delegate who failed to
;; deliver on their pledge
;; the decent token is burnt
;; a delegate gets only 12 chances of being a decent person
(define-fungible-token decent-delegate-reputation u12)
(ft-mint? decent-delegate-reputation u12 contract-address)



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


;; allowed contract-callers
(define-map allowance-contract-callers
    { sender: principal, contract-caller: principal }
    { until-burn-ht: (optional uint) })


;; Stolen from XVerse
;; Backport of .pox's burn-height-to-reward-cycle
(define-private (burn-height-to-reward-cycle (height uint))
    (let (
        (pox-info (unwrap-panic (contract-call? 'ST000000000000000000002AMW42H.pox get-pox-info)))
    )
    (/ (- height (get first-burnchain-block-height pox-info)) (get reward-cycle-length pox-info)))
)

(define-private (get-reward-cycle-length)
    (let (
        (pox-info (unwrap-panic (contract-call? 'ST000000000000000000002AMW42H.pox get-pox-info)))
    )
    (get reward-cycle-length pox-info)))

;; Backport of .pox's reward-cycle-to-burn-height
(define-private (reward-cycle-to-burn-height (cycle uint))
    (let (
        (pox-info (unwrap-panic (contract-call? 'ST000000000000000000002AMW42H.pox get-pox-info)))
    )
    (+ (get first-burnchain-block-height pox-info) (* cycle (get reward-cycle-length pox-info))))
)

;; What's the current PoX reward cycle?
(define-private (get-current-cycle-id)
    (burn-height-to-reward-cycle burn-block-height))


(define-private (deposit (amount uint)) 
  (and 
    (is-ok (stx-transfer? amount tx-sender contract-address))
    (is-ok (ft-mint? stacked-stx amount contract-address))))


(define-private (increase-deposit (amount uint)) 
  (let (
        (cycle-id (get-current-cycle-id))
        (cycle-info (get-cycle cycle-id))
        (reputation (ft-get-balance decent-delegate-reputation stacker))
        (no-more-rep (reputation-no-mo!))
        (cycle-exists (is-some cycle-info)))
    (asserts! cycle-exists (err ERROR-i-have-never-met-this-man-in-my-life))
    (let (
          (current-deposit  (get-current-deposit))
          (new-collateral-amount (+ current-deposit  amount))
          (promised-rewards (get pledged-payout (unwrap-panic cycle-info)))
          (cycle-expired (is-past-cycle cycle-id))
          (is-promise-fulfilled (>= new-collateral-amount promised-rewards))
    )
    (asserts! (not cycle-expired) 
      (err ERROR-didnt-we-just-go-through-this-the-other-day))
    (set-deposit new-collateral-amount)
    (if is-promise-fulfilled
      (begin
        (asserts! (< reputation u12) 
          (err ERROR-you-cant-get-any-awesomer))
        (asserts! (not no-more-rep)
          (err ERROR-you-had-12-chances-wtf!))
        (asserts! (is-ok (award-reputation))
          (err ERROR-wtf-stacks!!!))
        (ok true))
      (ok true)))))

(define-private (award-reputation) 
  (let ((supply (ft-get-balance decent-delegate-reputation contract-address)))
    (if (> supply u0)
      (ft-transfer? decent-delegate-reputation u1 contract-address stacker) 
      (ok true))))    


(define-private (lock-and-mint-DDX (amount uint) (sacrifice-stx-for-padding bool))
  (let (
      (cycle-info (unwrap-panic (get-cycle (get-next-cycle-id))))
      (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
      ;; you can add the difference if you've contributed before
      (can-safely-add-padding (or sacrifice-stx-for-padding (not (is-new-delegator))))
      ;; Reach goal after getting the amount of stacks required before starting
      
      (new-stake-info (get-new-stake amount))
      ;; How much stx are required to fulfill stacking
      (max-possible-addition (get max-possible-addition new-stake-info))
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

      (err ERROR-requires-padding))

    (asserts! (> max-possible-addition u0) 
      (err 
        ERROR-better-luck-next-time
      ))
    
      (let
        (
          (stx-result (stx-transfer? max-possible-addition tx-sender contract-address))
          (mint-result (ft-mint? stacked-stx max-possible-addition tx-sender))
        )
        (asserts! (is-ok stx-result) 
          (err (unwrap-err-panic stx-result)))
        (asserts! (is-ok mint-result) 
          (err  (unwrap-err-panic mint-result)))
    )
    (ok new-stake-info)))


;; I know I know
(define-private (set-deposit (deposited-collateral uint))
  (map-set stacking-offer-details 
    {cycle: (get-current-cycle-id)}
    (merge 
      (unwrap-panic (get-cycle (get-current-cycle-id)))
      { deposited-collateral: deposited-collateral,})))


(define-private (contract-stx? (amount uint) (recipient principal)) 
  (as-contract (stx-transfer? amount tx-sender recipient)))

;; Readonly functions
;;

(define-read-only (get-next-cycle-info) 
  (get-cycle (get-next-cycle-id)))

(define-read-only (get-next-cycle-id)
  (+ (burn-height-to-reward-cycle burn-block-height) u1))

(define-read-only (get-next-pox-start) 
  (let ((next-cycle (get-next-cycle-id)))
    (reward-cycle-to-burn-height next-cycle)))

;; (define-private (get-cycle-start (cycle uint)) 
;;   (if (<= cycle u1) first-burnchain-block-height
;;     (let ((fixed-height (- first-burnchain-block-height prepare-cycle-length))
;;         (cycle-start (+ fixed-height (* cycle u2100))))
;;       cycle-start)))

(define-read-only (is-creator) 
  (is-eq stacker tx-sender))

;; what rewards you could get right now
;; and what rewards you could get later
(define-read-only (calculate-cycle-rewards (cycle uint) (personal-stake uint) (total-stake uint)) 
  (let (
    (current-cycle-info (get-cycle cycle))
  )
    (asserts! (is-some current-cycle-info) 
      (err ERROR-i-have-never-met-this-man-in-my-life))
    (let (
          (info-unpacked (unwrap-panic current-cycle-info))
          (pledged-payout (get pledged-payout info-unpacked))
          (current-funds (get deposited-collateral info-unpacked))
          ;; Sometimes the payout would be bigger than promised
          ;; And sometimes that payout comes sooner not later
          (largest-payout-pool (if (> current-funds pledged-payout) current-funds pledged-payout))
          (rewards-if-patient (/ (* personal-stake largest-payout-pool) total-stake))
          (rewards-if-impatient (/ (* personal-stake current-funds) total-stake))
        )
    (ok {rewards-if-patient: rewards-if-patient, rewards-if-impatient: rewards-if-impatient}))))

(define-read-only (get-cycle (cycle uint)) 
  (map-get? stacking-offer-details {cycle: cycle}))

(define-read-only (reputation-no-mo!) 
  (is-eq (ft-get-supply decent-delegate-reputation) u0))




(define-read-only (delegate-assertions (amount uint))
  (let 
      ((cycle-id (get-next-cycle-id))
      (cycle-info (unwrap-panic (get-cycle cycle-id)))
      (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
      (lock-collateral-period (get lock-collateral-period cycle-info))
      (lock-started-at (get lock-started-at cycle-info))
      (lock-expires-at (+ lock-started-at lock-collateral-period))
      (collateral-lock-valid (< block-height lock-expires-at))
      (cycle-locked-amount (get-cycle-locked-amount cycle-id))
      (balance (stx-get-balance tx-sender)))

      (asserts! (>= amount minimum-delegator-stake) 
        (err ERROR-you-poor-lol))
      ;; you can't delegate your stx if the cycle expired after not
      ;; completing the amount required to start stacking
      (asserts! collateral-lock-valid
        (err ERROR-better-luck-next-time))
      ;; The cycle must have existed before delegating
      (asserts! (is-some cycle-locked-amount) 
        (err ERROR-i-have-never-met-this-man-in-my-life))
      ;; Must have enough balance to delegate
      (asserts! (>= balance amount) 
        (err ERROR-you-poor-lol))
      (ok true)))


(define-read-only (get-delegator-stake (delegator principal))
  (default-to {locked-amount: u0} (map-get? delegator-stx-vault {delegator: delegator})))

(define-read-only (is-new-delegator)
  (is-eq u0 (get locked-amount (get-delegator-stake tx-sender))))

(define-read-only (get-new-stake (amount uint))
  (let (
    (cycle-id (get-next-cycle-id))
    (cycle-info (unwrap-panic (get-cycle cycle-id)))
    (cycle-locked-amount (get locked-amount (unwrap-panic (get-cycle-locked-amount cycle-id))))
    (total-required-stake (get total-required-stake cycle-info))
    (stake (get-delegator-stake tx-sender))
    ;; How much stx are required to fulfill stacking
    (remaining-required-stake (- total-required-stake cycle-locked-amount))
    ;; The max possible STX a delegator can put in
    ;; this would make it possible for fixed sets of
    ;; collateralized pools
    ;; so that the distribution is fair
    (max-possible-addition 

      (if (> amount remaining-required-stake) remaining-required-stake amount))

    ;; get the old locked balance
    (delegator-sum-stake 
          (+ max-possible-addition (get locked-amount stake))))
    {delegator-sum-stake: delegator-sum-stake, max-possible-addition: max-possible-addition}))


(define-read-only (get-current-deposit) 
  (get deposited-collateral (unwrap-panic (get-cycle (get-current-cycle-id)))))
(define-read-only (get-cycle-locked-amount (cycle-id uint)) 
  (map-get? cycle-stx-vault {cycle: cycle-id}))


(define-read-only (is-past-cycle (cycle uint)) 
  (> (get-current-cycle-id) cycle))

(define-read-only (get-delegator-info (cycle-id uint) (delegator principal)) 
  (map-get? delegators {cycle: cycle-id, delegator: delegator}))

(define-read-only (is-cycle-expired (cycle-id uint)) 
  (let 
    ((cycle-info (unwrap-panic (get-cycle cycle-id)))
    (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
    (lock-collateral-period (get lock-collateral-period cycle-info))
    (lock-started-at (get lock-started-at cycle-info))
    (total-required-stake (get total-required-stake cycle-info))
    (collateral-lock-expired (>= block-height (+ lock-started-at lock-collateral-period)))
    (cycle-locked-amount (get-cycle-locked-amount cycle-id)))
  (and collateral-lock-expired (< (get locked-amount (unwrap-panic cycle-locked-amount)) total-required-stake)))
)




;; util
;; MY EYES MY EYES!!!
;; ustx might have greater value in the future
;; now it's just a nuisance of many many zeroes
(define-read-only (to-ustx (amount uint)) (* amount u1000000))


;; Public Functions
;;



(define-public (create-decent-pool
    (pledged-payout uint)
    (minimum-delegator-stake uint)
    (cycle-count uint)
    (collateral uint)
    ;; TODO: use cycle expiry instead
    ;; when it would be not feasible to stack
    (lock-collateral-period uint)
    (total-required-stake uint)
    (pox-address {hashbytes: (buff 20), version: (buff 1)}))

  (let
    ((balance (stx-get-balance tx-sender))
    (next-cycle (get-next-cycle-id)))

    (asserts! (check-caller-allowed)
      (err ERROR-ummm-this-is-a-PEOPLE-contract))
    (asserts! (is-creator)
      (err ERROR-not-my-president!))
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
        deposited-collateral: collateral,
        lock-collateral-period: lock-collateral-period,
        lock-started-at: block-height,
        total-required-stake: total-required-stake,
        pox-address: pox-address,
      })))
  )


(define-public (deposit-to-collateral (amount uint)) 
  (let 
    ((balance (stx-get-balance tx-sender)))
    
    (asserts! (and (>= balance amount) (> amount u0))
      (err ERROR-you-poor-lol))

    (asserts! (deposit amount)
      (err ERROR-wtf-stacks!!!))

    (increase-deposit amount)))



;; if you want you could get your cut but 
;; you won't be eligible to get the rest of the rewards
;; they would be reserved for the stacker
(define-public (redeem-reward (cycle uint))
  ;; if within the cycle when not enough funds
  (let ((delegator-vault-info (get-delegator-stake tx-sender))
        (locked-amount (get locked-amount delegator-vault-info))
        (cycle-info (unwrap-panic (get-cycle cycle)))
        (total-required-stake (get total-required-stake cycle-info))
        (was-patient (is-past-cycle cycle))
        (reward-info (unwrap-panic (calculate-cycle-rewards cycle locked-amount total-required-stake)))
        (patient-reward (get rewards-if-patient reward-info))
        (impatient-reward (get rewards-if-impatient reward-info))
        (reward-to-payout (if was-patient patient-reward impatient-reward)))
    (asserts! (> reward-to-payout u0) 
      (err ERROR-you-poor-lol))
    (let (
      (stx-result (ft-transfer? stacked-stx reward-to-payout (as-contract tx-sender) tx-sender))
    )
      (asserts! (is-ok stx-result)
        (err (unwrap-err-panic stx-result)))
      (map-set delegators
        {
          delegator: tx-sender, 
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
  )



(define-public (withdraw-stake (cycle-id uint))
  (let ((stake-info (get-delegator-stake tx-sender))
    (delegator-info (get-delegator-info cycle-id tx-sender))
    (stake (get locked-amount stake-info)))
    (asserts! (check-caller-allowed)
      (err ERROR-ummm-this-is-a-PEOPLE-contract))
    (asserts! (is-past-cycle cycle-id)
      (err ERROR-LOCKED-have-a-little-faith))
    (asserts! (> stake u0) 
      (err ERROR-you-poor-lol))
    (asserts!
        (and
          (is-ok (contract-stx? stake tx-sender))
          (is-ok (ft-burn? stacked-stx stake tx-sender)))
    (err ERROR-wtf-stacks!!!))
    (ok true)))



(define-public (delegate (amount uint) (sacrifice-stx-for-padding bool))
    (let (
      (assertions (delegate-assertions amount)))

      (asserts! (is-ok assertions) 
        (err (unwrap-err-panic assertions)))

      (let 
        (
          (cycle-id (get-next-cycle-id))
          (locked-amount (get locked-amount (unwrap-panic (get-cycle-locked-amount cycle-id))))
          ;; How much stx are required to fulfill stacking
          (lock-response (lock-and-mint-DDX amount sacrifice-stx-for-padding)))
        ;; stacker would then append padding and start stacking
        (asserts! (is-ok lock-response)
          (err (unwrap-err-panic lock-response)))

        (let
          (
            (cycle-info (unwrap-panic (get-cycle cycle-id)))
            (delegator-sum-stake (get delegator-sum-stake (unwrap-panic lock-response)))
            (max-possible-addition (get max-possible-addition (unwrap-panic lock-response)))
            (new-total-locked-amount (+ locked-amount max-possible-addition))
            (reached-goal (>= new-total-locked-amount (get total-required-stake cycle-info)))
                  ;; This has preplexed me for a while now
            (stacking-response
              (if reached-goal
                ;; just for testing since clarity vscode analysis
                ;; is upset with contract calls
                ;; (ok true)
                (as-contract 
                  (contract-call? 
                    'ST000000000000000000002AMW42H.pox stack-stx 
                      (stx-get-balance tx-sender) 
                      (get pox-address cycle-info)
                      burn-block-height 
                      (get cycle-count cycle-info)))

                (err (to-int ERROR-wtf-stacks!!!))))
            (did-stack (is-ok stacking-response)))
          (asserts! 
            ;; it either stacked or didn't stack
            (or (and reached-goal did-stack) (not reached-goal))
              (err (to-uint (unwrap-err-panic stacking-response))))

          (map-set 

            cycle-stx-vault

            {cycle: cycle-id} 

            {locked-amount: new-total-locked-amount, is-stacked: did-stack})
          (map-set 
            delegators 
            { delegator: tx-sender, cycle: cycle-id } 
            { did-withdraw-rewards: false })
          (map-set 
            delegator-stx-vault
            { delegator: tx-sender } 
            { locked-amount: delegator-sum-stake, })
          (ok
            {
              cycle: cycle-id,
              locked-amount: new-total-locked-amount,
              contract-balance: (stx-get-balance contract-address),
              delegator: tx-sender,
              delegated-amount: delegator-sum-stake,
              time-until-cycle-expiry: (+ (get lock-started-at cycle-info) (get lock-collateral-period cycle-info)),
            })))))


;;; DDX Section
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

      (asserts! (check-caller-allowed) 
        (err ERROR-ummm-this-is-a-PEOPLE-contract))
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

(define-data-var token-uri (string-utf8 256) u"")

(define-public (set-token-uri (uri (string-utf8 256))) 
  (begin
    (asserts! (is-creator) (err ERROR-not-my-president!))
    (ok (var-set token-uri uri))))

;; stolen from jude

(define-read-only (get-name)
    (ok "Decent-Delegate-STX"))

(define-read-only (get-symbol)
    (ok "DDX"))

(define-read-only (get-decimals)
    (ok u6))

(define-read-only (get-balance-of (user principal))
    (ok (ft-get-balance stacked-stx user)))

(define-read-only (get-total-supply)
    (ok (ft-get-supply stacked-stx)))

(define-read-only (get-token-uri)
    (ok (some (var-get token-uri))))


;; Stolen from PoX

(define-private (check-caller-allowed)
    (or (is-eq tx-sender contract-caller)
        (let ((caller-allowed 
                ;; if not in the caller map, return false
                (unwrap! (map-get? allowance-contract-callers
                                  { sender: tx-sender, contract-caller: contract-caller })
                        false)))
          ;; is the caller allowance expired?
          (if (< burn-block-height (unwrap! (get until-burn-ht caller-allowed) true))
              false
              true))))

;; Revoke contract-caller authorization to call stacking methods
(define-public (disallow-contract-caller (caller principal))
  (begin 
    (asserts! (is-eq tx-sender contract-caller)
              (err ERROR-UNAUTHORIZED))
    (ok (map-delete allowance-contract-callers { sender: tx-sender, contract-caller: caller }))))

(define-public (allow-contract-caller (caller principal) (until-burn-ht (optional uint)))
  (begin
    (asserts! (is-eq tx-sender contract-caller)
              (err ERROR-UNAUTHORIZED))
    (ok (map-set allowance-contract-callers
              { sender: tx-sender, contract-caller: caller }
              { until-burn-ht: until-burn-ht }))))
