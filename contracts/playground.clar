
(define-data-var current-slice-index uint u0)
(define-private (go-to-7 (item (buff 1))) 
  (if 
    (>= (var-get current-slice-index) u7) 
    false 
    (begin 
      (var-set current-slice-index (+ (var-get current-slice-index) u1)))))

(define-private (slice-first-7 (input (buff 330))) 
  (filter go-to-7 input)
  (var-set current-slide-index u0))

(define-read-only (util-delete-me (input (buff 330)))
  (let (
    (first-hash (hash160 input))
    (btc-net-prefix (concat 0x00 first-hash))
    (second-hash (sha256 btc-net-prefix))
    (third-hash (sha256 btc-net-prefix))
    ;; (checksum (unwrap-panic (as-max-len? third-hash u4)))
    ;; (btc-checksum-postfix (concat btc-net-prefix checksum)))
  ) 
    (ok {stacks: (keccak256 input), btc: (as-max-len? first-hash u30)}))
  )
