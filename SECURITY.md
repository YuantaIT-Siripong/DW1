# Security Policy (Placeholder)

## Reporting
Report suspected vulnerabilities to security@example.local (placeholder).

## Data Classification
- PII columns masked in non-privileged views (future ADR).
- Sensitive suitability fields (vulnerable_investor_flag, pep_flag, sanction_screening_status) governed by role-based access.

## Next Steps
1. Define column-level masking strategy.
2. Add automated secret scan in CI.
3. Introduce ADR for security & masking (Phase 2).