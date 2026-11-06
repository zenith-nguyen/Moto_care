# Realtime Messaging Specification

## Purpose
This capability covers the authenticated websocket session that carries live order events, and the in-order chat that a customer and the assigned mechanic use while a job is running. It defines who may join a realtime channel, which events are pushed to it, and how chat messages, including image attachments, are created, stored, delivered and read back in a stable order. Matching, pricing and payment rules are out of scope; this capability only transports the events they produce.

## Requirements

### Requirement: Authenticated realtime session
The system SHALL open a websocket session only for a handshake that carries an access token belonging to an active account whose role and token version still match the token, and SHALL close every other connection immediately.

#### Scenario: Valid handshake
- **WHEN** a client connects with an access token of an active account
- **THEN** the session stays open and is bound to that account and role
- **AND** an approved provider that is currently online is also subscribed to its own dispatch channel

#### Scenario: Rejected handshake
- **WHEN** the handshake has no token, an unverifiable token, or a token whose account is inactive, suspended, or whose role or token version no longer matches
- **THEN** the server disconnects the socket without delivering any event

### Requirement: Participant-only order channel
The system SHALL subscribe a session to an order channel only when the requested order exists and the connecting account is that order's customer or its assigned provider.

#### Scenario: Participant joins
- **WHEN** a participant requests an order on connect
- **THEN** the session joins that order's channel and receives its subsequent events

#### Scenario: Outsider is refused
- **WHEN** the requested order does not exist, or the account is neither its customer nor its assigned provider
- **THEN** the connection is closed instead of joined

### Requirement: Live order and dispatch events
The system SHALL push every provider location update reported against an active order, every order status change and every new message of an order to that order's channel as `provider.location_updated`, `order.status_changed` and `message.created`, and SHALL push dispatch offers to the targeted provider as `offer.created` and `offer.expired`.

#### Scenario: Provider reports position on an active order
- **WHEN** the assigned provider submits its GPS position for an order that is accepted, arrived, in progress, awaiting price approval, price disputed, awaiting payment or paid
- **THEN** `provider.location_updated` with the order, provider, coordinates and update time reaches every session in that order's channel

#### Scenario: Order status changes
- **WHEN** an order moves to a new status
- **THEN** `order.status_changed` with the order and its new status reaches that order's channel

#### Scenario: Offer is dispatched or expires
- **WHEN** an offer is created for a provider or that offer expires
- **THEN** `offer.created` with the order, offer and expiry time, or `offer.expired` with the order and offer, reaches that provider's dispatch channel

### Requirement: Message creation restricted to active participation
The system SHALL accept a new message only from the order's customer or assigned provider, only while the order is accepted, arrived, in progress, awaiting price approval, price disputed, awaiting payment or paid, and only when it carries text, an image, or both. The system SHALL limit message creation to 20 requests per minute per client network address and SHALL answer 429 beyond that.

#### Scenario: Participant posts a message
- **WHEN** a participant posts text, an image, or both on an order in a writable status
- **THEN** the message is stored and returned with its identifier, sender, content, optional image reference and creation time
- **AND** the same message is broadcast to the order channel as `message.created`

#### Scenario: Empty message
- **WHEN** a request carries neither text nor an image
- **THEN** it is rejected with 400 and nothing is stored

#### Scenario: Chat is closed or caller is not a participant
- **WHEN** the order is in any other status, or the caller is not one of its two participants
- **THEN** the request is rejected with 404 and nothing is stored
- **AND** a caller whose role is neither customer nor mechanic is rejected with 403 before the order is looked up

#### Scenario: Message rate limit is exceeded
- **WHEN** more than 20 message creation requests arrive from the same client network address within one minute
- **THEN** the requests beyond the limit are rejected with 429 and nothing is stored

### Requirement: Validated, privately served image attachments
The system SHALL accept an attachment only when its actual bytes are a genuine JPEG, PNG or WebP that matches the declared type and stays within the configured maximum size (5 MiB by default), and SHALL serve the stored bytes only to a participant of that order.

#### Scenario: Attachment is accepted
- **WHEN** a participant uploads a genuine JPEG, PNG or WebP within the size limit
- **THEN** the created message carries an image reference with its retrieval URL, media type and byte size

#### Scenario: Attachment is refused
- **WHEN** the uploaded bytes are empty, exceed the maximum size, or are not a genuine image of the declared supported type
- **THEN** empty bytes, or a file that is not a genuine image of the declared supported type, are rejected with 400, and a file over the maximum size is rejected with 413
- **AND** no message and no file are kept in either case

#### Scenario: Attachment retrieval
- **WHEN** a participant requests a message image
- **THEN** the bytes are returned with their media type, a private cache directive and content-type sniffing disabled
- **AND** the same request from another customer or mechanic returns 404, and from an account of any other role returns 403

### Requirement: Ordered, replayable chat history
The system SHALL return at most the 100 newest messages of an order to either participant, selected and ordered by their identifiers and returned lowest identifier first, including after the order is closed, and clients SHALL merge pushed and fetched copies of a message by identifier and order them by creation time and then identifier.

#### Scenario: Opening a conversation
- **WHEN** a participant lists the messages of an order, whether it is still running or already finished
- **THEN** up to the 100 highest-numbered messages of that order are returned, lowest identifier first

#### Scenario: Pushed message already fetched
- **WHEN** a message arrives over the websocket and the same message also appears in a later fetch
- **THEN** the conversation shows it once, in creation order

#### Scenario: Reconnect
- **WHEN** the websocket reconnects for an order the client is viewing
- **THEN** the client re-fetches that order's history and keeps its previous history if the re-fetch fails

### Requirement: Notification fan-out never blocks realtime delivery
The system SHALL publish each event it transports to its channel first and then create the durable notification for the recipients of that event, SHALL create at most one durable notification per occurrence, and a failure of that notification SHALL NOT fail the action that caused it.

#### Scenario: New message notifies the counterpart
- **WHEN** a participant sends a message
- **THEN** the other participant receives a durable `MESSAGE_CREATED` notification carrying the order and message, created at most once per message

#### Scenario: Other transported events notify their recipients
- **WHEN** an order status change, a dispatch offer creation or expiry, or the assigned mechanic's arrival near the customer is published to its channel
- **THEN** a durable notification of the matching type is created, for both order participants on a status change, for the targeted mechanic on an offer event, and for the customer on arrival
- **AND** repeating the same occurrence does not create a second notification

#### Scenario: Notification fails
- **WHEN** creating the durable notification fails
- **THEN** the websocket event is still delivered and the originating request still succeeds
