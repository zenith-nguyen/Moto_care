# Rescue Orders Specification

## Purpose
Covers the life of one customer roadside-assistance order, from the moment a customer requests help for an incident at their location through prepayment, service, the final-price decision and closure. It owns the order status machine, the money-affecting status changes recorded on the order, incident photos and cancellation. It does not own how a mechanic is found for the order, which belongs to provider matching.

## Requirements

### Requirement: Order creation quotes a price and awaits prepayment
The system SHALL create a customer order in status `AWAITING_PREPAYMENT` with a snapshot of the incident base price, the weather surcharge, the resulting estimated price and the customer's vehicle when one is chosen or stored as the default, and SHALL open a prepayment for the estimated amount without offering the order to any mechanic.

#### Scenario: Customer requests assistance for an active incident type
- **WHEN** a customer posts to `POST /orders` with an active incident type and a valid latitude/longitude
- **THEN** the order is returned in status `AWAITING_PREPAYMENT` with its own code, estimated price and pricing breakdown
- **AND** the response reports that it is not matched and that no mechanic has been offered the order

#### Scenario: Incident type is not available
- **WHEN** the requested incident type does not exist or is not active
- **THEN** the request is rejected with 404 and no order is created

#### Scenario: Customer account is not active
- **WHEN** the requesting customer's account is not in active standing
- **THEN** the request is rejected with 403 and no order is created

#### Scenario: The customer names no vehicle
- **WHEN** the customer requests assistance without naming a vehicle and has no default vehicle in their garage
- **THEN** the order is still created and quoted, and its vehicle details are reported as empty

#### Scenario: The named vehicle is not the customer's
- **WHEN** the customer names a vehicle that is not in their own garage
- **THEN** the request is rejected with 404 and no order is created

### Requirement: Confirmed prepayment releases the order to matching
The system SHALL move an order from `AWAITING_PREPAYMENT` to `PENDING_MATCH` only once its prepayment is recorded as paid for exactly the estimated amount, and SHALL immediately attempt to reach mechanics for it.

#### Scenario: Prepayment is confirmed
- **WHEN** the prepayment for an order in `AWAITING_PREPAYMENT` is confirmed
- **THEN** the order moves to `PENDING_MATCH` and matching is attempted in the same transaction
- **AND** the order moves on to `OFFERED` when at least one mechanic was reached

#### Scenario: Prepayment is confirmed twice
- **WHEN** a confirmation arrives for a prepayment that is already paid
- **THEN** the current order and payment status are returned unchanged and no second set of offers is produced

#### Scenario: Confirmed amount differs from the estimate
- **WHEN** the recorded prepayment amount is not equal to the order's estimated price
- **THEN** a simulated confirmation is rejected with 409
- **AND** a bank transaction is acknowledged but recorded as an amount mismatch, and in both cases the order stays in `AWAITING_PREPAYMENT`

### Requirement: Every status change passes the transition guard
The system SHALL allow an order to move only along the declared transitions of its status machine, and SHALL reject any other change with 409 rather than writing the new status.

#### Scenario: A declared transition is requested
- **WHEN** a party requests a change that the status machine declares, such as `ACCEPTED` to `ARRIVED` or `PAID` to `COMPLETED`
- **THEN** the order is saved in the new status

#### Scenario: An undeclared transition is requested
- **WHEN** a party requests a change the status machine does not declare, such as starting service on an order that is still `OFFERED`
- **THEN** the request is rejected with 409 and the order keeps its current status

#### Scenario: The order has reached a closing status
- **WHEN** the order is already `COMPLETED`, `CANCELLED` or `REFUNDED`
- **THEN** no further status change is accepted

### Requirement: Participants read only their own orders
The system SHALL return to a signed-in customer or mechanic only the orders they are party to: a list of their 30 most recent orders newest first, and a full view of one order carrying its pricing snapshot, payment state, any price proposal and adjustment, and the assigned mechanic's last reported position while the order is active.

#### Scenario: Caller lists their own orders
- **WHEN** a customer or a mechanic calls `GET /orders`
- **THEN** only their own 30 most recent orders are returned newest first, each with its status, vehicle details and pricing

#### Scenario: Caller opens one order
- **WHEN** a participant calls `GET /orders/:orderId`
- **THEN** the full order is returned with its pricing, payment, price proposal and adjustment
- **AND** a caller who is neither the order's customer nor a mechanic holding a live offer or the assignment is refused with 404

### Requirement: Participants exchange phone numbers only while an assigned order is active
The system SHALL give each participant of an assigned order the other participant's name and phone number only while the order is accepted, arrived, in progress, awaiting price approval, disputed, awaiting payment or paid, and SHALL refuse the exchange at any other time. This exchange SHALL be the only place an order discloses a participant's phone number.

#### Scenario: Participant asks for the other side's contact
- **WHEN** the customer or the assigned mechanic calls `GET /orders/:orderId/participant-contact` while the order is in one of those active statuses
- **THEN** the other participant's name and phone number are returned

#### Scenario: The order is unassigned, closed or the caller is a stranger
- **WHEN** the order has no assigned mechanic, or the caller is not one of its two participants
- **THEN** the request is refused with 404
- **AND** the same request on an assigned order that has left those active statuses is refused with 409

