# Provider Wallet Specification

## Purpose
Covers the earnings ledger a mechanic accumulates and the deliberately manual route by which money leaves the platform: crediting a completed order to the mechanic's wallet, reserving and releasing available funds for a withdrawal request, the admin decision on that request, and the optional reconciliation of the bank transfer an admin performs by hand. The platform never initiates an outbound transfer itself. It does not cover collecting money from customers, which belongs to payments.

## Requirements

### Requirement: A completed order credits the mechanic exactly once
The system SHALL credit the assigned mechanic's wallet with the order's final price as part of completing that order, SHALL create the wallet on first credit if it does not exist, and SHALL record the credit as one ledger entry naming the order, never more than one credit for the same order.

#### Scenario: A fully settled order is completed
- **WHEN** completion settles the earnings of an order whose payment records reconcile with the final price
- **THEN** the wallet balance rises by the final price and one credit entry referencing that order is recorded

### Requirement: A credit is refused unless the payment records reconcile
The system SHALL refuse to credit a wallet unless the prepayment is paid for the estimated price and the final price reconciles exactly with the prepayment plus or minus its adjustment. An adjustment SHALL count as settled only when it was cleared through the simulated settlement path, so an order whose final price differs from its prepayment cannot be credited in production, where that path is refused.

#### Scenario: The payment records do not reconcile
- **WHEN** the prepayment is not paid for the estimated price, the adjustment is not settled, or the final price does not match the reconciled total
- **THEN** the credit is rejected with 409 and the wallet is left untouched

#### Scenario: The adjustment was not settled by simulation
- **WHEN** a credit is attempted for an order whose adjustment was not cleared through the simulated settlement path
- **THEN** the credit is rejected with 409 as an unsettled adjustment and the wallet is left untouched

### Requirement: A mechanic can read their own balance and recent ledger
The system SHALL expose to the signed-in mechanic, at `GET /wallets/me`, the total balance, the amount currently locked by a pending withdrawal, the available balance as the difference between them, the currency, and at most the twenty most recent ledger entries, newest first, with their type, amount and the order or withdrawal they relate to. The response SHALL state that these funds are a ledger balance and not directly withdrawable real money.

#### Scenario: A mechanic opens their wallet
- **WHEN** a signed-in mechanic with a provider profile calls `GET /wallets/me`
- **THEN** total, locked and available balances are returned with at most the twenty latest ledger entries and the non-withdrawable marker

#### Scenario: The caller is not a mechanic, or is one without a profile
- **WHEN** the signed-in user does not hold the mechanic role
- **THEN** the request is rejected with 403
- **AND** a signed-in mechanic whose provider profile is missing is rejected with 404 instead

### Requirement: A withdrawal request reserves available funds
The system SHALL let a mechanic request a withdrawal of a positive amount that does not exceed their available balance, SHALL move that amount into the locked balance while the request is pending, and SHALL allow only one pending request per mechanic at a time.

#### Scenario: A mechanic requests a withdrawal within the available balance
- **WHEN** a mechanic posts a positive amount no greater than the available balance to `POST /withdrawals`
- **THEN** a pending request is recorded, the amount is locked and the updated balances are returned

#### Scenario: The amount is not a positive two-decimal value
- **WHEN** the requested amount is negative, zero, or not written with exactly two decimal places
- **THEN** the request is rejected with 400 and nothing is reserved

#### Scenario: The amount exceeds the available balance or a request is already pending
- **WHEN** the requested amount exceeds the balance minus what is already locked, or another request of that mechanic is still pending
- **THEN** the request is rejected with 409 and nothing is reserved

### Requirement: An admin decides each withdrawal request idempotently
The system SHALL let an admin approve or reject a pending withdrawal request, SHALL require a reason for a rejection, SHALL on approval release the reservation and debit the balance with one ledger entry naming the request, SHALL on rejection release the reservation without changing the balance, and SHALL record who decided and when. Repeating the same decision SHALL return the existing outcome unchanged, while a different decision on an already resolved request SHALL be refused.

#### Scenario: An admin approves a pending request
- **WHEN** an admin approves a pending withdrawal whose reservation still reconciles with the wallet
- **THEN** the locked amount is released, the balance is debited by that amount and a debit entry referencing the request is recorded

#### Scenario: An admin rejects a pending request
- **WHEN** an admin rejects a pending withdrawal with a reason
- **THEN** the reservation is released, the balance is unchanged and the reason is stored with the decision

