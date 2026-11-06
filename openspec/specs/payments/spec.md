# Payments Specification

## Purpose
Covers money coming in from customers and how it is recorded: the prepayment opened for an order's estimated price, the bank-transfer instructions and QR the customer pays against, the authenticated confirmation that credits that transfer, the separate demo settlement path used outside production, and the single adjustment that settles the difference once a final price is approved. It does not own the order status machine or the final-price negotiation, and it does not cover paying mechanics, which belongs to the provider wallet.

## Requirements

### Requirement: Every order opens a pending prepayment for its estimated price
The system SHALL open one pending prepayment for an order at creation, for the order's estimated price. Uniqueness is not enforced, so the system SHALL treat the earliest prepayment of an order as the authoritative one and SHALL flag an order carrying more than one for reconciliation review.

#### Scenario: An order is created
- **WHEN** an order is created from a price quote
- **THEN** a prepayment for the estimated price is recorded in pending state and no money has been received yet

#### Scenario: An order carries more than one prepayment
- **WHEN** more than one prepayment exists for an order
- **THEN** the earliest one is the prepayment read, paid against and settled, and the order is flagged for reconciliation review

### Requirement: Monetary amounts are exact decimals compared as whole minor units
The system SHALL hold every monetary amount as an exact decimal value carrying at most two decimal places, and SHALL only ever add, subtract or compare those amounts as integer minor currency units, never as floating-point numbers. A monetary amount supplied in a request SHALL be a non-negative value written with exactly two decimal places, and SHALL otherwise be rejected with 400 before it reaches any money handling.

#### Scenario: A request carries a malformed amount
- **WHEN** a request body carries a monetary amount that is negative, zero where a positive amount is required, or not written with exactly two decimal places
- **THEN** it is rejected with 400 and no money handling runs

#### Scenario: A stored value is not a valid amount
- **WHEN** a value that is not a non-negative amount of at most two decimal places reaches money handling
- **THEN** the operation fails outright rather than coercing or silently rounding the value

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
The system SHALL identify each incoming transaction by its external transaction identifier, SHALL serialise concurrent deliveries of the same identifier, and SHALL bind an applied transaction to the prepayment it paid so that no second prepayment can claim it. Every delivery SHALL be recorded once with the outcome that was decided, except the provider's authenticated zero-identifier test delivery, which SHALL be acknowledged without being recorded and without changing any state.

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

#### Scenario: The provider sends its zero-identifier test delivery
- **WHEN** an authenticated delivery carries the zero transaction identifier the provider uses to test the endpoint
- **THEN** it is acknowledged with 200, nothing is recorded and no payment or order state changes

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
The system SHALL permit the live mode only when the service runs in production, the demo path is switched off, a public base address is configured and an explicit live acknowledgement value is present. Configuration that enables live mode without those guardrails SHALL fail startup validation, and independently of that every bank-transfer operation SHALL be refused with 403 at request time while live mode is selected outside production.

#### Scenario: Live mode is configured without its guardrails
- **WHEN** live mode is enabled while any of those conditions is unmet
- **THEN** startup validation fails and the service does not start

#### Scenario: Live mode is somehow active outside production
- **WHEN** a bank-transfer operation is called while live mode is selected and the service is not running in production
- **THEN** the request is refused with 403 before any payment state is read or changed

### Requirement: The demo settlement path is separate and never available in production
The system SHALL expose demo-only endpoints that simulate prepayment, refund and adjustment settlement without any bank transfer, SHALL refuse them with 403 whenever the service runs in production or the demo flag is off, SHALL mark every record they settle as demo, and SHALL make each of them idempotent. A simulated prepayment SHALL be accepted only for the exact estimated price. The customer of the order SHALL simulate payments and an admin SHALL simulate refunds.

#### Scenario: A customer simulates their prepayment outside production
- **WHEN** the customer of an order awaiting prepayment posts to the demo confirm endpoint and the pending amount equals the estimated price
- **THEN** the prepayment is marked paid as a demo payment and the order is released for matching

#### Scenario: The demo path is called in production or with demo mode off
- **WHEN** any demo payment endpoint is called while the service runs in production or the demo flag is not set
- **THEN** the request is rejected with 403

#### Scenario: A demo settlement is repeated
- **WHEN** the same demo confirmation, refund or adjustment settlement is submitted again after it succeeded
- **THEN** the existing state is returned unchanged and no second settlement is recorded

#### Scenario: The wrong actor calls a demo endpoint
- **WHEN** an admin simulates a payment or an adjustment charge, or anyone other than an admin simulates a refund
- **THEN** the request is rejected with 403

### Requirement: An approved final price settles through one adjustment
The system SHALL require the prepayment to be paid before a final price may be approved, SHALL record at most one adjustment per order holding the difference, as a charge when the final price exceeds the prepayment and as a refund when it is lower, and SHALL record no adjustment when the amounts are equal.

#### Scenario: The approved final price is higher than the prepayment
- **WHEN** a final price above the paid prepayment is approved
- **THEN** a pending charge adjustment for the difference is recorded and the extra cost is reported

#### Scenario: The approved final price is lower than the prepayment
- **WHEN** a final price below the paid prepayment is approved
- **THEN** a pending refund adjustment for the difference is recorded and the discount is reported

### Requirement: Earnings settle only against fully reconciled payment records
The system SHALL refuse to settle the earnings of an order unless the prepayment is paid for the estimated price, any adjustment recorded for the order is settled, and the final price equals the prepayment adjusted by that adjustment.

#### Scenario: Earnings are settled against unreconciled records
- **WHEN** settlement is attempted while the prepayment is unpaid, the adjustment is still pending, or the final price does not equal the prepayment adjusted by that adjustment
- **THEN** the settlement is rejected with 409 and nothing is credited

### Requirement: Settling money after a prepayment is paid is possible only by simulation
The system SHALL accept an adjustment as settled, and a paid prepayment as refunded, only when it was cleared through the demo settlement path, which is refused in production. Consequently in production a prepayment awaiting refund SHALL stay unrefunded, and an order whose approved final price differs from its prepayment SHALL stay uncompletable, until a live settlement path exists.

#### Scenario: Earnings are settled against an adjustment that was not simulated
- **WHEN** the earnings of an order are settled while its adjustment was not cleared through the demo settlement path
- **THEN** the settlement is rejected with 409 as an unsettled adjustment and nothing is credited

#### Scenario: A prepayment paid by bank transfer awaits a refund
- **WHEN** a refund is attempted for a prepayment that was not paid through the demo path
- **THEN** the refund is rejected with 409 and the prepayment stays awaiting refund
