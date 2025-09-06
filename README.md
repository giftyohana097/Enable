# Enable Smart Contract 🌟

## About 💡
Enable is a comprehensive blockchain-based ecosystem for managing disability access tokens, providing priority services, equipment lending, and verification for persons with disabilities. The system includes NFT-based access tokens, service booking, accessibility equipment sharing, and robust admin controls.

## 🎯 Core Features

### 🪪 **Identity & Access Management**
- NFT-based disability access tokens with unique IDs
- Priority level system (1-5) for service prioritization
- Expiration management with block-height validation
- Multiple disability type support (mobility, visual, hearing, cognitive, etc.)
- Status tracking (active, inactive, suspended, pending, expired)
- Notes field for additional verification details

### 🏪 **Service Provider Ecosystem**
- Service provider registration and management
- Service booking system with time-based scheduling
- Provider statistics and ratings
- Revenue tracking and completion metrics
- Special requirements handling

### 🛠️ **Equipment Lending Platform**
- Accessibility equipment registration by community members
- Loan management with start/end dates and costs
- Equipment condition tracking
- Deposit and daily rate system
- Borrower reputation system
- Late return tracking

### 🔐 **Security & Admin Controls**
- Multi-admin support with role-based permissions
- Emergency pause functionality
- Input validation for all user data
- Non-transferable tokens
- Comprehensive error handling

## 📋 Smart Contract Functions

### 👨‍💼 Administrator Functions

#### User Management
```clarity
(register-user 
    (user principal)
    (disability-type (string-ascii 64))  ;; "mobility", "visual", "hearing", etc.
    (status (string-ascii 16))           ;; "active", "inactive", "suspended", etc.
    (expiration uint)                    ;; Block height expiration
    (priority-level uint)                ;; 1-5 priority level
    (notes (string-ascii 256))          ;; Additional verification notes
)
```

```clarity
(update-user-status (user principal) (new-status (string-ascii 16)))
(update-expiration (user principal) (new-expiration uint))
```

#### Admin Management
```clarity
(add-admin (new-admin principal))        ;; Owner only
(remove-admin (admin principal))         ;; Owner only
(emergency-pause)                        ;; Any admin
(emergency-unpause)                      ;; Owner only
```

### 🏪 Service Provider Functions

```clarity
(register-service-provider 
    (name (string-ascii 64))
    (services (string-ascii 256))       ;; Description of services offered
)

(update-service-provider-status (active bool))
```

### 📅 Service Booking Functions

```clarity
(create-service-booking
    (provider principal)
    (service-type (string-ascii 64))
    (start-time uint)                   ;; Future block height
    (duration uint)                     ;; Duration in blocks
    (cost uint)                         ;; Service cost
    (special-requirements (string-ascii 256))
)

(update-booking-status (booking-id uint) (new-status (string-ascii 16)))
(cancel-booking (booking-id uint))      ;; User or provider can cancel

(rate-service 
    (booking-id uint) 
    (rating uint)                       ;; 1-5 stars
    (review (string-ascii 256))
)
```

### 🛠️ Equipment Management Functions

#### Equipment Registration
```clarity
(register-equipment
    (name (string-ascii 64))
    (category (string-ascii 32))        ;; "mobility", "visual-aid", etc.
    (description (string-ascii 256))
    (condition (string-ascii 16))       ;; "excellent", "good", "fair", etc.
    (daily-rate uint)                   ;; Daily rental cost
    (deposit-required uint)             ;; Security deposit
    (maintenance-notes (string-ascii 256))
)

(update-equipment-availability (equipment-id uint) (available bool))
```

#### Equipment Lending
```clarity
(create-equipment-loan
    (equipment-id uint)
    (start-date uint)                   ;; Future block height
    (end-date uint)                     ;; End block height
)

(approve-loan (loan-id uint))           ;; Equipment owner approves

(return-equipment 
    (loan-id uint) 
    (return-condition (string-ascii 16)) ;; Condition upon return
)

(rate-equipment 
    (loan-id uint) 
    (rating uint)                       ;; 1-5 stars
    (review (string-ascii 256))
)

(rate-borrower-care (loan-id uint) (care-rating uint)) ;; Owner rates borrower
```

### 📊 Read-Only Query Functions

#### User Information
```clarity
(get-user-details (user principal))
(is-active-user (user principal))
(get-priority-level (user principal))
```

#### Service Provider Information
```clarity
(get-service-provider (provider principal))
(get-provider-statistics (provider principal))
(calculate-provider-average-rating (provider principal))
(get-provider-bookings (provider principal))
```

