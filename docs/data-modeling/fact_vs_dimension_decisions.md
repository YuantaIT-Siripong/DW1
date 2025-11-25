# Fact vs Dimension Decision Matrix (Phase 1 Expanded)

## Purpose
Provide a consistent framework to decide whether a business concept becomes:
- Dimension (Type 1)
- Dimension (SCD2)
- Bridge Dimension (multi-valued set membership)
- Fact
- Audit Fact (event/action lineage)
- Reference / Lookup Dimension
- Gold / Mart View (derived analytics layer)

This matrix reduces modeling drift, supports predictable queries, and clarifies how time variance and events are captured.

## Core Concepts

| Concept | Stores | Mutability | Typical Grain | Examples |
|---------|--------|-----------|---------------|----------|
| Type 1 Dimension | Current state only | Overwritten | Business key | dim_service, dim_service_category |
| SCD2 Dimension | Historical state versions | Append-only (new version rows) | Business key + version interval | dim_customer_profile, dim_investment_profile_version |
| Bridge Dimension | Many-to-many membership snapshot per version | Re-written only when set changes | Version surrogate key + member key | dim_customer_income_source_version |
| Fact Table | Measurable events or transactions | Append-only | Business event or transaction key | fact_service_request |
| Audit Fact | State-change causation & rationale | Append-only | One row per event/action causing or describing a state transition | fact_customer_profile_audit, fact_investment_acknowledgement |
| Lookup / Reference | Enumerated codes & descriptions | Slowly updated (overwrite) | Code value | dim_marital_status |
| Gold/Mart View | Aggregated / derived metrics | Rebuilt (ephemeral) | Reporting grain | mart_profile_quality (future) |

## Decision Dimensions

1. Time Variance
   - Do stakeholders query past states? → SCD2 Dimension.
   - Only current state needed? → Type 1 Dimension.
   - Need sequence of discrete actions (who/why)? → Audit Fact.

2. Cardinality / Multiplicity
   - Single value per entity version → Store as attribute in dimension.
   - Multi-valued set needing membership logic → Bridge Dimension + set hash.

3. Event vs State
   - Stable snapshot at a point in time → Dimension.
   - Event that occurred (ack accepted, override decision) → Audit Fact.
   - Operational transaction (service request) → Fact.

4. Rationale & Actor
   - Must capture initiator, reason, hash for integrity → Audit Fact (not in SCD2 row).
   - Pure state without need for actor/rationale → SCD2 or Type 1.

5. Historical Reconstruction
   - Need to rebuild state timeline from atomic events? → Audit Facts complement SCD2.
   - SCD2 alone sufficient if business wants direct state intervals only.

6. Derived Metrics
   - Score subject to recalculation → Gold layer view (do NOT store in SCD2).
   - Immutable scalar driving business state gating? → Include in SCD2 hash fields.

7. Change Detection Method
   - Attribute-level changes tracked via hash → SCD2 Dimension + audit event row.
   - Set membership changes → Bridge table + versioning logic (no separate fact unless action semantics important).
   - Complex workflow decisions (override approval) → Audit Fact.

8. Query Pattern
   - Point-in-time state: filter SCD2 intervals.
   - Event timeline analysis: audit fact sequence.
   - Aggregated metrics (counts, latency): fact tables.
   - Set membership queries: bridge join on version surrogate key.

## Decision Matrix

| Question | YES → | NO → | Notes |
|----------|-------|------|-------|
| Do we need point-in-time historical state of attributes? | SCD2 Dimension | Type 1 Dimension | SCD2 if regulatory or suitability relevance. |
| Are multiple values selectable per version (list membership)? | Bridge Dimension + SCD2 | Regular attributes | Hash set triggers version creation. |
| Is the data an event with actor/rationale? | Audit Fact | Fact (if numeric metrics only) | Actor/rationale differentiate audit fact. |
| Is it a transactional measure (quantities, durations)? | Fact Table | Dimension | Facts can link to dimensions for attributes. |
| Will derived metric changes produce noise if stored? | Store in Gold view | Store in SCD2 | Exclude derived metrics from SCD2 (policy). |
| Must we replay events to rebuild dimension? | Keep Audit Fact | Optional (only SCD2) | Replay tool future enhancement. |
| Does a value drive version change detection? | Include in hash fields | Keep as Type 1 attribute | See hashing_standards.md. |
| Is there business meaning for each distinct action? | Separate Audit Fact | Just version row | Avoid stuffing actions into dimension row. |

## Classification Examples (Expanded)

