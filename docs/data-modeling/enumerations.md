# Core Enumerations (Unified)

This file consolidates enumeration domains used across Customer and Investment modules.

## Domains
- MaritalStatus
- Nationality
- Occupation
- EducationLevel
- SourceOfIncome
- PurposeOfInvestment
- ContactChannel
- RiskLevel
- AbilityToBearLoss
- InvestmentObjective
- InvestmentTimeHorizon
- LiquidityNeed
- HNWStatus
- KYCStatus
- KYCRiskRating
- AMLRiskRating
- SanctionScreeningStatus
- FATCAStatus
- InvestorCategory
- SourceOfWealth
- VulnerabilityReason
- MarginAgreementStatus
- LeverageTolerance
- ESGPreference (optional)
- TaxResidencyStatus
- ReviewCycle

Detailed investment-specific definitions remain in:
- docs/data-modeling/investment-profile/enumerations.md

Enumeration governance:
| Rule | Description |
|------|-------------|
| Addition requires approval | Compliance + Data Governance ticket |
| Deprecation | Mark deprecated flag; never delete historical codes |
| UNKNOWN | Present for early ingestion when value not collected |
| ENUM_VERSION | Bump when any domain changes (add/remove/semantic change) |

ENUM_VERSION: 2025.11.25-2

Change Notes:
- 2025.11.25-2 Added reference to centralized audit event enumeration file (audit_event_types.yaml).