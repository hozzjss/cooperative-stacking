;; a delegatee would say that they would payout delegators
;; an X amount of STX and would provide half or a portion of that STX in advance
;; delegators then would delegate to the contract their STX and based on their percentage
;; of the total stake they would receive rewards or the locked STX
;; each delegatee would have one pool at a time and would have one collateral pool as well
;; the collateral is locked until N cycles (whatever cycle defined in the pool) pass
;; and within the cycle the delegatee would progressively fill up the rest of the promised
;; stx rewards

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
;; (define-trait pox-fns 
;;   (
;;     (get-stacker-info (principal)
;;       (optional {
;;         amount-ustx: uint, 
;;         first-reward-cycle: uint, 
;;         lock-period: uint, 
;;         pox-addr: { hashbytes: (buff 20), version: (buff 1) }
;;       } none))))

;; this token would be awarded at the end of each successful cycle
;; and would be taken away if the cycle failed to produce the promised STX
(define-fungible-token decent-delegate-reputation u12)

;; in the same way this would be for a delegate who failed to
;; deliver on the promised STX if they didn't have decent tokens
;; then this token is given otherwise the decent token is burnt
;; a delegate gets only 12 chances of being a decent person
(define-fungible-token indecent-delegate-reputation)

(define-constant ERROR-ummm-this-is-a-PEOPLE-contract u1000)
(define-constant ERROR-you-poor-lol u1001)
(define-constant ERROR-bitch-this-aint-a-donation-box u1002)
(define-constant contract-address (as-contract tx-sender))
(define-constant stacker tx-sender)

