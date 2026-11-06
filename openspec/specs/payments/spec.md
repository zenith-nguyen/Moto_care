# Payments Specification

## Purpose
Covers money coming in from customers and how it is recorded: the prepayment opened for an order's estimated price, the bank-transfer instructions and QR the customer pays against, the authenticated confirmation that credits that transfer, the separate demo settlement path used outside production, and the single adjustment that settles the difference once a final price is approved. It does not own the order status machine or the final-price negotiation, and it does not cover paying mechanics, which belongs to the provider wallet.

## Requirements

### Requirement: Every order opens a pending prepayment for its estimated price
The system SHALL open exactly one pending prepayment for an order at creation, for the order's estimated price, and SHALL hold all monetary amounts as exact decimal values with two decimal places that are only ever added, subtracted or compared as integer minor currency units, never as floating-point numbers.

#### Scenario: An order is created
- **WHEN** an order is created from a price quote
- **THEN** a prepayment for the estimated price is recorded in pending state and no money has been received yet

#### Scenario: A monetary value is not a valid two-decimal amount
- **WHEN** an amount that is not a non-negative value with at most two decimal places is supplied
- **THEN** it is rejected rather than being coerced or rounded silently

### Requirement: An unpaid order yields bank-transfer instructions carrying a unique payment code
The system SHALL return, at `GET /payments/orders/:orderId/instructions`, the configured receiving bank, account number and account holder, the exact amount, a payment code unique to that prepayment, the transfer memo to use and a QR image link encoding all of them. The payment code SHALL be a configured prefix followed by the prepayment's own identifier.

#### Scenario: Customer opens the transfer screen for an unpaid order
- **WHEN** the customer of the order requests instructions while the prepayment is pending
- **THEN** the memo, the unique payment code, the exact amount and a QR link are returned together with the mode and whether it is simulation only

### Requirement: Instructions are issued only to the paying customer while payment is still due
The system SHALL issue transfer instructions only to the customer who owns the order, only while the prepayment is pending and the order still awaits prepayment, and only for an amount that is a whole currency unit.

#### Scenario: Instructions are requested by someone else or for a settled order
- **WHEN** the caller is not the customer of the order, or the order no longer awaits prepayment
- **THEN** the request is rejected with 404 or 409 and no instructions are issued

#### Scenario: The amount is not a whole currency unit
- **WHEN** the prepayment amount carries a fractional currency unit
- **THEN** instructions are refused with 409 rather than a QR that cannot be paid exactly

### Requirement: Transaction notifications are accepted only when authentic and fresh
The system SHALL require every incoming transaction notification to carry a timestamp and a signature, SHALL recompute the signature as a keyed hash over the timestamp and the exact received body using the configured secret and compare it in constant time, SHALL reject a timestamp that differs from the current time by more than the configured maximum age, and SHALL reject with 401 whenever either check fails or a required header is absent.

#### Scenario: A correctly signed and recent notification arrives
- **WHEN** the signature matches the body and timestamp and the timestamp is within the configured freshness window
- **THEN** the notification is processed and acknowledged with 200

#### Scenario: The signature does not match or a header is missing
- **WHEN** the signature, timestamp or body is absent, malformed or does not verify
- **THEN** the request is rejected with 401 and nothing is recorded

#### Scenario: The notification is replayed after the freshness window
- **WHEN** the timestamp is older or further ahead than the configured maximum age
- **THEN** the request is rejected with 401 as expired

### Requirement: A bank transaction is credited at most once and only when it matches the open prepayment
The system SHALL identify each incoming transaction by its external transaction identifier, SHALL serialise concurrent deliveries of the same identifier, and SHALL bind an applied transaction to the prepayment it paid so that no second prepayment can claim it. Every delivery SHALL be recorded once with the outcome that was decided.

#### Scenario: A matching transfer arrives
- **WHEN** an authenticated incoming transaction matches the configured account, a known payment code, the exact pending amount and an order still awaiting prepayment
- **THEN** the prepayment is marked paid with the time and the bank transaction identifier, and the order is released for matching in the same transaction

