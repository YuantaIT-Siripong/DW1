# Thread Handover Guide

## Purpose
Enable any new AI/Copilot session (thread) to immediately continue DW1 modeling and audit work without re-discovering prior decisions.

## Read First (Order)
1. AI_CONTEXT.md (overview + authoritative links)
2. CONTEXT_MANIFEST.yaml (machine index of critical files & versions)
3. fact_vs_dimension_decisions.md (pattern & classification matrix)
4. enumerations/audit_event_types.yaml (event_type & rationale_code taxonomy)
5. docs/audit/audit_artifacts_standard.md (implementation standard)

## Current State Snapshot
- Audit fact tables implemented: customer_profile_audit, investment_acknowledgement, vulnerability_assessment, supervisory_override.
- Enumeration file live: audit_event_types.yaml (version 2025.11.25-1).
- Decision matrix expanded (fact vs dimension).
- Legacy customer_profile_audit legacy table deprecated/removed.
- SCD2 policy updated with audit linkage requirement.

## Active Backlog (High Priority)
| Item | Goal | Notes |
|------|------|-------|
| vw_audit_quality_issues | Monitor stale hashes, UNKNOWN rationale usage | Requires event aging threshold constant |
| Fallback event design (fact_profile_scope_fallback) | Explicitly log scope fallback usage | Clarify KPI & gating logic |
| Approval reference pattern | Store link/ID for correction/override approvals | Might add approval_reference_id (nullable) |
| Enumeration deprecation stub | Demonstrate lifecycle_status=DEPRECATED mechanics | Add one test code & replacement |
| Monitoring thresholds in standard | Formalize UNKNOWN <=2% monthly | Add to audit standard + manifest |

## Key Modeling Rules (Quick Recap)
- SCD2 stores state; audit facts store actions (no rationale_code in dimensions).
- Derived metrics (scores) excluded from SCD2 + hash fields (gold layer only).
- Multi-valued sets modeled via bridge tables + set hash (no CSV in dimensions).
- Event hashes use sentinel '__PENDING__' then asynchronous generation.
- Backdated or corrective events allowed only if enumeration flags chronology_exception_allowed.

## Open Questions
1. Fallback Event Emission: Emit only when trade decision references baseline? Or on profile lookup failure scenario?
2. Approval Reference: Single textual field or foreign key to approval dimension?
3. Monitoring View KPI thresholds: Are 1 hour & 2% appropriate for initial alerts?
4. Scope of deprecation process: Do we require immediate replacement_code for every deprecation?

## Suggested Next Steps for New Thread
1. Draft SQL for vw_audit_quality_issues (include hash age, UNKNOWN ratio, orphan version detection).
2. Propose schema extension for approval_reference_id on relevant audit facts.
3. Define conditions for SCOPE_FALLBACK_USED emission (business rules table).
4. Add sample DEPRECATED rationale_code entry to audit_event_types.yaml (version bump).

## Reference Pointers
- Hash algorithm & exclusions: hashing_standards.md, STANDARD_SCD2_POLICY.md.
- Enumeration governance: audit_event_types.yaml (change_control block).
- Decision logic: fact_vs_dimension_decisions.md.

## Contribution Checklist
- Update CONTEXT_MANIFEST.yaml when adding new standard/ADR.
- Bump enumeration_version and ENUM_VERSION together.
- Add Change Log entry in each modified standard document.
- Ensure new audit facts follow sentinel defaults and integrity constraints.

## Contact / Review Roles
- Data Architecture: Design approval
- Compliance: Override & vulnerability rationale validation
- Domain Leads: Customer & Investment semantics
- Data Quality: Monitoring thresholds & alert logic

## Do Not
- Add derived scores to SCD2 dimensions.
- Introduce new event_type/rationale_code without enumeration update.
- Mutate existing version rows for corrections (insert new + audit event).
- Store multi-valued sets as delimited strings.

End of Handover Guide.