# Customer Profile Specification

## Purpose
Covers the personal record a signed-in account keeps in the REVO app: name, contact details, emergency contact, medical note, saved home and work addresses, and the customer's garage of vehicles with one default vehicle. It defines how that data is read, changed and kept consistent so a rescue request can be raised with known contact and vehicle details. It does not cover credentials, sessions or roles, nor how the data is consumed when dispatching a rescue order.

## Requirements

### Requirement: Own profile retrieval
The system SHALL return the signed-in account's own profile from GET /users/me, including name, email address, phone number, emergency contact name and phone, medical note, home and work address, role and account status.

#### Scenario: Signed-in account reads its profile
- **WHEN** an authenticated account calls GET /users/me
- **THEN** the response is 200 with that account's own profile fields, never another account's
- **AND** fields that were never filled in are returned as null

### Requirement: Own profile update
The system SHALL let the signed-in account change, through PATCH /users/me, only its own name, phone number, emergency contact name and phone, medical note, home address and work address, leaving every omitted field unchanged, and SHALL never change the email address, role or account status through this endpoint.

#### Scenario: Partial update
- **WHEN** the request supplies only some of the editable fields
- **THEN** only those fields are stored and the response is 200 with the full updated profile
- **AND** a request that also carries an email address, role or account status is rejected with 400 and nothing at all is stored

#### Scenario: Clearing an optional field
- **WHEN** an emergency contact name, emergency contact phone, medical note, home address or work address is sent as an empty value
- **THEN** that field is cleared

#### Scenario: Invalid values
- **WHEN** the name is shorter than 2 or longer than 100 characters, or a phone number is not 9 to 15 digits with an optional leading plus sign
- **THEN** the request is rejected with 400 and nothing is stored

### Requirement: Account reachability and contact uniqueness
The system SHALL keep every account reachable by at least one of an email address or a phone number, and SHALL keep phone numbers unique across accounts.

#### Scenario: Removing the only contact detail
- **WHEN** an account with no email address tries to remove its phone number
- **THEN** the request is rejected with 409 and the phone number is kept

#### Scenario: Phone number already in use
- **WHEN** the submitted phone number already belongs to another account
- **THEN** the request is rejected with 409

### Requirement: Customer garage listing
The system SHALL expose the vehicle garage at /users/me/vehicles to customer accounts only, and SHALL list a customer's own vehicles with the default vehicle first and the remaining vehicles oldest first.

#### Scenario: Customer lists vehicles
- **WHEN** a customer calls GET /users/me/vehicles
- **THEN** the response is 200 with that customer's vehicles, the default one first, then the others in the order they were added

#### Scenario: Non-customer account
- **WHEN** a provider or administrator account calls any garage endpoint
- **THEN** access is denied and no vehicle data is returned

### Requirement: Vehicle registration
The system SHALL add a vehicle to the signed-in customer's garage through POST /users/me/vehicles with a vehicle type, brand, model and licence plate and optionally a colour, tyre type, engine type and a request to make it the default, normalising the plate to upper case without spaces and keeping it unique across the whole platform.

#### Scenario: First vehicle becomes the default
- **WHEN** a customer adds a vehicle while the garage is empty, or asks for the new vehicle to be the default
- **THEN** the new vehicle is stored as the default and any previous default stops being the default
- **AND** the response is 201 with the stored vehicle, its tyre type defaulting to tubed and its engine type defaulting to electric for an electric motorbike and to gas otherwise

#### Scenario: Plate already registered
- **WHEN** the normalised licence plate already exists on any vehicle
- **THEN** the request is rejected with 409 and no vehicle is added

#### Scenario: Unusable vehicle data
- **WHEN** the vehicle type is not one of the supported types, or the licence plate is shorter than 4 or longer than 20 characters or contains characters other than letters, digits, dots and hyphens
- **THEN** the request is rejected with 400

### Requirement: Vehicle update and default selection
The system SHALL update only a vehicle that belongs to the signed-in customer through PATCH /users/me/vehicles/{vehicleId}, SHALL keep exactly one default vehicle in the garage at a time, and SHALL keep a motorbike's vehicle type and its engine type consistent with each other.

#### Scenario: Promoting another vehicle to default
- **WHEN** a customer marks one of its vehicles as the default
- **THEN** that vehicle becomes the default and the previous default is demoted in the same operation

#### Scenario: Unsetting the current default
- **WHEN** a customer tries to clear the default flag on the vehicle that is currently the default
- **THEN** the request is rejected with 409 and the customer is told to promote another vehicle instead

#### Scenario: Changing only the engine type of a motorbike
- **WHEN** a customer changes the engine type of a vehicle that is a motorbike or an electric motorbike, without sending a vehicle type
- **THEN** the vehicle type follows the new engine type, becoming an electric motorbike for an electric engine and a motorbike otherwise

#### Scenario: Vehicle of another customer
- **WHEN** the vehicle identifier does not belong to the signed-in customer
- **THEN** the response is 404

### Requirement: Vehicle removal
The system SHALL remove a vehicle of the signed-in customer through DELETE /users/me/vehicles/{vehicleId} and, when the removed vehicle was the default, SHALL promote the oldest remaining vehicle to default.

#### Scenario: Removing the default vehicle
- **WHEN** a customer deletes its default vehicle while other vehicles remain
- **THEN** the oldest remaining vehicle becomes the default
- **AND** the response reports the deletion and the identifier of the new default vehicle

#### Scenario: Removing the last vehicle
- **WHEN** a customer deletes its only vehicle
- **THEN** the garage is empty and the response reports the deletion with no new default vehicle
