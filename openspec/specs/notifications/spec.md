# Notifications Specification

## Purpose
This capability covers the durable notification inbox: the stored record of everything the platform tells an account about, kept whether or not that account was connected when it happened. It defines what is stored, who may read it, how the inbox is paged, how read state changes, how an app installation registers and revokes its push credential, and what the background push path actually does. The live websocket session, the order channel and the chat it carries belong to realtime messaging; this capability owns only the durable record and its delivery.

## Requirements

### Requirement: Durable per-recipient notification record
The system SHALL store every notification it raises as a durable record owned by exactly one recipient account, carrying a type, a short title, a body, a string-keyed routing payload, a creation time and a read state that starts unread. The record SHALL remain readable after the live event that produced it has passed.

#### Scenario: Event raises a notification
- **WHEN** the platform raises a notification for a recipient account
- **THEN** a record is stored for that account alone, unread, with its type, title, body, routing payload and creation time
- **AND** the routing payload names the in-app destination and the order, offer or message it refers to, when the notification concerns one

#### Scenario: Recipient was not connected
- **WHEN** the recipient had no live session at the moment of the event and later opens the inbox
- **THEN** the record is still listed with its original content and creation time
- **AND** a record whose relevance window has already elapsed is still listed, because listing does not filter on expiry

#### Scenario: Account decision outside the order flow
- **WHEN** an administrator approves or rejects a mechanic application
- **THEN** a durable notification of the general system type is stored for that applicant with the outcome and the destination to open next
- **AND** the review decision stands even if storing that notification fails

### Requirement: At-most-once creation per occurrence
The system SHALL accept an optional occurrence key when a notification is raised, SHALL keep at most one record for a given key, and SHALL return the already stored record instead of creating a second one when the same key is raised again, including when two attempts race.

#### Scenario: Same occurrence raised twice
- **WHEN** a notification is raised twice with the same occurrence key
- **THEN** the second attempt returns the record created by the first
- **AND** only one record exists for that key and no additional push attempt is queued

#### Scenario: Concurrent attempts collide
- **WHEN** two attempts with the same occurrence key are stored at the same instant and the store rejects the later one as a duplicate
- **THEN** the surviving record is returned to both callers instead of an error

### Requirement: Owner-only cursor-paged inbox
The system SHALL return from `GET /notifications` only the signed-in account's own notifications, newest first, in pages of a caller-chosen size between 1 and 100 that defaults to 30, together with a cursor for the next page and the account's unread count. An optional flag SHALL restrict the page to unread notifications.

#### Scenario: Reading the inbox
- **WHEN** a signed-in account lists its notifications
- **THEN** only that account's notifications are returned, newest first, each with its identifier, type, title, body, routing payload, read time and creation time
- **AND** the unread count reported is the account's total unread notifications, independent of the cursor and of the unread-only flag

#### Scenario: Paging through more than one page
- **WHEN** more notifications match than the requested page size
- **THEN** the page is truncated to the requested size and a cursor pointing past the last returned item is included
- **AND** the final page returns no cursor

#### Scenario: Invalid query values
- **WHEN** the request carries a non-boolean unread-only flag, a non-integer page size, or a page size outside 1 to 100
- **THEN** the request is rejected with 400 and nothing is returned

### Requirement: Read state controlled by the owner
The system SHALL mark a single notification read only for the account that owns it and SHALL answer 404 when the notification does not exist or belongs to another account. The system SHALL also mark every currently unread notification of the signed-in account read in one request, reporting how many were updated and the instant applied.

#### Scenario: Owner marks one notification read
- **WHEN** the owner calls `PATCH /notifications/{id}/read` on an unread notification
- **THEN** the notification is returned with its read time set
- **AND** repeating the call leaves the first read time unchanged

#### Scenario: Another account tries to mark it read
- **WHEN** an account that does not own the notification calls the same endpoint
- **THEN** the request is rejected with 404 and the notification stays unread

#### Scenario: Clearing the whole inbox
- **WHEN** the account calls `PATCH /notifications/read-all`
- **THEN** every notification of that account that was still unread is marked read at one common instant, and the number updated and that instant are returned
- **AND** a following inbox listing reports an unread count of zero

### Requirement: Private installation registration
The system SHALL let a signed-in account register or refresh one app installation for push through `PUT /notifications/devices` with the installation identifier, platform and push token, and SHALL never return or echo that token in any response. One registration SHALL exist per installation identifier, and one push token SHALL belong to at most one installation.

#### Scenario: Installation registers after sign-in
- **WHEN** a signed-in account registers an installation identifier, platform and push token
- **THEN** the registration is stored or refreshed as enabled against that account, with its last-seen time updated
- **AND** the response carries only the installation identifier, platform, enabled state and last-seen time, never the push token

#### Scenario: Push token moves to another installation
- **WHEN** a push token that is already registered is submitted under a different installation identifier
- **THEN** the earlier registration holding that token is removed and only the new installation keeps it

#### Scenario: Installation is revoked
- **WHEN** the account calls `DELETE /notifications/devices/{installationId}` at sign-out or when revoking a token
- **THEN** that installation is marked disabled and is no longer eligible for push
- **AND** an installation identifier the account never registered is answered with 404

### Requirement: Push delivery is an optional side channel
The system SHALL queue a push attempt for each enabled installation of the recipient only while background push is switched on for the deployment, and SHALL never make push a precondition for a notification being stored, listed or marked read. Push is switched off in the shipped configuration, so no push attempt is queued or sent there.

#### Scenario: Push switched off, as shipped
- **WHEN** a notification is raised while background push is switched off
- **THEN** the durable record is stored and listable as usual and no push attempt is queued or sent for it
- **AND** the apps rely on the live session while open and on this inbox otherwise

#### Scenario: Push switched on with an enabled installation
- **WHEN** a notification is raised while push is switched on and the recipient has enabled installations
- **THEN** one attempt per installation is queued and carries the title, body, routing payload and the notification's identifier
- **AND** an attempt for an installation that is disabled or has no usable token is abandoned without being sent

### Requirement: Bounded push retries
The system SHALL retry a push attempt that failed for a transient reason after a delay that grows with each try, SHALL abandon the attempt after five tries, and SHALL disable an installation whose token the push service rejects as permanently invalid so that no further attempt targets it. An attempt left in progress by an interrupted worker SHALL be returned to the retry queue.

#### Scenario: Transient failure
- **WHEN** a push attempt fails for a reason that may succeed later
- **THEN** it is scheduled for another try after a delay that grows with each previous try, and it is abandoned once five tries have been made

#### Scenario: Token is permanently rejected
- **WHEN** the push service reports that the installation's token is invalid or no longer registered
- **THEN** the attempt is abandoned and that installation is disabled, so later notifications queue no attempt for it
- **AND** the durable notification itself is unaffected and stays in the recipient's inbox

#### Scenario: Worker is interrupted
- **WHEN** an attempt stays in progress longer than the worker's recovery window because the process stopped mid-flight
- **THEN** it is returned to the retry queue and picked up again under the same try limit
