# Investment Profile Module (Concept & Clarification Document)

## Status
This version reflects decisions:
- Minimal acknowledgement handling (flags only; language/text external).
- Workflow / Evidence module deferred.
- Consent artifact references deferred.
- Vulnerability fields ADDED (VulnerableInvestorFlag, VulnerabilityReasonCode, VulnerabilityAssessmentTs).

## Purpose
Define a flexible, auditable Investment Profile domain (dimension + related bridges) for Yuanta Thailand capturing suitability, risk, regulatory statuses, product entitlements, vulnerability status, and acknowledgement completion flags. Excludes calculation engines, form answers, and raw evidentiary artifacts.

## Scope
IN: Final suitability score, risk level, KYC/AML statuses, investor category, vulnerability status, net worth classification, experience, product eligibility flags, acknowledgement flags.
OUT: Raw consent documents, language versions, disclosure text, detailed workflow case processing, questionnaire answers, algorithms.

## Separation of Concerns
- Investment Profile: Conformed SCD2 dimension for analytic/reporting/regulatory snapshots.
- Deferred Workflow Module: Manages documents, languages, evidentiary artifacts, form submissions.
- Acknowledgements here are boolean/status flags only.

## Core Business Concepts
| Concept | Definition |
|---------|------------|
| Investment Profile | Time-variant snapshot of client’s approved investment posture. |
| Suitability Score | External numeric or tier result. |
| Risk Level | Investment risk tolerance classification. |
| AbilityToBearLossTier | Financial capacity to absorb losses (distinct from risk appetite). |
| VulnerableInvestorFlag | Indicates client requires enhanced protection measures. |
| VulnerabilityReasonCode | Reason category explaining vulnerability classification. |
| InvestmentObjectiveCategory | Primary investment goal. |
| InvestmentTimeHorizon | Duration expectation for investment strategy. |
| LiquidityNeedLevel | Urgency for accessible funds. |
| High Net Worth Status | NONE/HNW/UHNW classification. |
| KYC/AML/FATCA Statuses | Regulatory compliance lifecycle indicators. |
| InvestorCategory | Regulatory segmentation (RETAIL/PROFESSIONAL/INSTITUTIONAL). |
| SourceOfWealthCode | Origin of client wealth (categorical). |
| Product Eligibility | Permissions per product category. |
| Acknowledgement Flags | Boolean indicators risk disclosures acknowledged. |
| RiskQuestionnaireVersion | Internal version identifying questionnaire used. |
| ProfileReliabilityScore | Composite trust metric (quality * compliance factors). |
| DataQualityScore | Attribute completeness/validity score. |

## High-Level Entity Groups
1. Dimension Core (SCD2): dim_investment_profile, dim_investment_profile_version  
2. Reference Dimensions: risk, HNW, investor category, source of wealth, product category, assessment master/version, questionnaire version  
3. Fact / Bridges: assessment outcomes, acknowledgements, product eligibility, restricted products, tax documents  
4. Audit: profile events  

## Product Category Codes (Thailand Focus)
EQUITY, TFEX, DW, DRX, ETF, INVERSE_ETF, FUND, GLOBAL_EQUITY, STRUCTURED_NOTE_LOCAL, STRUCTURED_NOTE_GLOBAL, BOND, PERPETUAL_BOND, FIXED_INCOME_OTHER, SBL, BLOCK_TRADE, IPO, TENDER_OFFER

## Enumerations (Include UNKNOWN)
InvestmentObjectiveCategory:
CAPITAL_PRESERVATION | INCOME | GROWTH | SPECULATION | HEDGING | RETIREMENT | TAX_EFFICIENCY | EDUCATION_FUNDING | OTHER | UNKNOWN

InvestmentTimeHorizon:
SHORT | MEDIUM | LONG | UNKNOWN

AbilityToBearLossTier:
LOW | MODERATE | HIGH | UNKNOWN

LiquidityNeedLevel:
LOW | MEDIUM | HIGH | UNKNOWN

FATCAStatus:
NOT_APPLICABLE | PENDING_SELF_CERT | CERTIFIED | REPORTED | EXPIRED | UNKNOWN

InvestorCategory:
RETAIL | PROFESSIONAL | INSTITUTIONAL | UNKNOWN

HighNetWorthStatus:
NONE | HNW | UHNW | UNKNOWN

KYCStatus:
PENDING | IN_PROGRESS | VERIFIED | EXPIRED | UNKNOWN

KYCRiskRating / AMLRiskRating:
LOW | MEDIUM | HIGH | UNKNOWN

RiskLevelCode (example):
CONSERVATIVE | MODERATE | BALANCED | GROWTH | AGGRESSIVE | SPECULATIVE | UNKNOWN

SourceOfWealthCode:
SALARY | BUSINESS_INCOME | INVESTMENT_PORTFOLIO | INHERITANCE | RENTAL_INCOME | OTHER | UNKNOWN