### Requirement: Customers may attach incident photos while the order is open
The system SHALL let only the order's customer attach incident photos, SHALL cap an order at six photos, and SHALL refuse new photos once the order is completed, cancelled, awaiting refund or refunded. Stored photos SHALL be readable only by the order's customer and its assigned mechanic.

#### Scenario: Customer attaches a photo to an open order
- **WHEN** the customer posts an image to `POST /orders/:orderId/photos` while the order is still open and holds fewer than six photos
- **THEN** the photo is stored and its metadata is returned

#### Scenario: The photo limit or a closed order blocks the upload
- **WHEN** the order already holds six photos, or the order is completed, cancelled, awaiting refund or refunded
- **THEN** the upload is rejected with 409

#### Scenario: The assigned mechanic tries to attach a photo
- **WHEN** the order's assigned mechanic posts an image to the order's photos
- **THEN** the upload is refused with 403 while the mechanic keeps read access to the photos already attached

#### Scenario: Someone who is not a participant reads the photos
- **WHEN** a caller who is neither the customer nor the assigned mechanic lists or fetches a photo of the order
- **THEN** the request is rejected with 404

### Requirement: Customers may cancel before service and live offers are withdrawn
The system SHALL let the order's customer cancel with a reason before service, SHALL record the reason and who cancelled, and SHALL place the order in `REFUND_PENDING` when the prepayment has to be returned or in `CANCELLED` when it does not. Offers still open on that order SHALL be withdrawn.

#### Scenario: Customer cancels an order whose prepayment must be returned
- **WHEN** the customer posts to `POST /orders/:orderId/cancel` with a reason and the prepayment requires a refund
- **THEN** the order moves to `REFUND_PENDING` with the refund amount reported, and the reason and canceller are recorded

#### Scenario: Customer cancels an order that currently holds offers
- **WHEN** the cancelled order is in `OFFERED`
- **THEN** every offer still open on it is closed so no mechanic can accept it afterwards

#### Scenario: Cancellation comes too late
- **WHEN** the order has already passed the point where the status machine permits cancellation
- **THEN** the request is rejected with 409 stating the order needs admin review or is already closed

### Requirement: Service starts only on a code the customer presents in person
The system SHALL let the assigned mechanic mark arrival, SHALL issue the customer a start code that is valid for five minutes and only after arrival, and SHALL move the order to `IN_PROGRESS` only when the assigned mechanic submits that unexpired code.

#### Scenario: Mechanic arrives and the customer obtains the code
- **WHEN** the assigned mechanic posts to `POST /orders/:orderId/arrive` and the customer then calls `GET /orders/:orderId/start-token`
- **THEN** the order is in `ARRIVED` and a code with its expiry is returned for the customer to show

#### Scenario: The code is requested before arrival
- **WHEN** the customer requests the start code while the order is not yet `ARRIVED`
- **THEN** the request is rejected with 409

#### Scenario: The submitted code is wrong or stale
- **WHEN** the mechanic posts to `POST /orders/:orderId/start` with a code that is expired or does not match the order and its customer
- **THEN** the request is rejected with 403 and the order stays in `ARRIVED`

### Requirement: The final price is proposed by the mechanic and decided by the customer
The system SHALL let the assigned mechanic propose a final price with a reason while the order is `IN_PROGRESS`, moving it to `AWAITING_PRICE_APPROVAL`. On the customer's approval the order SHALL move to `AWAITING_PAYMENT` when the difference against the prepayment still has to be settled, or straight to `PAID` when it does not. On the customer's rejection the order SHALL return to `IN_PROGRESS`, from where the mechanic may escalate the rejected proposal to `PRICE_DISPUTED` for admin resolution.

#### Scenario: Customer approves the proposed final price
- **WHEN** the customer posts to `POST /orders/:orderId/price-proposals/:proposalId/approve` while the proposal is still pending
- **THEN** the order records the final price together with any extra cost or discount
- **AND** the order moves to `AWAITING_PAYMENT` if an adjustment is owed, otherwise to `PAID`

#### Scenario: Customer rejects the proposed final price
- **WHEN** the customer posts to `POST /orders/:orderId/price-proposals/:proposalId/reject` with a reason
- **THEN** the proposal is marked rejected with that reason and the order returns to `IN_PROGRESS`

#### Scenario: Mechanic escalates a rejected proposal
- **WHEN** the assigned mechanic posts to `POST /orders/:orderId/price-proposals/:proposalId/dispute` with a reason while the proposal stands rejected and the order is `IN_PROGRESS`
- **THEN** the order moves to `PRICE_DISPUTED` and waits for an admin decision, which either applies the price or returns the order to `IN_PROGRESS`

### Requirement: Completion requires a settled final price
The system SHALL let the assigned mechanic complete an order only once an approved final price is recorded and the order has reached `PAID`, and SHALL credit the mechanic's earnings exactly once as part of that completion.

#### Scenario: Mechanic completes a fully settled order
- **WHEN** the assigned mechanic posts to `POST /orders/:orderId/complete` on an order in `PAID` that carries a final price
- **THEN** earnings are settled for that order and the order moves to `COMPLETED`

#### Scenario: Completion is attempted too early
- **WHEN** completion is requested while no final price is recorded or the order has not reached `PAID`
- **THEN** the request is rejected with 409 stating the final price and payment adjustment must be settled first
