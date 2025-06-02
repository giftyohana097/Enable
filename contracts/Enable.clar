(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-transfer-disabled (err u104))

(define-non-fungible-token enable-token uint)

(define-map registrations
    principal
    {
        token-id: uint,
        disability-type: (string-ascii 64),
        status: (string-ascii 16),
        expiration: uint,
        priority-level: uint,
        verification-authority: principal
    }
)

(define-map service-providers
    principal
    {
        name: (string-ascii 64),
        services: (string-ascii 256),
        active: bool
    }
)

(define-data-var last-token-id uint u0)

(define-public (register-user 
    (disability-type (string-ascii 64))
    (status (string-ascii 16))
    (expiration uint)
    (priority-level uint)
)
    (let
        (
            (new-id (+ (var-get last-token-id) u1))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-none (map-get? registrations tx-sender)) err-already-registered)
        (try! (nft-mint? enable-token new-id tx-sender))
        (var-set last-token-id new-id)
        (ok (map-set registrations
            tx-sender
            {
                token-id: new-id,
                disability-type: disability-type,
                status: status,
                expiration: expiration,
                priority-level: priority-level,
                verification-authority: tx-sender
            }
        ))
    )
)

(define-public (update-user-status
    (user principal)
    (new-status (string-ascii 16))
)
    (let
        (
            (current-registration (unwrap! (map-get? registrations user) err-not-registered))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set registrations
            user
            (merge current-registration { status: new-status })
        ))
    )
)

(define-public (update-expiration
    (user principal)
    (new-expiration uint)
)
    (let
        (
            (current-registration (unwrap! (map-get? registrations user) err-not-registered))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set registrations
            user
            (merge current-registration { expiration: new-expiration })
        ))
    )
)

(define-public (register-service-provider 
    (name (string-ascii 64))
    (services (string-ascii 256))
)
    (ok (map-set service-providers
        tx-sender
        {
            name: name,
            services: services,
            active: true
        }
    ))
)

(define-public (update-service-provider-status (active bool))
    (let
        (
            (provider (unwrap! (map-get? service-providers tx-sender) err-not-registered))
        )
        (ok (map-set service-providers
            tx-sender
            (merge provider { active: active })
        ))
    )
)

(define-read-only (get-user-details (user principal))
    (ok (unwrap! (map-get? registrations user) err-not-registered))
)

(define-read-only (get-service-provider (provider principal))
    (ok (unwrap! (map-get? service-providers provider) err-not-registered))
)

(define-read-only (is-active-user (user principal))
    (match (map-get? registrations user)
        registration (ok (and
            (is-eq (get status registration) "active")
            (> (get expiration registration) stacks-block-height)
        ))
        err-not-registered
    )
)

(define-read-only (get-priority-level (user principal))
    (match (map-get? registrations user)
        registration (ok (get priority-level registration))
        err-not-registered
    )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (err err-transfer-disabled)
)