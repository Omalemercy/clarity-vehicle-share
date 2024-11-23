;; Vehicle Share Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-vehicle-not-found (err u103))
(define-constant err-not-available (err u104))

;; Data structures
(define-map vehicles
    principal
    {
        model: (string-ascii 50),
        year: uint,
        available: bool,
        current-user: (optional principal),
        owners: (list 10 principal)
    }
)

(define-map ownership-shares
    {vehicle-id: principal, owner: principal}
    uint
)

;; Register a new vehicle
(define-public (register-vehicle (vehicle-id principal) (model (string-ascii 50)) (year uint))
    (let
        ((vehicle-exists (map-get? vehicles vehicle-id)))
        (if (is-some vehicle-exists)
            err-already-exists
            (begin
                (map-set vehicles vehicle-id {
                    model: model,
                    year: year,
                    available: true,
                    current-user: none,
                    owners: (list contract-owner)
                })
                (map-set ownership-shares {vehicle-id: vehicle-id, owner: contract-owner} u100)
                (ok true)
            )
        )
    )
)

;; Transfer ownership shares
(define-public (transfer-shares (vehicle-id principal) (recipient principal) (share-amount uint))
    (let
        ((sender-shares (default-to u0 (map-get? ownership-shares {vehicle-id: vehicle-id, owner: tx-sender}))))
        (if (>= sender-shares share-amount)
            (begin
                (map-set ownership-shares {vehicle-id: vehicle-id, owner: tx-sender} 
                    (- sender-shares share-amount))
                (map-set ownership-shares {vehicle-id: vehicle-id, owner: recipient}
                    (+ (default-to u0 (map-get? ownership-shares {vehicle-id: vehicle-id, owner: recipient}))
                       share-amount))
                (ok true)
            )
            err-not-authorized
        )
    )
)

;; Check out vehicle
(define-public (check-out-vehicle (vehicle-id principal))
    (let
        ((vehicle (map-get? vehicles vehicle-id)))
        (match vehicle
            vehicle-data
            (if (and (get available vehicle-data)
                     (> (default-to u0 (map-get? ownership-shares {vehicle-id: vehicle-id, owner: tx-sender})) u0))
                (begin
                    (map-set vehicles vehicle-id
                        (merge vehicle-data {
                            available: false,
                            current-user: (some tx-sender)
                        }))
                    (ok true)
                )
                err-not-available
            )
            err-vehicle-not-found
        )
    )
)

;; Return vehicle
(define-public (return-vehicle (vehicle-id principal))
    (let
        ((vehicle (map-get? vehicles vehicle-id)))
        (match vehicle
            vehicle-data
            (if (is-eq (some tx-sender) (get current-user vehicle-data))
                (begin
                    (map-set vehicles vehicle-id
                        (merge vehicle-data {
                            available: true,
                            current-user: none
                        }))
                    (ok true)
                )
                err-not-authorized
            )
            err-vehicle-not-found
        )
    )
)

;; Read only functions
(define-read-only (get-vehicle-info (vehicle-id principal))
    (ok (map-get? vehicles vehicle-id))
)

(define-read-only (get-shares (vehicle-id principal) (owner principal))
    (ok (map-get? ownership-shares {vehicle-id: vehicle-id, owner: owner}))
)
