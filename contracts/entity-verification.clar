;; Entity Verification Contract
;; Validates supply chain participants

(define-data-var admin principal tx-sender)

;; Entity types: 1 = Supplier, 2 = Manufacturer, 3 = Distributor, 4 = Retailer
(define-map entities
  { entity-id: uint }
  {
    principal: principal,
    name: (string-utf8 100),
    entity-type: uint,
    verified: bool
  }
)

(define-data-var next-entity-id uint u1)

;; Register a new entity
(define-public (register-entity (name (string-utf8 100)) (entity-type uint))
  (let ((entity-id (var-get next-entity-id)))
    (begin
      (asserts! (and (>= entity-type u1) (<= entity-type u4)) (err u1))
      (map-insert entities
        { entity-id: entity-id }
        {
          principal: tx-sender,
          name: name,
          entity-type: entity-type,
          verified: false
        }
      )
      (var-set next-entity-id (+ entity-id u1))
      (ok entity-id)
    )
  )
)

;; Verify an entity (admin only)
(define-public (verify-entity (entity-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? entities { entity-id: entity-id })
      entity (begin
        (map-set entities
          { entity-id: entity-id }
          (merge entity { verified: true })
        )
        (ok true)
      )
      (err u404)
    )
  )
)

;; Check if an entity is verified
(define-read-only (is-verified (entity-id uint))
  (match (map-get? entities { entity-id: entity-id })
    entity (ok (get verified entity))
    (err u404)
  )
)

;; Get entity details
(define-read-only (get-entity (entity-id uint))
  (map-get? entities { entity-id: entity-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (var-set admin new-admin)
    (ok true)
  )
)