#### Booking Information
```clarity
(get-booking-details (booking-id uint))
(get-user-bookings (user principal))
(get-booking-status (booking-id uint))
(is-booking-active (booking-id uint))
(get-service-rating (booking-id uint))
```

#### Equipment Information
```clarity
(get-equipment-details (equipment-id uint))
(get-loan-details (loan-id uint))
(get-owner-equipment (owner principal))
(get-borrower-loans (borrower principal))
(is-equipment-available (equipment-id uint))
(calculate-loan-cost (equipment-id uint) (days uint))
(get-equipment-rating (loan-id uint))
(get-borrower-reputation (borrower principal))
```

#### Admin Functions
```clarity
(is-admin (user principal))
(is-contract-paused)
```

## 🚀 Usage Guide

### 1. Contract Deployment
```bash
# Clone the repository
git clone <repository-url>
cd Enable

# Install dependencies
npm install

# Check contract syntax
clarinet check

# Run tests
npm test

# Deploy to local devnet
clarinet deploy --devnet
```

### 2. User Registration Flow
1. **Admin registers user**: Contract owner calls `register-user` with disability details
2. **User receives NFT**: Non-transferable access token is minted
3. **Service access**: User can book services and borrow equipment
4. **Priority handling**: Higher priority users get preferential treatment

### 3. Service Provider Flow
1. **Registration**: Provider calls `register-service-provider`
2. **Service listings**: Providers can be discovered by users
3. **Booking management**: Accept/update booking statuses
4. **Rating system**: Build reputation through service delivery

### 4. Equipment Sharing Flow
1. **Equipment listing**: Community members register available equipment
2. **Loan requests**: Users create loan requests for needed equipment
3. **Approval process**: Equipment owners approve/deny requests
4. **Return tracking**: System tracks on-time returns and equipment condition
5. **Reputation building**: Both borrowers and lenders build community reputation

## 🔒 Security Features

### Access Controls
- **Owner-only functions**: User registration, admin management, emergency unpause
- **Admin functions**: Emergency pause capability for system protection
- **User-specific access**: Users can only modify their own bookings and loans
- **Provider controls**: Only service providers can update their offerings

### Input Validation
- **Disability types**: Limited to predefined valid types
- **Status values**: Controlled vocabulary for all status fields
- **Equipment categories**: Standardized category system
- **Numeric constraints**: Rate limits, duration limits, cost validation
- **Time validation**: Future dates for bookings and loans

### Emergency Controls
- **Pause functionality**: Admins can pause all operations during emergencies
- **Multi-admin support**: Distributed emergency response capability
- **Owner override**: Contract owner can unpause and manage admins

### Data Integrity
- **Non-transferable tokens**: Prevents token trading/speculation
- **Expiration enforcement**: Automatic status validation
- **Reputation system**: Community-driven quality control
- **Comprehensive logging**: All actions tracked with timestamps

## 🧪 Testing

The contract includes comprehensive test coverage:

```bash
# Run full test suite
npm test

# Check test coverage includes:
# - User registration and management
# - Service provider functionality
# - Booking lifecycle
# - Equipment lending process
# - Admin controls
# - Emergency pause functionality
# - Input validation
# - Error handling
```

## 📈 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | err-owner-only | Only contract owner can perform this action |
| u101 | err-already-registered | User is already registered |
| u102 | err-not-registered | User is not registered |
| u103 | err-invalid-status | Invalid status value |
| u104 | err-transfer-disabled | Token transfers are disabled |
| u105 | err-invalid-booking | Invalid booking parameters |
| u121 | err-contract-paused | Contract is currently paused |
| u122 | err-admin-only | Only admins can perform this action |
| u125 | err-invalid-disability-type | Invalid disability type |
| u126 | err-invalid-service-type | Invalid service type |
| u127 | err-invalid-equipment-category | Invalid equipment category |
| u128 | err-invalid-priority-level | Priority level must be 1-5 |
| u129 | err-invalid-cost | Cost exceeds maximum allowed |
| u130 | err-invalid-duration | Duration exceeds maximum allowed |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

MIT License - See LICENSE file for details.

## 🛠️ Development

**Built with:**
- Clarity Smart Contract Language
- Clarinet Development Environment
- Vitest Testing Framework
- Stacks Blockchain

**Requirements:**
- Node.js 16+
- Clarinet CLI
- TypeScript (for tests)


