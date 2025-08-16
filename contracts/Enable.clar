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
(define-constant err-equipment-not-found (err u113))
(define-constant err-equipment-not-available (err u114))
(define-constant err-loan-not-found (err u115))
(define-constant err-unauthorized-equipment (err u116))
(define-constant err-equipment-already-loaned (err u117))
(define-constant err-loan-already-returned (err u118))
(define-constant err-invalid-condition (err u119))
(define-constant err-cannot-rate-own-equipment (err u120))

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

(define-data-var last-equipment-id uint u0)
(define-data-var last-loan-id uint u0)

(define-map accessibility-equipment
    uint
    {
        owner: principal,
        name: (string-ascii 64),
        category: (string-ascii 32),
        description: (string-ascii 256),
        condition: (string-ascii 16),
        daily-rate: uint,
        deposit-required: uint,
        available: bool,
        total-loans: uint,
        maintenance-notes: (string-ascii 256)
    }
)

(define-map equipment-loans
    uint
    {
        equipment-id: uint,
        borrower: principal,
        owner: principal,
        start-date: uint,
        end-date: uint,
        actual-return-date: (optional uint),
        status: (string-ascii 16),
        total-cost: uint,
        deposit-paid: uint,
        condition-at-loan: (string-ascii 16),
        condition-at-return: (optional (string-ascii 16))
    }
)

(define-map owner-equipment
    principal
    (list 20 uint)
)

(define-map borrower-loans
    principal
    (list 30 uint)
)

(define-map equipment-ratings
    uint
    {
        loan-id: uint,
        equipment-id: uint,
        borrower: principal,
        owner: principal,
        rating: uint,
        review: (string-ascii 256),
        timestamp: uint
    }
)

