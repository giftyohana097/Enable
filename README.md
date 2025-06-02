# Enable Smart Contract 🌟

## About 💡
Enable is a blockchain-based solution for managing disability access tokens, providing priority services and verification for persons with disabilities.

## Features ✨
- NFT-based disability access tokens
- Priority level system
- Expiration management
- Service provider registration
- Verification authority controls
- Non-transferable tokens

## Smart Contract Functions 🔧

### For Administrators
- `register-user`: Register new users with disability access tokens
- `update-user-status`: Update user verification status
- `update-expiration`: Modify token expiration dates

### For Service Providers
- `register-service-provider`: Register as a service provider
- `update-service-provider-status`: Toggle service provider active status

### Read-Only Functions
- `get-user-details`: Retrieve user registration details
- `get-service-provider`: Get service provider information
- `is-active-user`: Check if a user's token is active
- `get-priority-level`: Get user's priority level

## Usage 📝
1. Deploy the contract using Clarinet
2. Register users through the administrator account
3. Service providers can register themselves
4. Query user status and priority levels for service provision

## Security 🔒
- Only contract owner can register users and update their status
- Tokens are non-transferable
- Built-in expiration system
- Priority levels are immutable once set

## Development 🛠
Built with Clarity and Clarinet for the Stacks blockchain.
```


