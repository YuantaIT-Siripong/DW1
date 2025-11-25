# Audit Artifacts Standard

## Purpose
This document establishes the authoritative standard for implementing audit event fact tables across all domains in DW1. It ensures consistent event capture, sentinel defaults, integrity constraints, and auditability for dimension versioning and critical business actions.

## Scope
This standard applies to all audit fact tables that capture business events, state transitions, and regulatory actions:
- Profile versioning audit (customer, investment, company)
- Acknowledgement events (risk disclosures)
- Vulnerability assessments
- Supervisory overrides
- Future audit facts (backdated requests, fallback events)

## Design Principles

### 1. Append-Only Event Layer
- Audit facts are **append-only** (no updates, no deletes)
- Each event is immutable once written
- Corrections logged as new events with correction reason codes

### 2. Event Grain
- One row per business event occurrence
- Events linked to dimension versions via surrogate keys when applicable
- Natural keys ensure deduplication where business semantics allow

### 3. Separation of State vs Actions
- **Dimensions (SCD2)** store current and historical **state**
- **Audit Facts** capture **events** and **actions** that caused state changes
- Audit facts provide the "why" and "who"; dimensions provide the "what"

## Common Attributes

All audit fact tables MUST include the following core attributes:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `<entity>_sk` | BIGINT | Yes | Surrogate key (auto-generated) |
| `event_ts` | TIMESTAMP(6) | Yes | Business-effective timestamp of event |
| `event_detected_ts` | TIMESTAMP(6) | Yes | System timestamp when event was detected/ingested |
| `actor_id` | VARCHAR(100) | Yes | User/system identifier performing action (default: 'SYSTEM') |
| `actor_type` | VARCHAR(50) | Yes | HUMAN / SYSTEM / BATCH_JOB |
| `event_source_system` | VARCHAR(100) | Yes | Source system code (e.g., CRM, KYC, PORTAL) |
| `rationale_code` | VARCHAR(100) | Yes | Reason code (default: 'UNKNOWN' or domain-specific) |
| `event_hash` | VARCHAR(64) | Yes | SHA256 event content hash (default: '__PENDING__') |
| `event_hash_status` | VARCHAR(20) | Yes | PENDING / GENERATED (enforced via constraint) |
| `load_ts` | TIMESTAMP(6) | Yes | ETL ingestion timestamp |

## Sentinel Defaults

### Actor ID Default
```sql
actor_id VARCHAR(100) NOT NULL DEFAULT 'SYSTEM'
```
**Use Case**: Batch processes, automated versioning, system-initiated events

### Rationale Code Default
```sql
rationale_code VARCHAR(100) NOT NULL DEFAULT 'UNKNOWN'
```
**Domain-Specific Overrides**:
- Customer Profile: `'INITIAL_LOAD'`, `'SOURCE_UPDATE'`, `'CORRECTION'`, etc.
- Investment Profile: `'PROFILE_VERSION_CREATE'`, `'ACKNOWLEDGEMENT_RECEIVED'`, etc.

### Event Hash Default
```sql
event_hash VARCHAR(64) NOT NULL DEFAULT '__PENDING__',
event_hash_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
```
**Workflow**:
1. Events inserted with `event_hash = '__PENDING__'` and `event_hash_status = 'PENDING'`
2. Asynchronous hash generation job computes SHA256 hash
3. Hash job updates `event_hash` and sets `event_hash_status = 'GENERATED'`

## Integrity Constraints

### 1. Event Hash Constraint
```sql
CONSTRAINT ck_event_hash_status CHECK (
  (event_hash_status = 'PENDING' AND event_hash = '__PENDING__')
  OR (event_hash_status = 'GENERATED' AND event_hash != '__PENDING__' AND LENGTH(event_hash) = 64)
)
```

### 2. Chronological Order
```sql
CONSTRAINT ck_event_chronology CHECK (
  event_detected_ts >= event_ts OR rationale_code IN ('CORRECTION', 'BACKDATED')
)
```

### 3. Rationale Code Validation
All rationale codes MUST be documented in domain-specific enumerations (future: centralized `audit_event_types` enumeration file with versioning)

### 4. Uniqueness Constraints
Domain-specific uniqueness constraints applied based on business rules:
- Example (acknowledgement): `UNIQUE (investment_profile_id, ack_type, accepted_ts)`
- Example (profile audit): `UNIQUE (customer_id, profile_version_id_new)`

## Version Linkage

### Dimension Version Surrogate Keys
- Audit facts SHOULD reference dimension version surrogate keys when tracking state changes
- Version surrogate keys nullable for early events (backfill job will populate)
- Foreign key constraints ensure referential integrity

