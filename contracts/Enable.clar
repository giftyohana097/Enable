(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-transfer-disabled (err u104))
(define-constant err-invalid-booking (err u105))
(define-constant err-booking-not-found (err u106))
(define-constant err-unauthorized-booking (err u107))
(define-constant err-service-unavailable (err u108))
(define-constant err-booking-already-completed (err u109))
(define-constant err-booking-already-cancelled (err u110))
(define-constant err-invalid-rating (err u111))
(define-constant err-cannot-rate-own-service (err u112))

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
(define-data-var last-booking-id uint u0)

(define-map service-bookings
    uint
    {
        user: principal,
        provider: principal,
        service-type: (string-ascii 64),
        start-time: uint,
        duration: uint,
        status: (string-ascii 16),
        cost: uint,
        booking-time: uint,
        special-requirements: (string-ascii 256)
    }
)

(define-map user-bookings
    principal
    (list 50 uint)
)

(define-map provider-bookings
    principal
    (list 50 uint)
)

(define-map service-ratings
    uint
    {
        booking-id: uint,
        user: principal,
        provider: principal,
        rating: uint,
        review: (string-ascii 256),
        timestamp: uint
    }
)

(define-map provider-statistics
    principal
    {
        total-bookings: uint,
        completed-bookings: uint,
        total-rating: uint,
        rating-count: uint,
        revenue: uint
    }
)

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

(define-public (create-service-booking
    (provider principal)
    (service-type (string-ascii 64))
    (start-time uint)
    (duration uint)
    (cost uint)
    (special-requirements (string-ascii 256))
)
    (let
        (
            (new-booking-id (+ (var-get last-booking-id) u1))
            (current-user-bookings (default-to (list) (map-get? user-bookings tx-sender)))
            (current-provider-bookings (default-to (list) (map-get? provider-bookings provider)))
            (provider-info (unwrap! (map-get? service-providers provider) err-not-registered))
            (user-registration (unwrap! (map-get? registrations tx-sender) err-not-registered))
        )
        (asserts! (get active provider-info) err-service-unavailable)
        (asserts! (> start-time stacks-block-height) err-invalid-booking)
        (asserts! (> duration u0) err-invalid-booking)
        (asserts! (> cost u0) err-invalid-booking)
        (asserts! (and (is-eq (get status user-registration) "active") 
                      (> (get expiration user-registration) stacks-block-height)) err-invalid-status)
        (var-set last-booking-id new-booking-id)
        (map-set service-bookings new-booking-id
            {
                user: tx-sender,
                provider: provider,
                service-type: service-type,
                start-time: start-time,
                duration: duration,
                status: "pending",
                cost: cost,
                booking-time: stacks-block-height,
                special-requirements: special-requirements
            }
        )
        (map-set user-bookings tx-sender (unwrap! (as-max-len? (append current-user-bookings new-booking-id) u50) err-invalid-booking))
        (map-set provider-bookings provider (unwrap! (as-max-len? (append current-provider-bookings new-booking-id) u50) err-invalid-booking))
        (let
            (
                (current-stats (default-to { total-bookings: u0, completed-bookings: u0, total-rating: u0, rating-count: u0, revenue: u0 } 
                               (map-get? provider-statistics provider)))
            )
            (ok (map-set provider-statistics provider
                (merge current-stats { total-bookings: (+ (get total-bookings current-stats) u1) })
            ))
        )
    )
)

(define-public (update-booking-status
    (booking-id uint)
    (new-status (string-ascii 16))
)
    (let
        (
            (booking (unwrap! (map-get? service-bookings booking-id) err-booking-not-found))
        )
        (asserts! (is-eq tx-sender (get provider booking)) err-unauthorized-booking)
        (asserts! (not (is-eq (get status booking) "completed")) err-booking-already-completed)
        (asserts! (not (is-eq (get status booking) "cancelled")) err-booking-already-cancelled)
        (if (is-eq new-status "completed")
            (let
                (
                    (provider-stats (default-to { total-bookings: u0, completed-bookings: u0, total-rating: u0, rating-count: u0, revenue: u0 } 
                                   (map-get? provider-statistics (get provider booking))))
                )
                (map-set provider-statistics (get provider booking)
                    (merge provider-stats { 
                        completed-bookings: (+ (get completed-bookings provider-stats) u1),
                        revenue: (+ (get revenue provider-stats) (get cost booking))
                    })
                )
            )
            true
        )
        (ok (map-set service-bookings booking-id
            (merge booking { status: new-status })
        ))
    )
)