#### Scenario: The same bank transaction is delivered again
- **WHEN** a transaction identifier that has already been recorded is delivered again with the identical body
- **THEN** nothing changes and the delivery is acknowledged, so no amount is credited twice
- **AND** a delivery reusing that identifier with a different body is rejected with 409

#### Scenario: The transfer does not match
- **WHEN** the account, the direction, the payment code, the amount or the current prepayment or order state does not match
- **THEN** no payment state changes and the delivery is recorded with the reason it was ignored

### Requirement: Applying a transaction requires it to match the open prepayment
The system SHALL apply an incoming transaction only when the receiving account matches configuration, the direction is incoming, the memo carries a known payment code, the amount equals the prepayment amount to the minor unit, the prepayment is still pending and the order still awaits prepayment.

#### Scenario: The transfer does not match the prepayment
- **WHEN** the receiving account, direction, payment code, amount or payment state does not match
- **THEN** the transaction is recorded as not applied and no payment or order state changes

### Requirement: Live money handling is off by default and gated behind explicit configuration
The system SHALL refuse all bank-transfer operations unless they are enabled in configuration, SHALL default to the simulation mode, and SHALL state the active mode and whether it is simulation only on every set of instructions it issues.

#### Scenario: Bank transfers are not enabled
- **WHEN** any bank-transfer operation is called while the integration is disabled or the mode is unsupported
- **THEN** the request is rejected with 403

#### Scenario: Live mode is requested without its guardrails
- **WHEN** configuration selects live mode outside production, with the demo path still enabled, without a public base address or without the explicit live acknowledgement
- **THEN** startup validation fails and the service does not run

#### Scenario: Simulation mode issues instructions
- **WHEN** instructions are issued in the default simulation mode
- **THEN** they are marked simulation only, and the receiving account must be a provider-issued virtual account

### Requirement: Live mode requires explicit production guardrails
The system SHALL permit the live mode only when the service runs in production, the demo path is switched off, a public base address is configured and an explicit live acknowledgement value is present. Configuration that enables live mode without those guardrails SHALL fail startup validation.

#### Scenario: Live mode is configured without its guardrails
- **WHEN** live mode is enabled while any of those conditions is unmet
- **THEN** startup validation fails and the service does not start

### Requirement: The demo settlement path is separate and never available in production
The system SHALL expose demo-only endpoints that simulate prepayment, refund and adjustment settlement without any bank transfer, SHALL refuse them with 403 whenever the service runs in production or the demo flag is off, SHALL mark every record they settle as demo, and SHALL make each of them idempotent. A simulated prepayment SHALL be accepted only for the exact estimated price.

#### Scenario: A customer simulates their prepayment outside production
- **WHEN** the customer of an order awaiting prepayment posts to the demo confirm endpoint and the pending amount equals the estimated price
- **THEN** the prepayment is marked paid as a demo payment and the order is released for matching

#### Scenario: The demo path is called in production or with demo mode off
- **WHEN** any demo payment endpoint is called while the service runs in production or the demo flag is not set
- **THEN** the request is rejected with 403

#### Scenario: A demo settlement is repeated
- **WHEN** the same demo confirmation, refund or adjustment settlement is submitted again after it succeeded
- **THEN** the existing state is returned unchanged and no second settlement is recorded

### Requirement: An approved final price settles through one adjustment
The system SHALL require the prepayment to be paid before a final price may be approved, SHALL record at most one adjustment per order holding the difference, as a charge when the final price exceeds the prepayment and as a refund when it is lower, SHALL record no adjustment when the amounts are equal, and SHALL require that adjustment to be settled and to reconcile exactly with the final price before the earnings of the order may be settled.

#### Scenario: The approved final price is higher than the prepayment
- **WHEN** a final price above the paid prepayment is approved
- **THEN** a pending charge adjustment for the difference is recorded and the extra cost is reported

#### Scenario: The approved final price is lower than the prepayment
- **WHEN** a final price below the paid prepayment is approved
- **THEN** a pending refund adjustment for the difference is recorded and the discount is reported

#### Scenario: Earnings are settled against unreconciled records
- **WHEN** settlement is attempted while the prepayment is unpaid, the adjustment is still pending, or the final price does not equal the prepayment adjusted by that adjustment
- **THEN** the settlement is rejected with 409 and nothing is credited
