# ADR-AUDIT-001: Audit Artifacts Standard

## Status
Accepted

## Context
Gap 5 identified the lack of a unified, append-only audit event layer across customer and investment domains. Prior state:
- Minimal audit reference existed in `dim_customer_profile` contract
- No concrete fact tables for critical events (vulnerability, overrides, acknowledgements)
- No central standard for audit event capture
- Inconsistent sentinel defaults and integrity checks across potential audit implementations

The need for a standardized audit layer stems from:
1. **Regulatory Requirements**: SEC, FINRA, and internal compliance require immutable audit trails for suitability decisions, risk disclosures, and supervisory actions
2. **Dimension Reconstruction**: SCD2 dimensions record state changes; audit facts provide the "why" (rationale) and "who" (actor)
3. **Data Quality**: Orphaned dimension versions without corresponding audit events indicate ETL gaps
4. **Traceability**: Point-in-time queries against dimensions require correlation with event timestamps for complete context

## Decision
Adopt a unified audit artifacts standard with the following characteristics:

### 1. Append-Only Event Layer
- All audit facts are immutable (append-only, no updates/deletes)
- Corrections logged as new events with explicit correction reason codes
- Event grain: one row per business occurrence

### 2. Common Attribute Set
All audit fact tables include:
- Event surrogate key (auto-generated BIGINT)
- Event timestamp (`event_ts`, business-effective)
- Event detection timestamp (`event_detected_ts`, system ingestion)
- Actor identification (`actor_id`, `actor_type`)
- Source system (`event_source_system`)
- Rationale code (`rationale_code`)
- Event content hash (`event_hash`, `event_hash_status`)
- Load timestamp (`load_ts`)

### 3. Sentinel Defaults
- `actor_id` defaults to `'SYSTEM'` for automated processes
- `rationale_code` defaults to `'UNKNOWN'` (overrideable per domain)
- `event_hash` defaults to `'__PENDING__'` with `event_hash_status = 'PENDING'`
- Asynchronous hash generation job updates to computed SHA256 hash and status `'GENERATED'`

### 4. Integrity Constraints
- Event hash constraint enforces status/hash semantics
- Chronological constraint allows backdating only with explicit rationale codes
- Domain-specific uniqueness constraints (e.g., one acknowledgement per profile/type/timestamp)
- Foreign key constraints to dimension version surrogate keys (nullable for early events)

### 5. SCD2 Linkage Requirement
- One audit event per dimension version creation (future enforcement)
- Event `event_ts` matches dimension `effective_start_ts`
- Profile hash in event matches dimension `profile_hash`

### 6. Initial Audit Fact Tables
Implement four audit facts:
- **fact_customer_profile_audit**: Profile change events (INITIAL_LOAD, SOURCE_UPDATE, CORRECTION, etc.)
- **fact_investment_acknowledgement**: Risk disclosure acceptances (DERIVATIVE_RISK, FX_RISK, COMPLEX_PRODUCT)
- **fact_vulnerability_assessment**: Vulnerability classification events (assessment timestamp, reason codes)
- **fact_supervisory_override**: Override decisions for complex products, margin, etc.

### 7. Central Documentation
- **Audit Artifacts Standard**: `docs/audit/audit_artifacts_standard.md` (authoritative reference)
- **Module Specs Updated**: Customer and Investment module specs include concise Audit Events sections
- **AI_CONTEXT.md Updated**: Lists audit artifacts and clarifies state (dimensions) vs actions (audit facts) separation
- **SCD2 Policy Updated**: Notes audit linkage requirement for version creation events

## Implementation Directory Structure
```
contracts/audit/
  ├── fact_customer_profile_audit.yaml
  ├── fact_investment_acknowledgement.yaml
  ├── fact_vulnerability_assessment.yaml
  └── fact_supervisory_override.yaml

db/audit/
  ├── fact_customer_profile_audit.sql
  ├── fact_investment_acknowledgement.sql
  ├── fact_vulnerability_assessment.sql
  └── fact_supervisory_override.sql

docs/audit/
  └── audit_artifacts_standard.md
```

**Note**: Existing `db/audit/customer_profile_audit.sql` is a legacy schema; new DDL files follow unified standard.

## Alternatives Considered

### Alternative 1: Embed Audit Fields in Dimensions
**Rejected**: Violates separation of concerns; dimensions represent state, audit facts represent events. Embedding would:
- Inflate dimension row width
- Complicate SCD2 closure logic
- Prevent audit event replay/reconstruction workflows

### Alternative 2: Single Unified Audit Event Table
**Rejected**: Generic audit table (with JSON payload) would:
- Sacrifice type safety and referential integrity
- Complicate query performance (JSON extraction overhead)
- Lose domain-specific uniqueness constraints

### Alternative 3: No Hash Generation (Manual Hash Only)
**Rejected**: Sentinel `__PENDING__` approach provides:
- Graceful degradation (events written immediately, hash computed async)
- Quality monitoring (detect stalled hash generation)
- Backward compatibility (existing events without hashes can be backfilled)

## Consequences

### Positive
✅ Unified audit trail across all domains  
✅ Consistent sentinel defaults reduce ETL complexity  
✅ Integrity constraints prevent invalid events at write-time  
✅ Append-only design supports immutable regulatory compliance  
✅ Hash generation decoupled from event ingestion (performance)  
✅ Future-proof: enumeration versioning and monitoring views planned  

### Negative
⚠️ Hash generation delays create temporary `PENDING` state (mitigated by monitoring view in future PR)  
⚠️ Multiple audit fact tables increase schema complexity (mitigated by central standard documentation)  
⚠️ Enumeration drift risk (mitigated by versioned central standard + future `audit_event_types.yaml`)  

### Neutral
📊 Downstream consumers require new joins to audit facts for complete context  
📊 Replay tooling for dimension reconstruction deferred to future PR  

## Risks & Mitigations
| Risk | Mitigation |
|------|------------|
| Downstream confusion about new tables | Clear documentation in AI_CONTEXT.md and module specs |
| Hash generation delays (`PENDING` too long) | Provide `vw_audit_quality_issues` monitoring view (future PR) |
| Enumeration drift (rationale codes proliferate) | Central standard + ADR ensures versioned change control; future `audit_event_types.yaml` |
| Orphaned dimension versions (no audit event) | Foreign key constraints + quality rules detect gaps |

## Follow-Up Tasks (Future PRs)
1. **Enumeration File**: Create `audit_event_types.yaml` with versioned rationale codes
2. **Monitoring View**: Implement `vw_audit_quality_issues` for hash status, orphaned events
3. **Backfill Audit**: Populate missing version linkage (nullable foreign keys)
4. **Replay Tooling**: Dimension reconstruction from audit fact replay
5. **Additional Facts**: `fact_profile_scope_fallback`, `fact_backdated_request`

## Compliance Alignment
- **SEC Rule 17a-4**: Audit facts provide immutable records for suitability decisions (WORM-compliant storage planned)
- **FINRA Rule 4511**: Supervision override events logged with supervisor identity and timestamp
- **Internal Policy**: Vulnerability assessment events support "know your customer" obligations

## Related Policies and Standards
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md) - Version linkage requirements
- [Audit Artifacts Standard](../audit/audit_artifacts_standard.md) - Authoritative implementation guide
- [Hashing Standards](../data-modeling/hashing_standards.md) - SHA256 event hash algorithm
- [Customer Module](../business/modules/customer_module.md) - Customer audit events
- [Investment Module](../business/modules/investment_profile_module.md) - Investment audit events

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-25 | Initial ADR for audit artifacts standard | Data Architecture |