VulnerabilityReasonCode:
ELDERLY_HIGH_COGNITIVE_RISK | DISABILITY_SUPPORT_NEEDED | LOW_FINANCIAL_LITERACY | RECENT_BEREAVEMENT | SERIOUS_ILLNESS | TEMPORARY_DISTRESS | OTHER | UNKNOWN

MarginAgreementStatus:
NOT_SIGNED | ACTIVE | EXPIRED | SUSPENDED

LeverageTolerance:
NONE | LIMITED | HIGH | UNKNOWN

ESGPreference:
NONE | MODERATE | STRONG | UNKNOWN

TaxResidencyStatus:
PRIMARY | MULTI | UNKNOWN

ReviewCycle:
ANNUAL | BIENNIAL | EVENT_DRIVEN | UNKNOWN

SanctionScreeningStatus:
CLEAR | HIT_PENDING_REVIEW | REJECTED | UNKNOWN

## dim_investment_profile_version Attributes (Vulnerability Fields Added)
| Attribute | Notes |
|-----------|-------|
| InvestmentProfileVersionSK | Surrogate key |
| InvestmentProfileId | FK |
| VersionNumber | Sequential |
| EffectiveStartTs / EffectiveEndTs | SCD2 window |
| ScopeType | CUSTOMER / CUSTOMERCODE |
| CustomerId / CustomerCode | Binding |
| OverrideIndicator | True if code-level override |
| SuitabilityScore | Numeric |
| SuitabilityTier | Derived tier (optional) |
| RiskLevelCode | FK risk classification |
| AbilityToBearLossTier | Added |
| InvestmentObjectiveCategory | Added |
| InvestmentTimeHorizon | Added |
| LiquidityNeedLevel | Added |
| HighNetWorthStatusCode | |
| KYCStatus | |
| KYCRiskRating | |
| AMLRiskRating | |
| PEPFlag | Boolean |
| SanctionScreeningStatus | |
| FATCAStatus | |
| InvestorCategory | |
| SourceOfWealthCode | |
| InvestmentExperienceYears | |
| RiskQuestionnaireVersion | Pattern RISK_Q_YYYYMMnn |
| QuestionnaireCompletionTs | Timestamp (optional) |
| GlobalTradingAllowed | Boolean |
| DerivativeTradingAllowed | Boolean |
| ComplexProductAllowed | Boolean |
| StructuredNoteAllowed | Boolean |
| SBLAllowed | Boolean |
| BlockTradeAllowed | Boolean |
| IPOParticipationAllowed | Boolean |
| TenderOfferParticipationAllowed | Boolean |
| FixedIncomeAccessAllowed | Boolean |
| DerivativeRiskAcknowledgedFlag | Boolean |
| FXRiskAcknowledgedFlag | Boolean |
| ComplexProductAcknowledgedFlag | Boolean |
| MarginAgreementStatus | ENUM |
| LeverageTolerance | ENUM |
| ESGPreference | ENUM |
| TaxResidencyStatus | ENUM |
| ReviewCycle | ENUM |
| NextReviewDueTs | |
| LastRiskReviewTs | |
| VulnerableInvestorFlag | Boolean (new) |
| VulnerabilityReasonCode | ENUM, nullable if flag false |
| VulnerabilityAssessmentTs | Timestamp of classification |
| ProfileReliabilityScore | 0–1 |
| DataQualityScore | 0–1 |
| AdvisoryDiscretionFlag | Boolean |
| SourceSystem | Upstream identifier |
| SourceExtractReference | Batch/event ID |
| CreatedAtTs | DW creation timestamp |
| CreatedBy | Process/user |
| IngestionBatchId | ETL run ID |

## Vulnerability Handling
- VulnerableInvestorFlag = TRUE triggers stricter gating (e.g., block SPECULATIVE / highly leveraged entitlements unless supervisory override).
- VulnerabilityReasonCode documents rationale.
- VulnerabilityAssessmentTs logs when classification was last confirmed.
- UNKNOWN reason penalizes ProfileReliabilityScore if flag TRUE.

## Acknowledgement Integration (Minimal)
Only boolean flags stored; detailed consent artifacts remain in deferred workflow system.

## Fact Table (Acknowledgements)
| Field | Notes |
|-------|-------|
| AcknowledgementRecordId | PK |
| InvestmentProfileVersionSK | Snapshot context |
| AcknowledgementTypeCode | DERIVATIVE_RISK / FX_RISK / COMPLEX_PRODUCT |
| AcceptedTs | Timestamp |
| ExpiresTs | Nullable |
(No language/text version now.)