**Example (Customer Profile Audit)**:
```sql
profile_version_id_new BIGINT REFERENCES dim.dim_customer_profile(customer_profile_version_sk),
profile_version_id_old BIGINT REFERENCES dim.dim_customer_profile(customer_profile_version_sk)
```

### SCD2 Policy Alignment
Per [STANDARD_SCD2_POLICY.md](../../contracts/scd2/STANDARD_SCD2_POLICY.md):
- One `PROFILE_VERSION_CREATE` audit event per dimension version row (future enforcement)
- Audit event `event_ts` MUST match dimension `effective_start_ts`
- Profile hash in audit event MUST match dimension `profile_hash`

## Event Hash Algorithm

### Purpose
- Event content verification
- Deduplication detection
- Integrity checking for downstream consumers

### Hash Calculation
```
event_content_string = concatenate(
  business_key_1,
  business_key_2,
  event_ts (ISO 8601 seconds),
  rationale_code,
  actor_id,
  domain_specific_attributes (ordered alphabetically)
)
event_hash = SHA256(event_content_string)
```

**Excluded from Hash**:
- Surrogate keys (`*_sk`)
- `event_detected_ts` (varies with ingestion latency)
- `load_ts` (ETL metadata)
- `event_hash` field itself
- `event_hash_status` field

See [Hashing Standards](../data-modeling/hashing_standards.md) for complete SHA256 algorithm details.

## Monitoring and Quality

### Future Implementation (Separate PR)
- `vw_audit_quality_issues` monitoring view
- Alert on events with `event_hash_status = 'PENDING'` older than 1 hour
- Duplicate event hash detection (potential replay issues)
- Orphaned event records (foreign key violations after dimension deletes)

## Audit Fact Inventory

| Fact Table | Domain | Grain | Status |
|------------|--------|-------|--------|
| `fact_customer_profile_audit` | Customer | Profile change event | Implemented |
| `fact_investment_acknowledgement` | Investment | Acknowledgement acceptance event | Implemented |
| `fact_vulnerability_assessment` | Investment | Vulnerability classification event | Implemented |
| `fact_supervisory_override` | Investment | Override decision event | Implemented |
| `fact_profile_scope_fallback` | Investment | Scope fallback event | Future |
| `fact_backdated_request` | Cross-domain | Backdated correction request | Future |

## Related Documents
- [STANDARD_SCD2_POLICY.md](../../contracts/scd2/STANDARD_SCD2_POLICY.md) - SCD2 versioning rules and version linkage
- [ADR-AUDIT-001](../adr/ADR-AUDIT-001-audit-artifacts-standard.md) - Audit artifacts architecture decision
- [Hashing Standards](../data-modeling/hashing_standards.md) - SHA256 algorithm specification
- [Customer Module](../business/modules/customer_module.md) - Customer domain audit events
- [Investment Module](../business/modules/investment_profile_module.md) - Investment domain audit events


### Centralized Audit Event Types
Future PR will introduce `audit_event_types.yaml` with:
- Versioned enumeration of all rationale codes across domains
- Semantic groupings (PROFILE_CHANGE, REGULATORY, CORRECTION, etc.)
- Deprecation workflow for obsolete codes
- ADR update requirement for new event types

## Enumeration Management

Audit event types and rationale codes are centralized in `enumerations/audit_event_types.yaml` (enumeration_version: 2025.11.25-1).

Key fields per event_type:
- category, domain, requires_version_link, chronology_exception_allowed, requires_approval_reference, status_change_flag_applicable, lifecycle_status.

Key fields per rationale_code:
- category, lifecycle_status, notes.

Validation Rules (from enumeration file):
- Unknown codes rejected at ingestion (except controlled backfill).
- Chronology exceptions allowed only for configured event_types/rationale_codes (e.g., BACKDATED, CORRECTION, PERIODIC_REVIEW).
- Approval required event types (PROFILE_VERSION_CORRECTION, PROFILE_VERSION_BACKDATED_INSERT, SUPERVISORY_OVERRIDE) must include approval reference in future schema extensions.

Monitoring Targets (future view `vw_audit_quality_issues`):
- `event_hash_status='PENDING'` older than SLA threshold.
- UNKNOWN rationale_code usage > 2% monthly.
- Backdated events missing approval reference.


## Change Control
- Adding new audit fact tables requires ADR review
- Changes to sentinel defaults require this standard update + major version bump
- Integrity constraint modifications require backward compatibility analysis
- Enumeration additions require domain module spec update

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-25 | Initial audit artifacts standard | Data Architecture |
