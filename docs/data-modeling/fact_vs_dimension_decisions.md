# Fact vs Dimension Decisions (Phase 1)

| Entity | Grain | Classification | Notes |
|--------|-------|----------------|-------|
| Customer Profile Version | customer + version | Dimension (SCD2) | Demographics over time |
| Customer Profile Audit | change event | Fact (Audit) | Analyze change frequency |
| Service | service | Dimension | Metadata & scope |
| Service Category | category | Dimension | Lookup grouping |
| Subscribe Scope | scope level | Dimension | PERSON/CUSTOMER_CODE/ACCOUNT_CODE |
| Service Request | request | Fact | Lifecycle metrics |
| Service Subscription Event | status event | Fact | Approval / rejection / deactivation transitions |
| Income Source Version | profile version + income source | Bridge Dimension | Multi-valued set |
| Investment Purpose Version | profile version + purpose | Bridge Dimension | Multi-valued set |