(define-map borrower-reputation
    principal
    {
        total-loans: uint,
        successful-returns: uint,
        late-returns: uint,
        damage-incidents: uint,
        average-care-rating: uint,
        total-care-ratings: uint
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

(define-public (register-equipment
    (name (string-ascii 64))
    (category (string-ascii 32))
    (description (string-ascii 256))
    (condition (string-ascii 16))
    (daily-rate uint)
    (deposit-required uint)
    (maintenance-notes (string-ascii 256))
)
    (let
        (
            (new-equipment-id (+ (var-get last-equipment-id) u1))
            (current-owner-equipment (default-to (list) (map-get? owner-equipment tx-sender)))
            (user-registration (unwrap! (map-get? registrations tx-sender) err-not-registered))
        )
        (asserts! (and (is-eq (get status user-registration) "active") 
                      (> (get expiration user-registration) stacks-block-height)) err-invalid-status)
        (asserts! (> daily-rate u0) err-invalid-booking)
        (asserts! (> deposit-required u0) err-invalid-booking)
        (var-set last-equipment-id new-equipment-id)
        (map-set accessibility-equipment new-equipment-id
            {
                owner: tx-sender,
                name: name,
                category: category,
                description: description,
                condition: condition,
                daily-rate: daily-rate,
                deposit-required: deposit-required,
                available: true,
                total-loans: u0,
                maintenance-notes: maintenance-notes
            }
        )
        (ok (map-set owner-equipment tx-sender 
            (unwrap! (as-max-len? (append current-owner-equipment new-equipment-id) u20) err-invalid-booking)
        ))
    )
)

(define-public (update-equipment-availability
    (equipment-id uint)
    (available bool)
)
    (let
        (
            (equipment (unwrap! (map-get? accessibility-equipment equipment-id) err-equipment-not-found))
        )
        (asserts! (is-eq tx-sender (get owner equipment)) err-unauthorized-equipment)
        (ok (map-set accessibility-equipment equipment-id
            (merge equipment { available: available })
        ))
    )
)

(define-public (create-equipment-loan
    (equipment-id uint)
    (start-date uint)
    (end-date uint)
)
    (let
        (
            (equipment (unwrap! (map-get? accessibility-equipment equipment-id) err-equipment-not-found))
            (new-loan-id (+ (var-get last-loan-id) u1))
            (loan-duration (- end-date start-date))
            (total-cost (* (get daily-rate equipment) loan-duration))
            (current-borrower-loans (default-to (list) (map-get? borrower-loans tx-sender)))
            (user-registration (unwrap! (map-get? registrations tx-sender) err-not-registered))
        )
        (asserts! (not (is-eq tx-sender (get owner equipment))) err-unauthorized-equipment)
        (asserts! (get available equipment) err-equipment-not-available)
        (asserts! (> start-date stacks-block-height) err-invalid-booking)
        (asserts! (> end-date start-date) err-invalid-booking)
        (asserts! (and (is-eq (get status user-registration) "active") 
                      (> (get expiration user-registration) stacks-block-height)) err-invalid-status)
        (var-set last-loan-id new-loan-id)
        (map-set equipment-loans new-loan-id
            {
                equipment-id: equipment-id,
                borrower: tx-sender,
                owner: (get owner equipment),
                start-date: start-date,
                end-date: end-date,
                actual-return-date: none,
                status: "pending",
                total-cost: total-cost,
                deposit-paid: (get deposit-required equipment),
                condition-at-loan: (get condition equipment),
                condition-at-return: none
            }
        )
        (map-set borrower-loans tx-sender 
            (unwrap! (as-max-len? (append current-borrower-loans new-loan-id) u30) err-invalid-booking)
        )
        (map-set accessibility-equipment equipment-id
            (merge equipment { available: false })
        )
        (let
            (
                (borrower-rep (default-to { total-loans: u0, successful-returns: u0, late-returns: u0, damage-incidents: u0, average-care-rating: u0, total-care-ratings: u0 } 
                             (map-get? borrower-reputation tx-sender)))
            )
            (ok (map-set borrower-reputation tx-sender
                (merge borrower-rep { total-loans: (+ (get total-loans borrower-rep) u1) })
            ))
        )
    )
)

(define-public (approve-loan (loan-id uint))
    (let
        (
            (loan (unwrap! (map-get? equipment-loans loan-id) err-loan-not-found))
        )
        (asserts! (is-eq tx-sender (get owner loan)) err-unauthorized-equipment)
        (asserts! (is-eq (get status loan) "pending") err-invalid-booking)
        (ok (map-set equipment-loans loan-id
            (merge loan { status: "approved" })
        ))
    )
)

(define-public (return-equipment
    (loan-id uint)
    (return-condition (string-ascii 16))
)
    (let
        (
            (loan (unwrap! (map-get? equipment-loans loan-id) err-loan-not-found))
            (equipment (unwrap! (map-get? accessibility-equipment (get equipment-id loan)) err-equipment-not-found))
            (is-late (> stacks-block-height (get end-date loan)))
        )
        (asserts! (is-eq tx-sender (get borrower loan)) err-unauthorized-equipment)
        (asserts! (is-eq (get status loan) "approved") err-invalid-booking)
        (asserts! (is-none (get actual-return-date loan)) err-loan-already-returned)
        (map-set equipment-loans loan-id
            (merge loan { 
                actual-return-date: (some stacks-block-height),
                status: "returned",
                condition-at-return: (some return-condition)
            })
        )
        (map-set accessibility-equipment (get equipment-id loan)
            (merge equipment { 
                available: true,
                condition: return-condition,
                total-loans: (+ (get total-loans equipment) u1)
            })
        )
        (let
            (
                (borrower-rep (default-to { total-loans: u0, successful-returns: u0, late-returns: u0, damage-incidents: u0, average-care-rating: u0, total-care-ratings: u0 } 
                             (map-get? borrower-reputation (get borrower loan))))
            )
            (if is-late
                (map-set borrower-reputation (get borrower loan)
                    (merge borrower-rep { late-returns: (+ (get late-returns borrower-rep) u1) })
                )
                (map-set borrower-reputation (get borrower loan)
                    (merge borrower-rep { successful-returns: (+ (get successful-returns borrower-rep) u1) })
                )
            )
        )
        (ok true)
    )
)

(define-public (rate-equipment
    (loan-id uint)
    (rating uint)
    (review (string-ascii 256))
)
    (let
        (
            (loan (unwrap! (map-get? equipment-loans loan-id) err-loan-not-found))
        )
        (asserts! (is-eq tx-sender (get borrower loan)) err-unauthorized-equipment)
        (asserts! (is-eq (get status loan) "returned") err-invalid-booking)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (asserts! (not (is-eq tx-sender (get owner loan))) err-cannot-rate-own-equipment)
        (ok (map-set equipment-ratings loan-id
            {
                loan-id: loan-id,
                equipment-id: (get equipment-id loan),
                borrower: tx-sender,
                owner: (get owner loan),
                rating: rating,
                review: review,
                timestamp: stacks-block-height
            }
        ))
    )
)

(define-public (rate-borrower-care
    (loan-id uint)
    (care-rating uint)
)
    (let
        (
            (loan (unwrap! (map-get? equipment-loans loan-id) err-loan-not-found))
            (borrower-rep (default-to { total-loans: u0, successful-returns: u0, late-returns: u0, damage-incidents: u0, average-care-rating: u0, total-care-ratings: u0 } 
                         (map-get? borrower-reputation (get borrower loan))))
        )
        (asserts! (is-eq tx-sender (get owner loan)) err-unauthorized-equipment)
        (asserts! (is-eq (get status loan) "returned") err-invalid-booking)
        (asserts! (and (>= care-rating u1) (<= care-rating u5)) err-invalid-rating)
        (let
            (
                (new-total-ratings (+ (get total-care-ratings borrower-rep) care-rating))
                (new-rating-count (+ (get total-care-ratings borrower-rep) u1))
            )
            (ok (map-set borrower-reputation (get borrower loan)
                (merge borrower-rep { 
                    average-care-rating: (/ new-total-ratings new-rating-count),
                    total-care-ratings: new-rating-count
                })
            ))
        )
    )
)

(define-read-only (get-equipment-details (equipment-id uint))
    (ok (unwrap! (map-get? accessibility-equipment equipment-id) err-equipment-not-found))
)

(define-read-only (get-loan-details (loan-id uint))
    (ok (unwrap! (map-get? equipment-loans loan-id) err-loan-not-found))
)

(define-read-only (get-owner-equipment (owner principal))
    (ok (default-to (list) (map-get? owner-equipment owner)))
)

(define-read-only (get-borrower-loans (borrower principal))
    (ok (default-to (list) (map-get? borrower-loans borrower)))
)

(define-read-only (get-equipment-rating (loan-id uint))
    (map-get? equipment-ratings loan-id)
)

(define-read-only (get-borrower-reputation (borrower principal))
    (ok (default-to { total-loans: u0, successful-returns: u0, late-returns: u0, damage-incidents: u0, average-care-rating: u0, total-care-ratings: u0 } 
       (map-get? borrower-reputation borrower)))
)

(define-read-only (is-equipment-available (equipment-id uint))
    (match (map-get? accessibility-equipment equipment-id)
        equipment (ok (get available equipment))
        err-equipment-not-found
    )
)

(define-read-only (calculate-loan-cost 
    (equipment-id uint) 
    (days uint)
)
    (match (map-get? accessibility-equipment equipment-id)
        equipment (ok (* (get daily-rate equipment) days))
        err-equipment-not-found
    )
)