(define-public (cancel-booking (booking-id uint))
    (let
        (
            (booking (unwrap! (map-get? service-bookings booking-id) err-booking-not-found))
        )
        (asserts! (or (is-eq tx-sender (get user booking)) (is-eq tx-sender (get provider booking))) err-unauthorized-booking)
        (asserts! (not (is-eq (get status booking) "completed")) err-booking-already-completed)
        (asserts! (not (is-eq (get status booking) "cancelled")) err-booking-already-cancelled)
        (ok (map-set service-bookings booking-id
            (merge booking { status: "cancelled" })
        ))
    )
)

(define-public (rate-service
    (booking-id uint)
    (rating uint)
    (review (string-ascii 256))
)
    (let
        (
            (booking (unwrap! (map-get? service-bookings booking-id) err-booking-not-found))
            (provider-stats (default-to { total-bookings: u0, completed-bookings: u0, total-rating: u0, rating-count: u0, revenue: u0 } 
                           (map-get? provider-statistics (get provider booking))))
        )
        (asserts! (is-eq tx-sender (get user booking)) err-unauthorized-booking)
        (asserts! (is-eq (get status booking) "completed") err-invalid-booking)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (asserts! (not (is-eq tx-sender (get provider booking))) err-cannot-rate-own-service)
        (map-set service-ratings booking-id
            {
                booking-id: booking-id,
                user: tx-sender,
                provider: (get provider booking),
                rating: rating,
                review: review,
                timestamp: stacks-block-height
            }
        )
        (ok (map-set provider-statistics (get provider booking)
            (merge provider-stats { 
                total-rating: (+ (get total-rating provider-stats) rating),
                rating-count: (+ (get rating-count provider-stats) u1)
            })
        ))
    )
)

(define-read-only (get-booking-details (booking-id uint))
    (ok (unwrap! (map-get? service-bookings booking-id) err-booking-not-found))
)

(define-read-only (get-user-bookings (user principal))
    (ok (default-to (list) (map-get? user-bookings user)))
)

(define-read-only (get-provider-bookings (provider principal))
    (ok (default-to (list) (map-get? provider-bookings provider)))
)

(define-read-only (get-service-rating (booking-id uint))
    (map-get? service-ratings booking-id)
)

(define-read-only (get-provider-statistics (provider principal))
    (ok (default-to { total-bookings: u0, completed-bookings: u0, total-rating: u0, rating-count: u0, revenue: u0 } 
       (map-get? provider-statistics provider)))
)

(define-read-only (calculate-provider-average-rating (provider principal))
    (let
        (
            (stats (default-to { total-bookings: u0, completed-bookings: u0, total-rating: u0, rating-count: u0, revenue: u0 } 
                   (map-get? provider-statistics provider)))
        )
        (if (> (get rating-count stats) u0)
            (ok (/ (get total-rating stats) (get rating-count stats)))
            (ok u0)
        )
    )
)

(define-read-only (get-booking-status (booking-id uint))
    (match (map-get? service-bookings booking-id)
        booking (ok (get status booking))
        err-booking-not-found
    )
)

(define-read-only (is-booking-active (booking-id uint))
    (match (map-get? service-bookings booking-id)
        booking (ok (and
            (or (is-eq (get status booking) "pending") 
                (is-eq (get status booking) "confirmed"))
            (> (get start-time booking) stacks-block-height)
        ))
        err-booking-not-found
    )
)