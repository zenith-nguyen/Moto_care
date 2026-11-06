# Authentication Specification

## Purpose
Covers how people obtain, keep and lose an authenticated session in the REVO rescue platform: self-service registration, password sign-in with email or phone, bearer token issuance and validation, role-based access to protected endpoints, email password recovery, and the mobile client session lifecycle. It defines the three account roles (customer, provider, admin) and the account states that block access. It does not cover what each role may do inside the rescue, payment or admin capabilities beyond the role check itself.

## Requirements

### Requirement: Self-service registration
The system SHALL allow a visitor to create a customer or provider account through POST /auth/register with a display name, a password, and at least one of an email address or a phone number, and SHALL reject any attempt to self-register an administrator account.

#### Scenario: Customer registers with an email address
- **WHEN** a visitor posts a name, a password of at least 8 characters and an email address, with no role or the customer role
- **THEN** an active customer account is created
- **AND** the response carries an access token and the new account's identity, role and status

#### Scenario: Provider registers and waits for approval
- **WHEN** a visitor registers with the provider role
- **THEN** the account is created in a pending-approval state together with its provider record
- **AND** the response still carries an access token and reports the pending-approval status

#### Scenario: Registration data is unusable
- **WHEN** the request supplies neither an email address nor a phone number, or asks for the administrator role
- **THEN** the request is rejected with 400
- **AND** when the email address or phone number already belongs to another account the request is rejected with 409

### Requirement: Password sign-in with email or phone
The system SHALL authenticate a POST /auth/login request by matching the submitted identity against a registered email address (case-insensitive) or phone number and verifying the password, returning an access token and the account summary on success.

#### Scenario: Valid credentials
- **WHEN** the identity matches an account and the password verifies
- **THEN** the response is 200 with an access token and the account's identity, role and status

#### Scenario: Unknown identity or wrong password
- **WHEN** no account matches the identity, or the password does not verify
- **THEN** the response is 401 with an indistinguishable "invalid credentials" message that does not reveal whether the account exists

#### Scenario: Suspended account
- **WHEN** the credentials are correct but the account is suspended
- **THEN** the response is 401 and no access token is issued

### Requirement: Failed sign-in lockout
The system SHALL count consecutive failed sign-in attempts per account and SHALL temporarily lock the account for 15 minutes after the fifth consecutive failure, clearing the counter and the lock on the next successful sign-in.

#### Scenario: Fifth consecutive failure locks the account
- **WHEN** a fifth consecutive sign-in attempt for the same account fails
- **THEN** the account is locked for 15 minutes
- **AND** further sign-in attempts during the lock return 401 even when the password is correct

#### Scenario: Successful sign-in resets the counter
- **WHEN** an account that has accumulated failures signs in successfully before being locked
- **THEN** the failure counter and any lock are cleared

### Requirement: Bearer session tokens
The system SHALL protect every endpoint except the authentication endpoints and other explicitly public endpoints, accepting only a bearer access token that is unexpired and still matches the account's current role, account version and non-suspended status.

#### Scenario: Protected request without a usable token
- **WHEN** a request to a protected endpoint carries no bearer token, an expired token, or a token for a deleted account
- **THEN** the response is 401

#### Scenario: Token no longer matches the account
- **WHEN** a request carries a token whose role or account version differs from the account's current values, or whose account has since been suspended
- **THEN** the response is 401 and the request is not processed

### Requirement: Role-based endpoint access
The system SHALL restrict role-scoped endpoints to accounts whose token role is in the allowed set for that endpoint, and SHALL deny access to authenticated accounts holding any other role.

#### Scenario: Wrong role calls a role-scoped endpoint
- **WHEN** an authenticated account whose role is not allowed for the endpoint calls it
- **THEN** access is denied and the operation does not run

#### Scenario: Endpoint without a role restriction
- **WHEN** an authenticated account calls an endpoint that declares no role restriction
- **THEN** access is granted regardless of role

### Requirement: Password reset code request
The system SHALL accept POST /auth/password/forgot for an email address and SHALL always answer 202 with the same generic message, sending a six-digit code valid for one minute only when the email address belongs to an account and no code was issued for it in the previous minute.

#### Scenario: Registered email address
- **WHEN** the email address belongs to an account and no code was issued for it in the last minute
- **THEN** any earlier unused code for that account is invalidated, a new six-digit code expiring in one minute is sent by email
- **AND** the response is 202 with the generic message

#### Scenario: Unknown email address or repeated request
- **WHEN** the email address belongs to no account, or a code was already issued for it less than a minute ago
- **THEN** no email is sent and the response is still 202 with the same generic message

#### Scenario: Email delivery fails
- **WHEN** the code cannot be delivered, including when email sending is switched off in the environment
- **THEN** the newly created code is invalidated so it can never be used
- **AND** the response is still 202 with the generic message

### Requirement: Password reset completion
The system SHALL accept POST /auth/password/reset with the email address, the six-digit code and a new password of at least 8 characters, and SHALL replace the password and invalidate every previously issued access token for that account when the code is the account's latest unused, unexpired code.

#### Scenario: Correct code
- **WHEN** the submitted code matches the account's latest unused code and it has not expired
- **THEN** the password is replaced, every previously issued access token for that account stops being accepted, any sign-in lock is cleared
- **AND** the response is 200 telling the person to sign in again

#### Scenario: Wrong, expired or already used code
- **WHEN** the code does not match, has expired, has already been used, or the email address belongs to no account
- **THEN** the response is 400 with the same "invalid or expired code" message and the password is unchanged

#### Scenario: Too many wrong attempts
- **WHEN** a fifth wrong code is submitted for the same reset code
- **THEN** that code is marked used and can no longer be redeemed even if the correct value is submitted afterwards

### Requirement: Mobile session lifecycle
The mobile apps SHALL keep the access token in the device's secure storage, restore the session on launch by re-reading the signed-in account, route the signed-in account to the area of its role, and discard the stored token whenever the session becomes invalid.

#### Scenario: App restart with a stored token
- **WHEN** the app starts and a token is present in secure storage
- **THEN** the app re-reads the signed-in account and, if its role is served by this app build, restores the session and lands on that role's area: customer, provider or admin
- **AND** when no token is stored the app lands on the welcome or sign-in screen

#### Scenario: Role not served by this app build
- **WHEN** a sign-in or a restored session returns a role that the running app build does not serve, such as a provider account in the customer app
- **THEN** the stored token is discarded, the person stays signed out and is told to use the app for that role

#### Scenario: Server rejects the token
- **WHEN** any request returns 401, or the person signs out
- **THEN** the stored token is deleted and the app returns to the signed-out state, guarded routes becoming unreachable immediately
