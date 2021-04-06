;; now the contract would stack itself
;; instead of pox complications
;; this way if people wanted to take their funds after the cycle ends
;; or the cycle didn't reach its goal and the collateral-lock-period
;; expired

;; TODO: change this when changing to mainnet
;; (impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-10-ft-standard.ft-trait)
;; (impl-trait .sip-10-ft-standard.ft-trait)


(define-constant ERROR-UNAUTHORIZED u1000)
(define-constant ERROR-not-enough-funds u1001)
(define-constant ERROR-this-aint-a-donation-box u1002)
(define-constant ERROR-wtf-stacks!!! u1003)
(define-constant ERROR-not-contract-creator u1004)
(define-constant ERROR-can-only-do-this-once u1005)
(define-constant ERROR-only-current-cycle-bro! u1006)
(define-constant ERROR-not-found u1007)
(define-constant ERROR-you-cant-get-any-awesomer u1008)
(define-constant ERROR-you-had-12-chances-wtf! u1009)
(define-constant ERROR-LOCKED-have-a-little-faith u1010)
(define-constant ERROR-amount-too-small u1011)
(define-constant ERROR-better-luck-next-time u1012)
(define-constant ERROR-requires-padding u1013)


;; replace this with your public key hashbytes pay to public key hashbytes p2pkh, i learnt that yesterday

;; (define-constant pox-address {hashbytes: 0x0000000000000000000000000000000000000000, version: 0x00})

(define-constant contract-address (as-contract tx-sender))
(define-constant stacker tx-sender)

;; how many blocks till collateral and delegation expire
;; How many blocks before locking starts 3/5 is a personal choice might be changed later
;; This is a new protocol all of this is new, we're still defining all this
(define-constant stacking-grace-period (* (/ (get-reward-cycle-length) u5) u3))



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
    total-required-stake: uint,
    pox-address: {version: (buff 1), hashbytes: (buff 20),},
    available-funds: uint,
    did-stack: bool,
  })

(define-map cycle-stx-vault {cycle: uint} {locked-amount: uint, is-stacked: bool})


