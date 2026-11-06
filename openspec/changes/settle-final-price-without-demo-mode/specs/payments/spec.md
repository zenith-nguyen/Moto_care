## ADDED Requirements

### Requirement: A charge adjustment is payable by bank transfer
The system SHALL issue transfer instructions for an open charge adjustment,
carrying a payment code unique to that adjustment, and SHALL settle it on a
verified transaction notification under the same guards that apply to a
prepayment.

#### Scenario: Customer pays an approved higher final price
- **WHEN** the customer approved a final price above the prepayment and transfers the difference with the payment code in the memo
- **THEN** the adjustment is settled, the order moves from `AWAITING_PAYMENT` to `PAID`
- **AND** completing the order credits the mechanic exactly once

#### Scenario: One payable at a time
- **WHEN** instructions are requested for an order whose prepayment is still unpaid
- **THEN** no adjustment instructions are issued, so a transfer cannot be ambiguous between the two amounts

#### Scenario: A bank transaction is used once across both payable kinds
- **WHEN** a transaction identifier already applied to a prepayment arrives again against an adjustment
- **THEN** it is refused and no second amount is credited

## MODIFIED Requirements

### Requirement: Earnings settle only against fully reconciled payment records
The system SHALL refuse to settle the earnings of an order unless the prepayment is paid for the estimated price, any adjustment recorded for the order is settled, and the final price equals the prepayment adjusted by that adjustment. The system SHALL NOT additionally require that the adjustment was settled by simulation.

#### Scenario: Earnings are settled against unreconciled records
- **WHEN** settlement is attempted while the prepayment is unpaid, the adjustment is still pending, or the final price does not equal the prepayment adjusted by that adjustment
- **THEN** the settlement is rejected with 409 and nothing is credited

#### Scenario: Live-settled adjustment
- **WHEN** an order completes in production whose adjustment was settled by a verified bank transfer
- **THEN** the mechanic is credited exactly once for that order

## REMOVED Requirements

### Requirement: Settling money after a prepayment is paid is possible only by simulation
The dead end this change exists to remove: once an adjustment or a refund can be settled in production, the restriction and its consequences no longer describe the system.