## Vulnerability Impact Rules (Illustrative)
| Rule | Condition | Action |
|------|-----------|--------|
| Block Speculative Products | VulnerableInvestorFlag=TRUE AND RiskLevelCode IN (SPECULATIVE, AGGRESSIVE) | Set respective product eligibility NOT_ALLOWED unless supervisory override |
| Shorten Review Cycle | VulnerableInvestorFlag=TRUE | nextReviewDueTs = MIN(nextReviewDueTs, LastRiskReviewTs + INTERVAL '6 months') |
| Reliability Penalty | VulnerableInvestorFlag=TRUE AND VulnerabilityReasonCode=UNKNOWN | reliabilityPenalty += 0.1 |

## Reliability & Data Quality (Including Vulnerability)
DataQualityScore = completeness_pct - stale_penalties  
ProfileReliabilityScore = DataQualityScore * (1 - sanctionsPenalty) * (1 - pepPenalty) * timelinessFactor * consistencyFactor * (1 - vulnerabilityPenalty)  
vulnerabilityPenalty example: 0.05 if flag TRUE and reason known; 0.15 if reason UNKNOWN.

## Sample JSON (Vulnerability Example)
```json
{
  "investmentProfileId": "ip-8899",
  "currentVersion": {
    "versionNumber": 13,
    "effectiveStartTs": "2025-11-19T12:00:00Z",
    "riskLevelCode": "BALANCED",
    "abilityToBearLossTier": "MODERATE",
    "investmentObjectiveCategory": "INCOME",
    "investmentTimeHorizon": "MEDIUM",
    "liquidityNeedLevel": "MEDIUM",
    "suitabilityScore": 76,
    "highNetWorthStatusCode": "NONE",
    "kycStatus": "VERIFIED",
    "kycRiskRating": "LOW",
    "amlRiskRating": "LOW",
    "pepFlag": false,
    "sanctionScreeningStatus": "CLEAR",
    "fatcaStatus": "NOT_APPLICABLE",
    "investorCategory": "RETAIL",
    "sourceOfWealthCode": "SALARY",
    "investmentExperienceYears": 4,
    "riskQuestionnaireVersion": "RISK_Q_20250101_01",
    "globalTradingAllowed": false,
    "derivativeTradingAllowed": false,
    "complexProductAllowed": false,
    "structuredNoteAllowed": false,
    "derivativeRiskAcknowledgedFlag": false,
    "fxRiskAcknowledgedFlag": true,
    "complexProductAcknowledgedFlag": false,
    "vulnerableInvestorFlag": true,
    "vulnerabilityReasonCode": "LOW_FINANCIAL_LITERACY",
    "vulnerabilityAssessmentTs": "2025-11-18T09:30:00Z",
    "nextReviewDueTs": "2026-05-18T00:00:00Z",
    "profileReliabilityScore": 0.84,
    "dataQualityScore": 0.90
  }
}
```

## Open Questions (Updated)
| # | Question | Impact |
|---|----------|--------|
| 1 | Supervisory override logic for vulnerable investors? | Entitlement gating |
| 2 | Minimum review interval when VulnerableInvestorFlag=TRUE (6 months vs 12)? | Scheduling |
| 3 | Should vulnerability changes always force new profile version? | Version volume |
| 4 | Need multi-valued vulnerability reasons? | Additional bridge table |
| 5 | Penalty weights for reliability scoring—regulatory input needed? | Scoring calibration |
| 6 | Should vulnerability suppress margin/structured note automatically? | Business rule matrix |
| 7 | Who is authorized to set vulnerability flag? | Access control |
| 8 | Retrospective removal—keep historical vulnerable versions? | Compliance audit |
| 9 | How to treat temporary distress (auto expiry)? | Expiry logic |
| 10 | Include vulnerability in client segmentation outputs? | Analytics design |

## Rule Matrix (Excerpt Including Vulnerability)
| Rule | Condition | Action |
|------|-----------|--------|
| Derivative Block | VulnerableInvestorFlag=TRUE AND RiskLevelCode NOT IN (BALANCED, MODERATE) | derivativeTradingAllowed=false |
| Structured Note Block | VulnerableInvestorFlag=TRUE | structuredNoteAllowed=false |
| Margin Block | VulnerableInvestorFlag=TRUE OR AbilityToBearLossTier=LOW | MarginAgreementStatus cannot become ACTIVE |
| Review Cycle Shortening | VulnerableInvestorFlag=TRUE | ReviewCycle set to EVENT_DRIVEN if currently BIENNIAL |

## Next Steps
1. Confirm vulnerability review interval.
2. Define override workflow (if discretionary advisor wants complex products).
3. Calibrate reliability penalty weights.
4. Approve enumeration sets.
5. Implement ingestion mapping (UNKNOWN defaults).
6. Design analytic view combining vulnerability + entitlements.

## Finalization Checklist
- [ ] Vulnerability fields approved (DONE).
- [ ] Override process defined.
- [ ] Reliability formula ratified.
- [ ] Review interval policy set.
- [ ] Enumeration table scripts prepared.
- [ ] Ingestion contract updated.

End of Document.