;; (define-constant pox 'ST000000000000000000002AMW42H.pox)

;; how many blocks till collateral and delegation expire

(define-constant lock-collateral-period-min u200)

(define-map stacking-offer-details 
  {cycle: uint}
  {
    total-payout: uint,
    minimum-stake: uint,
    cycle-count: uint,
    min-collateral: uint,
    deposited-collateral: uint,
    lock-collateral-period: uint,
    total-required-stake: uint
  }
)

(map-set stacking-offer-details {cycle: u4} {
  total-payout: (to-ustx u15000), 
  minimum-stake: (to-ustx u100),
  cycle-count: u1,
  min-collateral: (to-ustx u7500),
  ;; equal to 1 million
  deposited-collateral: u0,
  lock-collateral-period: u200,
  total-required-stake: (to-ustx (to-ustx u1))
})


(define-data-var current-cycle uint u4)


(define-map delegators 
  {delegator: principal} 
  {did-withdraw-reward: bool}
)


(define-public (deposit-to-collateral (amount uint)) 
  (let (
    (balance (stx-get-balance tx-sender))) 

    (asserts! (is-stacker)
      (err ERROR-bitch-this-aint-a-donation-box))

    (asserts! (is-eq contract-caller tx-sender)
      (err ERROR-ummm-this-is-a-PEOPLE-contract))

    (asserts! (>= balance amount)
      (err ERROR-you-poor-lol))

    (asserts! (deposit amount)
      (err ERROR-you-poor-lol))

    (asserts! (increase-deposit amount)
      (err ERROR-you-poor-lol))
    )



(define-private (do-delegate (amount uint) (until-block-ht uint)) 
    ;; (contract-call? pox delegate-stx (to-ustx amount) (as-contract tx-sender) until-block-ht none))
    (ok true))



;; util
;; MY EYES MY EYES!!!
;; ustx might have greater value in the future
;; now it's just a nuisance of many many zeroes
(define-private (to-ustx (amount uint)) (* amount u1000000))

(define-private (deposit (amount uint)) 
  (is-ok (stx-transfer? amount tx-sender contract-address)))

(define-private (is-stacker) 
  (is-eq tx-sender stacker))

(define-private (get-current-deposit) 
  (get deposited-collateral (get-current-cycle)))

(define-private (set-current-cycle 
  (deposited-collateral (optional uint))
  (total-payout (optional uint))
  (minimum-stake (optional uint))
  (cycle-count (optional uint))
  (min-collateral (optional uint))
  (lock-collateral-period (optional uint))
  (total-required-stake (optional uint))
) 
  (let (
    (current-cycle-info (get-current-cycle))
    (default-deposited-collateral (get deposited-collateral current-cycle-info))
    (default-total-payout (get total-payout current-cycle-info))
    (default-minimum-stake (get minimum-stake current-cycle-info))
    (default-cycle-count (get cycle-count current-cycle-info))
    (default-min-collateral (get min-collateral current-cycle-info))
    (default-lock-collateral-period (get lock-collateral-period current-cycle-info))
    (default-total-required-stake (get total-required-stake current-cycle-info))
  )
  (map-set stacking-offer-details 
    {cycle: (var-get current-cycle)}
    {
      deposited-collateral: (default-to default-deposited-collateral deposited-collateral),
      total-payout: (default-to default-total-payout total-payout),
      minimum-stake: (default-to default-minimum-stake minimum-stake),
      cycle-count: (default-to default-cycle-count cycle-count),
      min-collateral: (default-to default-min-collateral min-collateral),
      lock-collateral-period: (default-to default-lock-collateral-period lock-collateral-period),
      total-required-stake: (default-to default-total-required-stake total-required-stake),
    })
))

(define-private (set-current-deposit (amount uint)) 
  (set-current-cycle (some amount)))

(define-private (increase-deposit (amount uint)) 
  (let
    ((new-collateral-amount (+ (get-current-deposit) amount))
    (promised-rewards (get total-payout (get-current-cycle)))
    (is-promise-fulfilled (>= new-collateral-amount promised-rewards)))
    (set-current-deposit new-collateral-amount)
    (ft-mint? decent-delegate-reputation u1 stacker)
    ))

(define-private (get-current-cycle) 
  (unwrap-panic (map-get? stacking-offer-details {cycle: (var-get current-cycle)})))

(define-read-only (has-delegate-locked-collateral) 
  (let ((min-collateral (get min-collateral (get-current-cycle)))) 
  (>= (get deposited-collateral (get-current-cycle)) min-collateral )))

(define-private (get-stacker-info (delegator principal)) 
  ;; (contract-call? 'ST000000000000000000002AMW42H.pox get-stacker-info delegator))
  (ok true))


(define-read-only (calculate-current-reward (personal-stake uint) (total-stake uint)) 
  (let (
    (current-cycle-info (get-current-cycle))
    (total-payout (get total-payout current-cycle-info))
    (current-funds (get deposited-collateral current-cycle-info))
    (rewards-if-patient (/ (* personal-stake total-payout) total-stake))
    ;; if you want you could get your cut but 
    ;; you won't be eligible to get the rest of the rewards
    ;; they would be reserved for the stacker
    (rewards-if-impatient (/ (* personal-stake current-funds) total-stake))
    ) 
    (ok {rewards-if-patient: rewards-if-patient, rewards-if-impatient: rewards-if-impatient})))

(define-public (redeem-reward (delegator principal)) 
  ;; if within the cycle when not enough funds 
  ;; have been deposited and still in the pox cycle
  ;; only the delegator themselves might request to redeem
  ;; if the cycle ended the delegate might call this to payout
  ;; the delegator
  (ok true))

;;

;; payout
;; by friedget muffke
;;
;; (define-private (stx-transfer (details {stacker: principal, part-ustx: uint}))
;;   (stx-transfer? (get part-ustx details) contract-address (get stacker details)))

;; (define-private (check-err (result (response bool uint)) (prior (response bool uint)))
;;   (match prior
;;     ok-value result
;;     err-value  (err err-value)))

;; (define-private (calc-parts (member {stacker: principal, amount-ustx: uint}) 
;;             (context {payout-ustx: uint, stacked-ustx: uint, result: (list 750 {stacker: principal, part-ustx: uint})}))
;;   (let (
;;     (amount-ustx (get amount-ustx member)) 
;;     (payout-ustx (get payout-ustx context)) 
;;     (stacked-ustx (get stacked-ustx context)))          
;;     (let (
;;       (payout-details {stacker: (get stacker member), part-ustx: (/ (* amount-ustx payout-ustx) stacked-ustx)}))
;;       {payout-ustx: payout-ustx, stacked-ustx: stacked-ustx,
;;         result: (unwrap-panic (as-max-len? (append (get result context) payout-details) u750))})))


;; (define-public (payout (payout-ustx uint) (stacked-ustx uint) (members (list 750 (tuple (stacker principal) (amount-ustx uint)))))
;;   (let (
;;     (member-parts 
;;       (get result 
;;         (fold calc-parts members {payout-ustx: payout-ustx, stacked-ustx: stacked-ustx, result: (list)}))))
;;     (fold check-err
;;       (map stx-transfer member-parts) (ok true))))
