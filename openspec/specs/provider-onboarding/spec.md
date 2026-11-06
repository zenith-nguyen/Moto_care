# Provider Onboarding Specification

## Purpose
This capability covers how a mechanic joins the platform and how they are presented afterwards: applying from a customer account, the single administrative review that promotes or refuses them, the conditions under which they become available for work, the skills and tier that describe their competence, what a customer may see and rate about the mechanic assigned to their order, and the read-only directory of repair shops, charging stations, fuel stations and parts stores shown on the map. Order dispatch, chat and money flows are out of scope.

## Requirements

### Requirement: One provider application per account
The system SHALL let a customer account submit exactly one application to become a provider, recorded as PENDING, without changing the account's role or sign-in.

#### Scenario: Customer applies
- **WHEN** a customer submits an application with an optional short biography, supporting document link, years of experience and preferred service radius
- **THEN** the application is stored with approval status PENDING
- **AND** the account stays a customer until an administrator decides

#### Scenario: Duplicate application
- **WHEN** an account that already has an application submits another one
- **THEN** the request is rejected with 409 and the existing application is unchanged

#### Scenario: Checking own application
- **WHEN** an account asks for its own application
- **THEN** it receives the stored application with its approval status, or NONE when it has never applied

### Requirement: Single administrative review of an application
The system SHALL let an administrator approve or reject a pending application exactly once; approval promotes the account to an active provider, and rejection never changes a customer applicant's account.

#### Scenario: Approval
- **WHEN** an administrator approves a pending application
- **THEN** the application becomes APPROVED and the account becomes an active provider that starts offline
- **AND** any session issued to a customer applicant before the promotion stops working, and the applicant is notified of the outcome

#### Scenario: Rejection
- **WHEN** an administrator rejects a pending application
- **THEN** the application becomes REJECTED, a customer applicant keeps their unchanged customer account, and an account that registered directly as a provider is suspended
- **AND** the applicant is notified of the outcome

#### Scenario: Second decision
- **WHEN** an administrator reviews an application that was already approved or rejected
- **THEN** the request is rejected with 409 and nothing changes

### Requirement: Availability requires approval and a fresh position
The system SHALL let a provider go online only when their application is approved, their account is active, and they have reported a position more recently than the configured freshness window.

#### Scenario: Going online
- **WHEN** an approved, active provider with a recent position switches to online
- **THEN** they are marked online and orders still waiting for a mechanic are matched again

#### Scenario: Not approved
- **WHEN** a provider whose application is not approved, or whose account is not active, tries to go online
- **THEN** the request is refused with 403

#### Scenario: Stale position
- **WHEN** an approved provider has no position, or only an outdated one, and tries to go online
- **THEN** the request is refused with 422 asking them to update their location first

### Requirement: Administrator-controlled skills and tier
The system SHALL keep every skill a provider claims unverified until an administrator reviews it, and SHALL allow only an administrator to change a claim's verification status or a provider's tier.

#### Scenario: Provider edits own claims
- **WHEN** a provider replaces their claimed skills with a set of at most 20 active catalog skills
- **THEN** unclaimed skills are dropped, newly claimed ones are stored as PENDING, and previously rejected ones that are claimed again return to PENDING
- **AND** a set containing an unknown or deactivated skill is rejected with 400

#### Scenario: Administrator reviews a claim
- **WHEN** an administrator sets a claim to VERIFIED, REJECTED or back to PENDING
- **THEN** the claim takes that status and a verification time is recorded only for VERIFIED
- **AND** verifying a claim on a deactivated catalog skill is refused with 409

#### Scenario: Administrator sets a tier
- **WHEN** an administrator changes a provider's tier to STANDARD, SILVER, GOLD or PLATINUM
- **THEN** the new tier is stored and shown wherever that provider's profile is presented

### Requirement: Assigned-provider profile visible to the customer
The system SHALL show the customer of an order that has an assigned provider a profile containing that provider's name, biography, years of experience, service radius, tier, verified skills only and rating summary, and SHALL NOT include their phone number.

#### Scenario: Customer views the assigned mechanic
- **WHEN** the customer or the assigned provider of an order that is accepted through completed requests the assigned provider's profile
- **THEN** the profile is returned with only verified skills, plus that provider's review count and average rating

#### Scenario: No assignment or not a participant
- **WHEN** the order has no assigned provider, is not in one of those statuses, or the caller is not one of its two participants
- **THEN** the request returns 404

### Requirement: Reviews after a completed order
The system SHALL let each participant of a completed order leave exactly one rating from 1 to 5 with an optional comment about the other participant, and SHALL count those ratings toward the reviewed account's rating summary.

#### Scenario: Participant reviews the other side
- **WHEN** a participant of a completed order submits a rating between 1 and 5 with an optional comment of at most 500 characters
- **THEN** the review is stored against that order with the reviewer and the other participant as reviewee

#### Scenario: Duplicate or premature review
- **WHEN** the same participant reviews the order again, or any participant creates or lists reviews for an order that is not completed
- **THEN** the request is rejected with 409

#### Scenario: Provider reads their own reviews
- **WHEN** a provider lists the reviews written about them
- **THEN** up to the 50 newest reviews are returned together with the total count and the average rating

### Requirement: Read-only service-location directory
The system SHALL expose the shared directory of repair shops, charging stations, fuel stations and parts stores to signed-in clients as read-only map data, returning only active entries and supporting a filter by type.

#### Scenario: Map viewport query
- **WHEN** a client asks for the locations inside a map viewport, optionally filtered by type
- **THEN** up to 200 active entries inside those bounds are returned with name, type, origin, address, phone, website, opening hours, coordinates and the verified and partner markers
- **AND** partners are listed first, then verified entries, then the rest by name

#### Scenario: Unusable viewport
- **WHEN** the requested bounds are inverted or span more than one degree in either direction
- **THEN** the request is rejected with 400

#### Scenario: Proximity query
- **WHEN** a client asks for locations near a coordinate, with a radius of up to 50 km (5 km by default) and a limit of up to 100 entries (50 by default)
- **THEN** active entries within that radius are returned nearest first, each with its straight-line distance in metres