#### Scenario: The request was already resolved
- **WHEN** the same decision is submitted again
- **THEN** the existing result is returned unchanged and no balance or reservation changes, the payout record being opened if it is still missing
- **AND** the opposite decision on an already resolved request is rejected with 409

### Requirement: Approval never moves money by itself
The system SHALL perform no outbound bank transfer of any kind. Approving a withdrawal SHALL only open a payout record, idempotently, that awaits a transfer a human performs outside the platform.

#### Scenario: A withdrawal is approved
- **WHEN** an admin approves a withdrawal
- **THEN** a payout record awaiting the manual transfer is created for the approved amount with its own payout code, and no transfer is attempted
- **AND** the response states the manual payout mode

#### Scenario: A mechanic reviews their withdrawals
- **WHEN** a mechanic calls `GET /withdrawals/me`
- **THEN** at most the fifty most recent withdrawals are returned, newest first, each with its payout record, if any, and whether the bank transfer has been confirmed
- **AND** a caller who does not hold the mechanic role is rejected with 403, while a mechanic whose provider profile is missing is rejected with 404

### Requirement: Payout reconciliation is an optional, separately authenticated flow that never confirms by itself
The system SHALL treat reconciliation of outgoing transactions as disabled unless it is explicitly enabled in configuration, answering `503` otherwise, and SHALL authenticate those notifications with their own secret and freshness window, exactly as incoming notifications are authenticated.

#### Scenario: An outgoing transaction matching a payout code arrives
- **WHEN** an authenticated outgoing transaction from the configured source account carries a known payout code
- **THEN** the payout records that transaction reference and observed amount and moves to manual review awaiting an admin
- **AND** an observed amount differing from the expected amount is recorded as a mismatch in the review reason

#### Scenario: A second outgoing transaction claims the same payout code
- **WHEN** a payout already linked to one outgoing transaction receives a different transaction identifier for the same code
- **THEN** the payout is flagged for manual review as having multiple transactions and nothing is confirmed

#### Scenario: The notification does not concern a payout
- **WHEN** the source account, the direction or the payout code does not match, or no such payout exists
- **THEN** no payout state changes and the delivery is recorded with the reason it was ignored

### Requirement: A payout notification never confirms a transfer by itself
The system SHALL never mark a payout as transferred on the strength of a notification alone: a matching outgoing transaction SHALL only attach its reference and observed amount and place the payout in manual review. Each outgoing transaction SHALL be recorded once with its outcome, except the provider's authenticated zero-identifier test delivery, which SHALL be acknowledged without being recorded and without changing any payout.

#### Scenario: The provider sends its zero-identifier test delivery
- **WHEN** an authenticated delivery carries the zero transaction identifier the provider uses to test the endpoint
- **THEN** it is acknowledged with 200, nothing is recorded and no payout changes

#### Scenario: A matching outgoing transaction is observed
- **WHEN** an authenticated notification matches an awaiting payout
- **THEN** the payout keeps its reference and observed amount and lands in manual review rather than being confirmed

#### Scenario: The same outgoing transaction arrives with a different body
- **WHEN** an outgoing transaction identifier that was already recorded arrives with different content
- **THEN** the delivery is refused with 409 and the stored outcome is unchanged

### Requirement: Only an admin confirms a payout, against a bank transaction that cannot be reused
The system SHALL let an admin either confirm or flag a payout. Confirmation SHALL require an observed amount equal to the expected amount and a bank transaction reference that is not already linked to another payout and does not contradict the one already attached; flagging SHALL require a reason and place the payout in manual review. A confirmation SHALL record the admin and the time, SHALL be idempotent for the same transaction reference, and SHALL change no customer payment state.

#### Scenario: An admin confirms a completed transfer
- **WHEN** an admin confirms a payout with the matching observed amount and the bank transaction reference
- **THEN** the payout is marked reconciled with the admin and time recorded, and it reports the bank transfer as confirmed

#### Scenario: The observed amount or the transaction reference is wrong
- **WHEN** the observed amount differs from the expected amount, the reference contradicts one already attached, or that reference is already linked to another payout
- **THEN** the confirmation is rejected with 409 and the payout stays unreconciled

#### Scenario: An already reconciled payout is confirmed again
- **WHEN** a reconciled payout is confirmed again with the same transaction reference
- **THEN** the stored result is returned unchanged
- **AND** any other decision on a reconciled payout is rejected with 409