(define-map delegators-reward-status
  {delegator: principal, cycle: uint} 
  {
    withdrawn-rewards: uint,
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


(define-private (get-stacking-info)
  (contract-call? 'ST000000000000000000002AMW42H.pox 
      get-stacker-info contract-address))

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
  (stx-transfer? amount tx-sender contract-address))


(define-private (increase-deposit (amount uint)) 
  (let (
        (cycle-id (get-current-cycle-id))
        (cycle-info (get-cycle cycle-id))
        (reputation (ft-get-balance decent-delegate-reputation stacker))
        (no-more-rep (reputation-no-mo!))
        (cycle-exists (is-some cycle-info)))
    (asserts! cycle-exists (err ERROR-not-found))
    (let (
          (current-deposit  (get-current-deposit))
          (available-funds (get available-funds (unwrap-panic cycle-info)))
          (new-collateral-amount (+ current-deposit amount))
          (pledged-payout (get pledged-payout (unwrap-panic cycle-info)))
          (cycle-expired (is-past-cycle cycle-id))
          (is-promise-fulfilled (>= new-collateral-amount pledged-payout))
    )
    (asserts! (not cycle-expired) 
      (err ERROR-can-only-do-this-once))
    (set-deposit new-collateral-amount (+ available-funds amount))
    (is-ok 
      (if is-promise-fulfilled
        (begin
          (asserts! (< reputation u12) 
            (err ERROR-you-cant-get-any-awesomer))
          (asserts! (not no-more-rep)
            (err ERROR-you-had-12-chances-wtf!))
          (award-reputation))
        (ok true)))
      (deposit amount))))

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


(define-private (set-deposit (deposited-collateral uint) (available-funds uint))
  (map-set stacking-offer-details
    {cycle: (get-current-cycle-id)}
    (merge 
      (unwrap-panic (get-cycle (get-current-cycle-id)))
      { 
        deposited-collateral: deposited-collateral,
        available-funds: available-funds,
      })))


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
(define-read-only (calculate-cycle-rewards (cycle-id uint)) 
  (let (
    (delegator tx-sender)
    (withdrawn-rewards (default-to u0 (get withdrawn-rewards (get-delegator-info cycle-id delegator))))
    (cycle-info (unwrap! (get-cycle cycle-id) (err ERROR-not-found)))
    (available-funds (get available-funds cycle-info))
    (total-rewards (get deposited-collateral cycle-info))
    (ddx-balance (ft-get-balance stacked-stx delegator))
    (ddx-supply (ft-get-supply stacked-stx))
    (ddx-percentage (/ (* u1000000 ddx-balance) ddx-supply))
    ;; (reward-per-ddx (/ (* u1000000 total-available-rewards) ddx-supply))
    (reward (- (/ (* ddx-percentage total-rewards) u1000000) withdrawn-rewards))
  )
    (ok reward)))

(define-read-only (get-cycle (cycle uint)) 
  (map-get? stacking-offer-details {cycle: cycle}))

(define-read-only (reputation-no-mo!) 
  (is-eq (ft-get-supply decent-delegate-reputation) u0))




(define-read-only (delegate-assertions (amount uint))
  (let 
      ((cycle-id (get-next-cycle-id))
      ;; The cycle must have existed before delegating
      (cycle-info (unwrap! (get-cycle cycle-id) (err ERROR-not-found)))
      (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
      (cycle-start-time (reward-cycle-to-burn-height cycle-id))
      
      (balance (stx-get-balance tx-sender)))

      ;; Must have enough balance to delegate
      (asserts! (and (>= amount minimum-delegator-stake) (>= balance amount))
        (err ERROR-not-enough-funds))
      ;; you can't delegate your stx if the cycle expired after not
      ;; completing the amount required to start stacking
      (asserts! (< burn-block-height (+ cycle-start-time stacking-grace-period))
        (err ERROR-better-luck-next-time))
      (ok true)))


(define-read-only (get-delegator-stake (delegator principal))
  (default-to {locked-amount: u0} (map-get? delegator-stx-vault {delegator: delegator})))

(define-read-only (is-new-delegator)
  (is-eq u0 (get locked-amount (get-delegator-stake tx-sender))))

(define-read-only (get-new-stake (amount uint))
  (let (
    (cycle-id (get-next-cycle-id))
    (cycle-info (unwrap-panic (get-cycle cycle-id)))
    (cycle-locked-amount (get-cycle-locked-amount))
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
(define-read-only (get-cycle-locked-amount) 
  (ft-get-supply stacked-stx))


(define-read-only (is-past-cycle (cycle uint)) 
  (> (get-current-cycle-id) cycle))

(define-read-only (get-delegator-info (cycle-id uint) (delegator principal)) 
  (map-get? delegators-reward-status {cycle: cycle-id, delegator: delegator}))

(define-read-only (is-cycle-expired (cycle-id uint)) 
  (let 
    ((cycle-info (unwrap-panic (get-cycle cycle-id)))
    (minimum-delegator-stake (get minimum-delegator-stake cycle-info))
    (cycle-start-time (reward-cycle-to-burn-height cycle-id))
    (total-required-stake (get total-required-stake cycle-info))
    (collateral-lock-expired (> burn-block-height (+ cycle-start-time stacking-grace-period))))
  (and collateral-lock-expired (< (get-cycle-locked-amount) total-required-stake)))
)




;; util
;; MY EYES MY EYES!!!
;; ustx might have greater value in the future
;; now it's just a nuisance of many many zeroes
(define-read-only (to-ustx (amount uint)) (* amount u1000000))


(define-read-only (get-current-ddx-value) 
  (let (
    (stx-balance (stx-get-balance contract-address))
    (ddx-supply (ft-get-supply stacked-stx))
    )
  (/ (/ (* u1000000 stx-balance) ddx-supply) u1000000)))




;; Public Functions
;;



(define-public (create-decent-pool
    (pledged-payout uint)
    (minimum-delegator-stake uint)
    (cycle-count uint)
    (collateral uint)
    (total-required-stake uint)
    (pox-address {hashbytes: (buff 20), version: (buff 1)}))

  (let
    ((balance (stx-get-balance tx-sender))
    (next-cycle (get-next-cycle-id)))

    (asserts! (check-caller-allowed)
      (err ERROR-UNAUTHORIZED))
    (asserts! (is-creator)
      (err ERROR-not-contract-creator))
    (asserts! (>= balance collateral)
      (err ERROR-not-enough-funds))
    (asserts! (is-none (map-get? stacking-offer-details {cycle: next-cycle})) 
      (err ERROR-can-only-do-this-once))

    (map-set stacking-offer-details 
      {
        cycle: next-cycle,
      } 
      {
        pledged-payout: pledged-payout, 
        minimum-delegator-stake: minimum-delegator-stake,
        cycle-count: cycle-count,
        collateral: collateral,
        deposited-collateral: collateral,
        available-funds: collateral,
        total-required-stake: total-required-stake,
        pox-address: pox-address,
        did-stack: false
      })
    (deposit collateral))
  )


(define-public (deposit-to-collateral (amount uint)) 
  (let 
    ((balance (stx-get-balance tx-sender)))
    
    (asserts! (and (>= balance amount) (> amount u0))
      (err ERROR-not-enough-funds))
    (increase-deposit amount)))


(define-read-only (get-ddx-balance (hodler principal)) 
  (ft-get-balance stacked-stx hodler))


(define-private (is-funds-unlocked)
  ;; (let ((contract-stx-balance (stx-get-balance contract-address))
  ;;       (ddx-supply (unwrap-panic (get-total-supply)))) 
        ;; Funds are unlocked when stacking is done
    (is-none (get-stacking-info)))

(define-public (unwrap-DDX (amount uint))
  (let (
    (ddx-balance (unwrap! (get-balance-of tx-sender) (err ERROR-not-enough-funds)))
    ;; (stx-balance (stx-get-balance contract-address))
    ;; (ddx-supply (ft-get-supply stacked-stx))
    ;; (ddx-price (/ (* u1000000 stx-balance) ddx-supply))
    ;; (stx-to-send (/ (* amount ddx-price) u1000000))
    )
    (asserts! (check-caller-allowed)
      (err ERROR-UNAUTHORIZED))
    (asserts! (is-funds-unlocked)
      (err ERROR-LOCKED-have-a-little-faith))
    
    (asserts! (and (> amount u0) (>= ddx-balance amount)) 
      (err ERROR-not-enough-funds))
    (let (
        (stx-result (contract-stx? amount tx-sender))
        (burn-result (ft-burn? stacked-stx amount tx-sender))
      )
    (asserts!
      (is-ok stx-result)
      (err (unwrap-err-panic stx-result)))
    (asserts!
      (is-ok burn-result)
      (err (unwrap-err-panic burn-result))))
  (ok true)))


;; Alex Graebe feedback on writing milestones
;; Grantees: A big idea => amazing
;; Grantees: weird unorganized milestones
;; Alex says you should you should:
;; listen the user
;; input from users can change the milestones
;; start small
;; listen to feedback again

(define-public (redeem-rewards (cycle-id uint)) 
  (let (
    (delegator tx-sender)
    ;; the cycle to redeem rewards from should be the past cycle
    ;; or the current cycle this is to ensure that when transferring
    ;; DDX withdrawn rewards are to be taken into account
    (is-valid-cycle (or (is-eq cycle-id (- (get-current-cycle-id) u1)) (is-eq cycle-id (get-current-cycle-id))))
    (withdrawn-rewards (default-to u0 (get withdrawn-rewards (get-delegator-info cycle-id delegator))))
    (cycle-info (unwrap-panic (get-cycle cycle-id)))
    (available-funds (get available-funds cycle-info))
    ;; (reward-per-ddx (/ (* u1000000 total-available-rewards) ddx-supply))
    (reward (unwrap-panic (calculate-cycle-rewards cycle-id)))
    (funds-stacked (is-some (get-stacking-info)))
    (is-complete-cycle (and (get did-stack cycle-info) (is-past-cycle cycle-id)))
  )

  (asserts! is-valid-cycle
    (err ERROR-UNAUTHORIZED))
  (asserts! (or is-complete-cycle funds-stacked) 
    (err ERROR-UNAUTHORIZED))
  (asserts! (> reward u0)
    (err ERROR-not-enough-funds))
  (map-set delegators-reward-status
    {
      cycle: cycle-id,
      delegator: delegator
    } 
    {
      withdrawn-rewards: (+ reward withdrawn-rewards)
    })

  (map-set stacking-offer-details
    {cycle: cycle-id}
    (merge 
      cycle-info
      { 
        available-funds: (- available-funds reward),
      }))

  (contract-stx? reward delegator)))


(define-public (delegate (amount uint) (sacrifice-stx-for-padding bool))
    (let (
      (assertions (delegate-assertions amount)))

      (asserts! (is-ok assertions) 
        (err (unwrap-err-panic assertions)))

      (let 
        (
          (cycle-id (get-next-cycle-id))
          (locked-amount (get-cycle-locked-amount))
          ;; How much stx are required to fulfill stacking
          (lock-response (lock-and-mint-DDX amount sacrifice-stx-for-padding)))
        ;; stacker would then append padding and start stacking
        (asserts! (is-ok lock-response)
          (err (unwrap-err-panic lock-response)))

        (let
          (
            (cycle-info (unwrap-panic (get-cycle cycle-id)))
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
                      new-total-locked-amount
                      (get pox-address cycle-info)
                      burn-block-height 
                      (get cycle-count cycle-info)))

                (err (to-int ERROR-wtf-stacks!!!))))
            (did-stack (is-ok stacking-response)))
          (asserts! 
            ;; it either stacked or didn't stack
            (or (and reached-goal did-stack) (not reached-goal))
              (err (to-uint (unwrap-err-panic stacking-response))))
          (map-set stacking-offer-details
            {cycle: cycle-id}
            (merge 
              cycle-info
              { did-stack: did-stack,}))
          (ok (map-set 
            delegators-reward-status
            { delegator: tx-sender, cycle: cycle-id } 
            { withdrawn-rewards: u0 }))))))


;;; DDX Section
;; This should make stacked stx liquid

(define-fungible-token stacked-stx)


(define-private (calculate-withdrawn-rewards (total-withdrawn-rewards uint) (total-ddx uint) (ddx-to-transfer uint)) 
  (let (
        (percentage (/ (* ddx-to-transfer u1000000) total-ddx))
        (total-withdrawn-reward-amount (/ (* total-withdrawn-rewards percentage) u1000000)))
  
  total-withdrawn-reward-amount))

(define-public (transfer (amount uint) (sender principal) (recipient principal))
    (let (
      (ddx-balance (ft-get-balance stacked-stx sender))
      (current-cycle-id (get-current-cycle-id))
      (current-cycle-withdrawn-rewards (get withdrawn-rewards (get-delegator-info current-cycle-id sender)))
      (last-cycle-id (- current-cycle-id u1))
      (last-cycle-withdrawn-rewards (get withdrawn-rewards (get-delegator-info last-cycle-id sender)))
    )
      ;; amounts lower than 1 DDX are too low
      ;; so I thought to myself that a person
      ;; could send an amount too small that 
      ;; the transferred withdrawn amount is zero
      ;; then I thought well it's actually pretty
      ;; costly in tx fees to do so, so I didn't care to make
      ;; this max 1 whole DDX
      (asserts! (>= amount u1000) 
        (err ERROR-amount-too-small))
      (asserts! (check-caller-allowed) 
        (err ERROR-UNAUTHORIZED))
      ;; IMPOSTER!!!
      (asserts! (and (is-eq sender tx-sender) (not (is-eq sender recipient)))
          (err ERROR-UNAUTHORIZED))
      (if (is-some last-cycle-withdrawn-rewards) 
        (map-set delegators-reward-status 
          {delegator: recipient, cycle: last-cycle-id}
          {withdrawn-rewards: (calculate-withdrawn-rewards (unwrap-panic last-cycle-withdrawn-rewards) ddx-balance amount)})
        false)
      (if (is-some current-cycle-withdrawn-rewards) 
        (map-set delegators-reward-status 
          {delegator: recipient, cycle: current-cycle-id}
          {withdrawn-rewards: (calculate-withdrawn-rewards (unwrap-panic current-cycle-withdrawn-rewards) ddx-balance amount)})
        false)
      ;; here are your frozen tokens, have fun!
      (ft-transfer? stacked-stx amount sender recipient)
    )
)

(define-data-var token-uri (optional (string-utf8 256)) none)

(define-public (set-token-uri (uri (string-utf8 256)))
  (begin
    (asserts! (is-creator) (err ERROR-not-contract-creator))
    (ok (var-set token-uri (some uri)))))

;; stolen from jude

(define-read-only (get-name)
    (ok "Decent-Delegate-STX"))

(define-read-only (get-symbol)
    (ok "DDX"))

(define-read-only (get-decimals)
    (ok u6))

(define-read-only (get-balance-of (user principal))
    (ok (get-ddx-balance user)))

(define-read-only (get-total-supply)
    (ok (ft-get-supply stacked-stx)))

(define-read-only (get-token-uri)
    (ok (var-get token-uri)))

;; Stolen from PoX
(define-private (check-caller-allowed)
    (or (is-eq tx-sender contract-caller)
        (let ((caller-allowed 
                ;; if not in the caller map, return false
                (unwrap! (map-get? allowance-contract-callers
                                  { sender: tx-sender, contract-caller: contract-caller })
                        false)))
          ;; is the caller allowance expired?
          (if (> burn-block-height (unwrap! (get until-burn-ht caller-allowed) true))
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

(define-read-only (get-contract-balance) 
  (ok (as-contract (stx-get-balance tx-sender))))