| Entity / Concept | Recommended Artifact | Rationale |
|------------------|----------------------|-----------|
| Customer profile state | SCD2 Dimension (dim_customer_profile) | Regulated historical demographics & suitability context. |
| Customer profile change event | Audit Fact (fact_customer_profile_audit) | Captures reason, actor, attribute diff lists. |
| Investment profile state | SCD2 Dimension (dim_investment_profile_version) | Time-variant eligibility, vulnerability, acknowledgements. |
| Acknowledgement acceptance | Audit Fact (fact_investment_acknowledgement) | Separate event; expiry & channel tracked. |
| Vulnerability assessment | Audit Fact (fact_vulnerability_assessment) | Action with assessor role, method, status change. |
| Supervisory override decision | Audit Fact (fact_supervisory_override) | Compliance needs who/why/conditions. |
| Income sources per profile version | Bridge Dimension (dim_customer_income_source_version) | Multi-valued set membership affecting hash. |
| Service metadata | Type 1 Dimension (dim_service) | Current definitions; historical tracking not required. |
| Service subscription request | Fact (fact_service_request) | Transaction lifecycle metrics (approval latency). |
| Fallback usage (profile scope) | Audit Fact (future fact_profile_scope_fallback) | Event indicating reliance on broader scope baseline. |
| Reliability score (future) | Gold View (mart_profile_quality) | Derived metric; exclude from SCD2 to avoid churn. |
| Margin agreement status (time-variant) | SCD2 attribute | Business gating value requiring history for trades. |

## Multi-Valued Sets Guidance

Use bridge dimension pattern when:
- Need to query each member independently (joins, filters).
- Changes in membership trigger new SCD2 versions.
- Need deterministic hashing for change detection.

Pattern:
- Bridge table keyed by `<profile_version_sk, member_code>`
- Member set hash computed (sorted, deduplicated)
- Stored in parent SCD2 dimension to participate in profile hash.

Avoid:
- Storing raw arrays/CSV strings in SCD2 dimension for membership queries.
- Embedding membership change rationale in dimension row (belongs in audit fact only if membership change has distinct action semantics beyond state change).

## Audit Fact vs Non-Audit Fact Distinction

| Aspect | Audit Fact | Regular Fact |
|--------|------------|--------------|
| Purpose | Explain state change, capture action | Measure transactional process |
| Includes actor/rationale | Yes | Optional / Usually no |
| Hash usage | Event content hash for integrity | Rare (maybe deduplication) |
| Links to version surrogate keys | Often (state linkage) | Usually foreign keys to dimensions, not specifically new versions |
| Replay dimension history | Facilitates | Not primary purpose |

## Anti-Patterns & Corrections

| Anti-Pattern | Why Problematic | Correct Approach |
|--------------|-----------------|------------------|
| Embedding rationale_code in SCD2 dimension row | Mixes action semantics with state; duplication | Store rationale_code in audit fact row only. |
| Including derived scores (reliability_score) in hash fields | Causes spurious versions | Exclude derived metrics; compute in gold layer. |
| Storing multi-valued member list as comma-separated string | Difficult to join/filter; non-deterministic ordering | Bridge dimension + set hash. |
| Using single generic audit table with JSON payload | Loss of constraints & type safety | Domain-specific audit fact tables. |
| Backdating by updating existing version row | Breaks immutability & historical accuracy | Insert new version + audit correction event. |
| Omitting actor_id for override decisions | Compliance gap | Include actor_id + supervisor role in audit fact. |

## Checklist (Pre-Modeling Review)

Before finalizing a new artifact, confirm:
- [ ] Grain explicitly documented.
- [ ] Time variance requirement understood.
- [ ] State vs action separation evaluated.
- [ ] Multi-valued attributes isolated into bridge where needed.
- [ ] Hash fields list excludes derived metrics.
- [ ] If audit fact: actor_id, actor_type, rationale_code, event_hash, event_hash_status defined.
- [ ] Naming patterns align with naming_conventions.md.
- [ ] Enumerations referenced exist (or will be added) and version bump considered.
- [ ] No historical mutation required (append-only confirmed for SCD2/audit facts).
- [ ] Approval/reference fields planned for events needing governance (e.g., corrections, overrides).

## Rapid Decision Flow (Pseudo-Algorithm)

```text
IF concept describes a persistent entity state over time THEN
    IF historical states needed THEN SCD2 Dimension
    ELSE Type 1 Dimension
ELSE IF concept is a discrete business action affecting state THEN
    Audit Fact
ELSE IF concept is a transactional process needing metrics THEN
    Fact
ENDIF

IF attribute has multiple simultaneous members with change detection importance THEN
    Bridge Dimension + include set_hash in parent SCD2
ENDIF

IF metric derived from other attributes and recalculated periodically THEN
    Gold/Mart View (exclude from SCD2 + hashing)
ENDIF
```

## Cross-Links
- Standard SCD2 Policy: contracts/scd2/STANDARD_SCD2_POLICY.md
- Hashing Standards: docs/data-modeling/hashing_standards.md
- Naming Conventions: docs/data-modeling/naming_conventions.md
- Audit Artifacts Standard: docs/audit/audit_artifacts_standard.md
- Audit Event Enumeration: enumerations/audit_event_types.yaml
- AI Context: AI_CONTEXT.md

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-25 | Initial minimal table (legacy) | Data Architecture |
| 1.1 | 2025-11-25 | Expanded decision matrix, anti-patterns, checklist | Data Architecture |
