# Admin Console Specification

## Purpose
This capability describes what an administrator can see and do. The console is not a separate application: signing into the customer app with an administrator account opens the admin shell instead of the customer home. It covers the operational dashboard, order oversight, payment reconciliation with anomaly detection, and the manual decisions on disputed final prices, provider withdrawals, bank payouts and refunds. Every money movement it offers is simulated inside the platform; this capability never performs a real bank transfer.

## Requirements

### Requirement: Administrator access through the customer app
The system SHALL open the admin shell when an account whose role is administrator signs into the customer app, SHALL refuse administrative screens and endpoints to any other role, and SHALL NOT allow an administrator account to be created by self-registration.

#### Scenario: Administrator signs in
- **WHEN** an administrator signs into the customer app
- **THEN** the admin shell opens with its own navigation covering the overview, orders, provider approvals, finance, request handling and account areas

#### Scenario: Non-administrator reaches an admin screen
- **WHEN** a customer or provider session opens an administrative route or calls an administrative endpoint
- **THEN** access is refused and the client is sent back to sign-in

#### Scenario: Self-registration as administrator
- **WHEN** a registration request asks for the administrator role
- **THEN** it is rejected with 400

### Requirement: Operational dashboard over a bounded period
The system SHALL report, for a requested period, the account, provider and order counts and the platform money positions, and SHALL mark every dashboard response as sandbox data. The period defaults to the last seven days ending now and may not start after its end or span more than 366 days.

#### Scenario: Summary for the default period
- **WHEN** an administrator opens the dashboard summary without naming a period
- **THEN** the last seven days are reported: accounts by role and accounts created in the period, providers by approval status with how many are online and how many have a fresh position, orders grouped by status with a completion rate, and the money positions for amounts collected, currently held, settled to providers, pending refund, refunded, provider wallet balances, pending withdrawals and amounts withdrawn

#### Scenario: Daily series
- **WHEN** an administrator requests the daily series for a period
- **THEN** one row per calendar day in Asia/Ho_Chi_Minh is returned, each with orders created, orders completed, amount collected, amount settled to providers, amount refunded and amount withdrawn, including days with no activity

#### Scenario: Invalid period
- **WHEN** the requested period starts at or after its end, or spans more than 366 days
- **THEN** the request is rejected with 400

### Requirement: Order oversight
The system SHALL give an administrator the 50 most recent orders and the full detail of any single order.

#### Scenario: Recent orders
- **WHEN** an administrator opens the order list
- **THEN** the 50 newest orders are returned newest first with their code, status, customer, assigned provider, estimated price and final price

#### Scenario: Single order detail
- **WHEN** an administrator opens one order
- **THEN** its incident type, status, price breakdown of estimate, extra cost, discount and final price, pickup location, customer contact details and assigned provider with their last known position are returned
- **AND** an unknown order returns 404

### Requirement: Reconciliation of orders against payments and settlements
The system SHALL return a paginated, point-in-time consistent reconciliation of the orders created in a period against their payments, price adjustments and provider wallet credits, and SHALL flag every inconsistency it detects on each row.

#### Scenario: Reviewing the ledger
- **WHEN** an administrator opens the reconciliation for a period
- **THEN** each row shows the order with its customer and provider, the payment with its status, amount and demo marker, the settlement with its wallet credits and any price adjustment, and the flags raised for that row, which include a completed order without a paid payment, a payment that does not match the final price, a completed order whose wallet credit does not match, a refund state mismatch between order and payment, a refunded order that still carries a wallet credit, more than one payment on an order, and an adjustment status that contradicts the order status

#### Scenario: Filtering and paging
- **WHEN** an administrator filters by payment status and asks for a page of at most 100 rows
- **THEN** only orders whose payment has that status are returned, newest first, together with the total number of matching orders and the number of pages for that same filter

### Requirement: Resolution of disputed final prices
The system SHALL show the final-price proposals a customer has disputed and SHALL let an administrator approve or reject each one once, recording who decided and the stated reason.

#### Scenario: Reviewing the queue
- **WHEN** an administrator opens the disputed price queue
- **THEN** up to 50 disputed proposals are returned, longest waiting first, with their order and the proposed final price

#### Scenario: Deciding a dispute
- **WHEN** an administrator approves or rejects a disputed proposal with a reason
- **THEN** the decision, the deciding administrator and the time are recorded, an approval applies the proposed final price and moves the order to awaiting payment or paid, a rejection returns the order to in progress, and the participants see the new order status

#### Scenario: Deciding again
- **WHEN** the same proposal is decided a second time
- **THEN** the already recorded outcome is returned unchanged, and a proposal that is no longer awaiting resolution is refused with 409

### Requirement: Withdrawal and payout decisions
The system SHALL let an administrator approve or reject each pending provider withdrawal once, and separately confirm or flag the bank payout that follows an approval, without changing any customer payment state.

#### Scenario: Deciding a withdrawal
- **WHEN** an administrator approves or rejects one of the up to 50 pending withdrawals, oldest first, giving a reason for a rejection
- **THEN** the reserved amount is released, an approval also debits the provider wallet and records the withdrawal transaction, and the deciding administrator and time are recorded
- **AND** repeating the same decision returns the same result, while the opposite decision on a resolved request is refused with 409

#### Scenario: Confirming a payout
- **WHEN** an administrator confirms a payout awaiting transfer with the observed amount and the bank transaction reference
- **THEN** the payout is marked reconciled with the confirming administrator and time, while a mismatched amount, a reference already linked to another payout, or a payout already reconciled against a different reference is refused with 409

#### Scenario: Flagging a payout
- **WHEN** an administrator flags a payout with a reason instead of confirming it
- **THEN** the payout moves to manual review with that reason and stays in the pending payout queue

### Requirement: Refunds are simulated only
The system SHALL let an administrator return money to a customer only as a simulated refund of a demo payment, and SHALL NOT perform any real bank transfer.

#### Scenario: Full refund queue
- **WHEN** an administrator opens the refund queue
- **THEN** up to 50 orders awaiting a refund are listed oldest first with their code, customer, amount, demo marker and cancellation reason

#### Scenario: Refunding an order
- **WHEN** an administrator refunds an order that is awaiting a refund and was paid with a demo payment
- **THEN** the payment and the order become refunded, the refund time is recorded, participants see the new order status, and repeating the call returns the same already refunded result

#### Scenario: Refunding an approved price reduction
- **WHEN** an administrator settles one of the up to 50 approved price reductions awaiting a refund
- **THEN** the adjustment is marked settled as a demo movement and the order becomes paid, and an order with no pending reduction or without a paid demo prepayment is refused with 409
