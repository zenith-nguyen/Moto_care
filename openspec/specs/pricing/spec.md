# Pricing Specification

## Purpose
Defines how the price of a rescue order is quoted before the customer pays: the published base price of the chosen incident type, a weather-aware surcharge derived from the conditions at the customer's location, and the resulting estimated price. It also defines the weather observation that backs that surcharge and how the whole quote is frozen onto the order. It does not define how the quoted amount is collected, how a final price is later proposed or approved, or how a mechanic is paid.

## Requirements

### Requirement: An order price is quoted from a base price and a weather multiplier
The system SHALL compute the estimated price of an order as the active incident type's base price multiplied by a weather multiplier, SHALL perform the whole computation in integer minor currency units rather than floating point, SHALL round the result to the nearest minor unit with halves rounded up, and SHALL report the base price, the estimated price, the weather surcharge (estimated price minus base price) and the multiplier applied.

#### Scenario: A quote is produced for an incident type
- **WHEN** a price is quoted for an incident type at a location
- **THEN** the base price, the estimated price, the weather surcharge and the four-decimal multiplier are returned together with the weather observation used
- **AND** the estimated price equals the base price when the multiplier is neutral, so the surcharge is zero

#### Scenario: The multiplied amount falls between two minor units
- **WHEN** applying the multiplier produces a fraction of a minor currency unit
- **THEN** the estimated price is the nearest whole minor unit, with an exact half rounded up

### Requirement: The weather severity band selects the multiplier
The system SHALL classify the observed conditions into a severity band and SHALL apply a fixed multiplier per band: no surcharge for normal conditions, a ten percent surcharge for moderate conditions and a twenty percent surcharge for severe conditions.

#### Scenario: Conditions are moderate
- **WHEN** the observation reports light precipitation, a wet weather code or moderate wind
- **THEN** the band is moderate and the estimated price is ten percent above the base price

#### Scenario: Conditions are severe
- **WHEN** the observation reports a storm or heavy-rain weather code, heavy precipitation, or strong sustained wind or gusts
- **THEN** the band is severe and the estimated price is twenty percent above the base price

### Requirement: Severity is classified from a current-conditions observation at the order location
The system SHALL obtain the current weather for the customer's coordinates from the configured external current-conditions provider, SHALL require weather code, temperature, precipitation, rain and wind readings to all be present and within plausible ranges before using an observation, and SHALL report with each quote which provider the observation came from and when it was observed.

#### Scenario: The provider returns a complete observation
- **WHEN** the provider answers within the configured request timeout with all required readings
- **THEN** the observation is classified into a severity band and reported with its source and observation time

#### Scenario: The provider answers with an incomplete or implausible reading
- **WHEN** a required reading is missing, is not a finite number or falls outside its plausible range
- **THEN** the observation is discarded and the quote falls back to neutral pricing

### Requirement: Pricing stays neutral when live weather is off or unreachable
The system SHALL treat weather pricing as switched off unless it is explicitly enabled in configuration, SHALL fall back to a neutral observation whenever the provider errors out, times out or returns a non-success response, and SHALL never fail order creation because of weather. A neutral observation SHALL carry no measurements and SHALL produce a multiplier of one.

#### Scenario: Weather pricing is not enabled
- **WHEN** a quote is requested while weather pricing is disabled in configuration
- **THEN** the observation is reported as disabled with no measurements and the estimated price equals the base price

#### Scenario: The weather provider is unreachable
- **WHEN** the request to the provider fails or exceeds the configured timeout
- **THEN** the observation is reported as unavailable with no measurements and the estimated price equals the base price

### Requirement: Observations are cached per approximate location
The system SHALL cache each observation under the customer's coordinates rounded to two decimal places for the configured time to live, SHALL reuse a cached observation that has not expired instead of calling the provider again, and SHALL keep the cache bounded by discarding the oldest entry once it is full.

#### Scenario: A second order is quoted nearby within the cache window
- **WHEN** another quote is requested for coordinates that round to the same two decimal places before the cached entry expires
- **THEN** the cached observation is reused and no new provider request is made

#### Scenario: The cached observation has expired
- **WHEN** the cached entry's time to live has passed
- **THEN** it is discarded and a fresh observation is requested

### Requirement: The quote is frozen onto the order
The system SHALL store, on the order at creation time, the quoted base price, estimated price, weather surcharge and multiplier together with the severity band, the observation source, the observation time, the weather code and the precipitation and wind measurements that justified the surcharge, so the price charged can be explained later without re-querying the provider.

#### Scenario: An order is created from a quote
- **WHEN** an order is created for an active incident type at a location
- **THEN** the order carries the full pricing breakdown and the weather evidence behind it
- **AND** the prepayment opened for that order is for the stored estimated price

### Requirement: Current weather is readable on its own
The system SHALL expose the current-conditions observation for a valid latitude and longitude at `GET /weather/current`, returning the same observation shape that pricing uses, including the neutral fallback when live weather is disabled or unavailable.

#### Scenario: A client reads current conditions
- **WHEN** an authenticated client calls `GET /weather/current` with a valid latitude and longitude
- **THEN** the current observation is returned with its severity band and source
