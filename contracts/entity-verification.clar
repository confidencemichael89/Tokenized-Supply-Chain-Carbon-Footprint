;; Generation Tracking Contract
;; Records energy production

(define-map generation-events
  {
    node-id: (string-ascii 24),
    timestamp: uint
  }
  {
    amount: uint,
    source-type: (string-ascii 10), ;; solar, wind, etc.
    recorded-by: principal
  }
)

(define-map node-total-generation
  { node-id: (string-ascii 24) }
  { total: uint }
)

(define-read-only (get-generation-event (node-id (string-ascii 24)) (timestamp uint))
  (map-get? generation-events { node-id: node-id, timestamp: timestamp })
)

(define-read-only (get-node-total-generation (node-id (string-ascii 24)))
  (default-to { total: u0 } (map-get? node-total-generation { node-id: node-id }))
)

(define-public (record-generation
    (node-id (string-ascii 24))
    (amount uint)
    (source-type (string-ascii 10)))
  (let (
    (timestamp block-height)
    (current-total (get total (get-node-total-generation node-id)))
    (node-contract (contract-call? .node-verification get-node node-id))
  )
    ;; Check if node exists and is verified
    (asserts! (is-some node-contract) (err u1)) ;; Node not found
    (asserts! (contract-call? .node-verification is-node-verified node-id) (err u2)) ;; Node not verified

    ;; Record the generation event
    (map-set generation-events
      { node-id: node-id, timestamp: timestamp }
      {
        amount: amount,
        source-type: source-type,
        recorded-by: tx-sender
      }
    )

    ;; Update the total generation for this node
    (map-set node-total-generation
      { node-id: node-id }
      { total: (+ current-total amount) }
    )

    (ok timestamp)
  )
)

(define-read-only (get-generation-in-range (node-id (string-ascii 24)) (start-time uint) (end-time uint))
  (let ((current-time block-height))
    (asserts! (<= end-time current-time) (err u3)) ;; End time cannot be in the future
    (asserts! (<= start-time end-time) (err u4)) ;; Start time must be before end time

    ;; Note: In a real implementation, we would need to iterate through the range
    ;; and collect all events. This is simplified for clarity.
    (ok { start-time: start-time, end-time: end-time })
  )
)
