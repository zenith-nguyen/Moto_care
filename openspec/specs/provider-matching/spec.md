# Provider Matching Specification

## Purpose
Covers how a paid rescue order reaches a mechanic: who is eligible to receive it, how it is broadcast to those mechanics at once, and how the race between them is resolved. It owns offer creation, acceptance, rejection, expiry and the return of an unclaimed order to matching. It does not own what happens after a mechanic is assigned, which belongs to the rescue-order lifecycle.

## Requirements

### Requirement: Only reachable, free and nearby mechanics are eligible
The system SHALL consider a mechanic for an order only when their account is active, their mechanic profile is approved, they are marked online, their last known position is no older than the configured location freshness limit and lies within the configured match radius of the customer, they have no other offer still open, they are not already handling an active order, and they have not already been offered this same order.

#### Scenario: A nearby, idle, recently-seen mechanic is considered
- **WHEN** matching runs for an order and an approved, online mechanic with an active account was last seen inside the freshness limit and within the match radius
- **THEN** that mechanic is among the candidates, ordered by distance from the customer with the closest first
- **AND** reach is judged by the platform's single configured match radius, never by the service radius a mechanic states on their own profile

#### Scenario: A mechanic is stale, busy or already engaged
- **WHEN** the mechanic's last position is older than the freshness limit, or they already hold an open offer, or they are already on an order in `ACCEPTED`, `ARRIVED`, `IN_PROGRESS`, `AWAITING_PRICE_APPROVAL`, `PRICE_DISPUTED`, `AWAITING_PAYMENT` or `PAID`
- **THEN** that mechanic is skipped and receives no offer

#### Scenario: A mechanic already saw this order
- **WHEN** the mechanic was offered this same order earlier in its life
- **THEN** they are not offered it again, whatever the outcome of that earlier offer was

### Requirement: An order is broadcast to all eligible mechanics at once
The system SHALL create one offer per eligible mechanic in the same pass, each expiring after the configured offer lifetime, SHALL move the order to `OFFERED` when at least one offer was created, and SHALL notify each of those mechanics of their offer and its expiry.

#### Scenario: Several mechanics are eligible
- **WHEN** matching runs and more than one mechanic qualifies
- **THEN** every qualifying mechanic receives their own offer for the order with the same lifetime
- **AND** the order moves to `OFFERED` once

#### Scenario: No mechanic is eligible
- **WHEN** matching runs and no mechanic qualifies
- **THEN** no offer is created and the order keeps the status it already had, reported to the customer as not matched yet with an invitation to retry later

### Requirement: Going online requires a fresh position and resumes waiting orders
The system SHALL refuse to mark a mechanic online unless their profile is approved, their account is active and their last known position is within the freshness limit, and SHALL re-run matching for the 30 longest-waiting unassigned orders as soon as a mechanic comes online.

#### Scenario: Mechanic goes online with a fresh position
- **WHEN** an approved, active mechanic with a recent position posts their availability as online
- **THEN** they are marked online and matching is re-run for the 30 longest-waiting orders that have no assigned mechanic, so a previously unmatched order can reach them

#### Scenario: Mechanic goes online without a usable position
- **WHEN** the mechanic has never reported a position or their last one is older than the freshness limit
- **THEN** the request is rejected with 422 asking them to update their location first

### Requirement: A mechanic sees only their own unexpired offers
The system SHALL expose to a mechanic only offers addressed to them that are still open and not yet past their expiry, soonest expiry first, with the order's incident, vehicle, price breakdown and customer location. A mechanic SHALL be able to read the full order only while holding such an offer or after being assigned to it.

#### Scenario: Mechanic lists their offers
- **WHEN** the mechanic calls `GET /providers/me/offers/pending`
- **THEN** only their own still-open, unexpired offers are returned, each with its expiry and enough order detail to decide

#### Scenario: Mechanic reads an order they have no claim on
- **WHEN** a mechanic requests an order to which they hold neither a live offer nor the assignment
- **THEN** the request is rejected with 404

### Requirement: The first mechanic to accept wins and the others lose the offer
The system SHALL assign the order to the first mechanic whose acceptance succeeds, move the order to `ACCEPTED`, and close every other offer still open on that order so no second mechanic can take it. Acceptance SHALL be refused when the offer is no longer open, has passed its expiry, or the accepting mechanic is no longer approved, online, active or free.

#### Scenario: One mechanic accepts a broadcast offer
- **WHEN** a mechanic posts to `POST /orders/:orderId/offers/:offerId/accept` on an open, unexpired offer
- **THEN** the order is assigned to them and moves to `ACCEPTED`
- **AND** all other offers still open on that order are closed

#### Scenario: Another mechanic accepts the same order a moment later
- **WHEN** a second mechanic accepts after the order has already been assigned
- **THEN** the request is rejected with 409 stating the offer is no longer available

#### Scenario: The accepting mechanic is no longer available
- **WHEN** the accepting mechanic is not approved, not online, not an active account, or is already handling another active order
- **THEN** the acceptance is rejected with 409 and the order keeps looking for a mechanic

### Requirement: Rejecting an offer releases it without disturbing the other recipients
The system SHALL mark a rejected offer as rejected, and SHALL return the order to `PENDING_MATCH` and run matching again only when no offer on that order is still open; while any recipient still holds a live offer the order SHALL stay in `OFFERED`.

#### Scenario: One recipient of a broadcast rejects
- **WHEN** a mechanic posts to `POST /orders/:orderId/offers/:offerId/reject` while other recipients still hold open offers
- **THEN** only their own offer is marked rejected and the order stays in `OFFERED` for the others

#### Scenario: The last live offer is rejected
- **WHEN** the rejected offer was the only one still open on the order
- **THEN** the order returns to `PENDING_MATCH` and matching runs again immediately, which may reach mechanics who were not reachable before

### Requirement: Offers expire on their own and release the order
The system SHALL expire an offer shortly after its lifetime has passed, by a recurring sweep rather than any party acting, SHALL treat an offer as already gone from the moment its expiry time is reached even before the sweep records it, SHALL notify the mechanic the offer is gone, and SHALL apply the same release rule as rejection so the order reopens for matching only when no offer on it is still open.

#### Scenario: Nobody answers a broadcast offer
- **WHEN** an open offer passes its expiry
- **THEN** it is marked expired, its mechanic is told it is gone, and the order's status is published to its watchers

#### Scenario: An offer is used between its expiry time and the sweep
- **WHEN** a mechanic lists or accepts an offer whose expiry has passed but which the sweep has not yet marked expired
- **THEN** the offer is absent from their pending offers and the acceptance is rejected with 409 stating the offer has expired

#### Scenario: The last open offer expires
- **WHEN** the expired offer was the only one still open on the order
- **THEN** the order returns to `PENDING_MATCH` and matching runs again, notifying any mechanic newly offered the order

### Requirement: Customers can retry matching on an unmatched order
The system SHALL let the order's customer ask for matching to be re-run, and SHALL refuse the retry when the order is not waiting for a mechanic.

#### Scenario: Customer retries an order nobody has taken
- **WHEN** the customer posts to `POST /orders/:orderId/retry-match` while the order is in `PENDING_MATCH` or `OFFERED`
- **THEN** matching is re-run and the response reports whether a mechanic was reached and, if so, when the offer expires

#### Scenario: Retry on an order that is no longer waiting
- **WHEN** the order has already been assigned or otherwise left the waiting states
- **THEN** the retry is rejected with 409 stating the order is not waiting for matching

#### Scenario: Retry on someone else's order
- **WHEN** the caller is not the order's customer
- **THEN** the request is rejected with 404
