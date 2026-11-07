## ADDED Requirements

### Requirement: Recorded refund settlement
The system SHALL let an administrator record that a refund for a payment in
`REFUND_PENDING` has been transferred, and SHALL perform no outbound transfer of
its own when doing so.

#### Scenario: Administrator records a completed refund
- **WHEN** an administrator settles a payment that is in `REFUND_PENDING`, supplying the bank reference of the transfer they made
- **THEN** the payment becomes `REFUNDED` with that reference and the time of settlement recorded
- **AND** the order attached to it becomes `REFUNDED`

#### Scenario: The same settlement is submitted twice
- **WHEN** a settlement arrives for a payment that is already `REFUNDED` with the same bank reference
- **THEN** the current payment and order state are returned unchanged and nothing is written

#### Scenario: The bank reference belongs to another payment
- **WHEN** the supplied bank reference is already recorded against a different payment
- **THEN** the request is rejected with 409 and no state changes

#### Scenario: The payment is not awaiting a refund
- **WHEN** the payment is in any state other than `REFUND_PENDING` or already `REFUNDED`
- **THEN** the request is rejected with 409

### Requirement: Outstanding refunds are the ones not yet settled
The system SHALL treat the administrator refund queue and the refund
reconciliation figures as covering only payments that are still in
`REFUND_PENDING`, so that a settled refund leaves both.

#### Scenario: Queue after settlement
- **WHEN** a refund has been settled
- **THEN** it no longer appears in the pending refund queue
- **AND** it is no longer counted as an amount still owed to customers
