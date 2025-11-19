# Investment / Suitability Profile Module Specification (Phase 1 Draft)

## 1. Module Overview
The Investment Profile Module represents the time‑variant (SCD2) suitability, risk tolerance, capacity, regulatory eligibility, vulnerability status, acknowledgements, and product entitlement posture for a client. It complements (does not duplicate) the Customer Profile demographic dimension.

This module covers:
- Risk appetite (RiskLevelCode)
- SuitabilityScore and tier
- AbilityToBearLossTier
- InvestmentObjectiveCategory
- InvestmentTimeHorizon (client‑declared; may be UNKNOWN initially)
- LiquidityNeedLevel
- Regulatory / Compliance statuses (KYCStatus, KYCRiskRating, AMLRiskRating, FATCAStatus, SanctionScreeningStatus, PEPFlag)
- HighNetWorthStatus
- SourceOfWealthCode
- Product eligibility flags
- Acknowledgement flags
- Margin agreement status and leverage tolerance
- VulnerableInvestorFlag + reason & assessment timestamp
- Reliability and Data Quality scores (derived)
- AdvisoryDiscretionFlag (discretionary mandate indicator)
- Review cycle & next/last risk review timestamps

## 2. Business Goals / KPIs
| KPI | Definition | Purpose |
|-----|------------|---------|
| Suitability Coverage | % of active customer codes with a current investment profile version | Regulatory completeness |
| Complex Product Readiness | % profiles where ComplexProductAllowed = true and acknowledgment flag present | Product enablement |
| Vulnerability Prevalence | % profiles flagged vulnerable | Oversight allocation |
| Overdue Reviews | count where current_date > nextReviewDueTs | Compliance scheduling |
| Reliability Score Distribution | Histogram of ProfileReliabilityScore by segment | Data trust monitoring |
| Acknowledgement Freshness | % of required acknowledgements expiring in next 30 days | Renewal planning |

## 3. Core Use Cases
1. Point‑in‑time suitability check before trade (join on trade timestamp).
2. Determining entitlement for complex / leveraged / IPO products.
3. Early warning: review overdue or vulnerability classification changes.
4. Advisory recommendation logging (objective vs risk alignment).
5. Aggregated reporting for regulators (risk tier exposures, vulnerable investor handling).
6. Data quality curation (identify UNKNOWN prevalence to drive re‑collection).

## 4. Entity Inventory
| Entity | Type | Description |
|--------|------|-------------|
| Investment Profile | SCD2 Dimension root (scope: CUSTOMER or CUSTOMER_CODE) |
| Investment Profile Version | Historical versions (effective interval) |
| Acknowledgement Record | Fact/mini‑bridge referencing version + type (DERIVATIVE_RISK, FX_RISK, COMPLEX_PRODUCT) |
| Product Eligibility Snapshot | (Embedded as flags in version; optional external fact later) |
| Vulnerability Classification | Carried inline; future: optional audit fact |
| Reliability Scoring Process | Derived calculation (not a table; stored result fields in version) |

## 5. Scope & Hierarchy Alignment
- CUSTOMER scope (optional baseline) may exist alongside multiple CUSTOMER_CODE scoped profiles.
- Trade / subscription decisions at CUSTOMER_CODE level always prefer code‑scoped profile; fallback to CUSTOMER scope only if code profile absent.
- CUSTOMER_CODE profile rows have OverrideIndicator = TRUE.

## 6. SCD2 Versioning Policy
| Aspect | Policy |
|--------|--------|
| Change Detection | Hash of ordered versioning attributes + boolean flags (excluding derived scores). |
| Effective granularity | Timestamp (seconds) – needed for intraday acknowledgement & vulnerability changes. |
| Overlap | Disallowed within same (ScopeType, CustomerId/CustomerCode). |
| Closing Prior Version | Set EffectiveEndTs = new_start - microsecond. |
| Backdating | Allowed only via controlled workflow; must not create overlap. |
| Vulnerability Changes | Each change produces a new version (auditability). |

## 7. Versioned vs Type 1 Attributes
| Versioned (SCD2) | Reason |
|------------------|-------|
| RiskLevelCode | Suitability gating historically relevant |
| SuitabilityScore | Regulatory trace |
| AbilityToBearLossTier | Impacts leverage permissions |
| InvestmentObjectiveCategory | Changing objective influences recommendations |
| InvestmentTimeHorizon | Long/short horizon affects product fit |
| LiquidityNeedLevel | Drives illiquid product gating |
| HighNetWorthStatusCode | Impacts eligibility & segmentation |
| KYCStatus, KYCRiskRating, AMLRiskRating | Compliance gating changes |
| PEPFlag, SanctionScreeningStatus, FATCAStatus | Regulatory filters |
| InvestorCategory | Retail vs professional product scope |
| SourceOfWealthCode | AML trace link |
| InvestmentExperienceYears | Suitability mapping logic |
| Acknowledgement Flags (3) | Risk acceptance state |
| Product Eligibility Flags | Must reflect decisions valid at trade time |
| MarginAgreementStatus | Leverage capability time‑variant |
| LeverageTolerance | Suitability gating |
| ESGPreference | Advisory segmentation (optional) |
| TaxResidencyStatus | Influence on cross‑border products |
| ReviewCycle, NextReviewDueTs, LastRiskReviewTs | Scheduling state |
| VulnerableInvestorFlag, VulnerabilityReasonCode, VulnerabilityAssessmentTs | Oversight |
| AdvisoryDiscretionFlag | Mandate state |
| ProfileReliabilityScore, DataQualityScore | Derived but snapshot required |

Type 1 (overwrite only):
- SourceSystem, CreatedBy, IngestionBatchId (operational lineage, not business history).

## 8. Attribute Inventory (Selected Subset)
| Attribute | Business Definition | Sample | Notes |
|-----------|---------------------|--------|------|
| InvestmentProfileId | Stable identifier for profile scope | IP-CODE-111111 | One per scope |
| VersionNumber | Sequential per profile | 7 | SCD2 sequence |
| EffectiveStartTs / EffectiveEndTs | Validity window | 2025-11-19T07:30:00Z | End null = current |
| ScopeType | CUSTOMER / CUSTOMERCODE | CUSTOMERCODE | Gating precedence |
| OverrideIndicator | TRUE if scoped to code | TRUE | Code override |
| SuitabilityScore | Numeric assessment result | 76 | External engine |
| RiskLevelCode | Categorized risk appetite | BALANCED | |
| AbilityToBearLossTier | Capacity to absorb loss | MODERATE | |
| InvestmentObjectiveCategory | Primary goal | INCOME | |
| InvestmentTimeHorizon | Declared horizon | UNKNOWN | May remain UNKNOWN until collected |
| LiquidityNeedLevel | Liquidity urgency | MEDIUM | |
| HighNetWorthStatusCode | Wealth tier | NONE | |
| KYCStatus | KYC lifecycle | VERIFIED | |
| KYCRiskRating | KYC risk rating | LOW | |
| AMLRiskRating | AML risk rating | LOW | |
| PEPFlag | Politically exposed person | FALSE | |
| SanctionScreeningStatus | Screening outcome | CLEAR | |
| FATCAStatus | FATCA doc state | NOT_APPLICABLE | |
| InvestorCategory | Regulatory classification | RETAIL | |
| SourceOfWealthCode | Wealth origin | SALARY | |
| InvestmentExperienceYears | Years of active investing | 4 | |
| ComplexProductAcknowledgedFlag | Disclosure acceptance | FALSE | |
| DerivativeRiskAcknowledgedFlag | Derivatives risk acceptance | TRUE | |
| FXRiskAcknowledgedFlag | FX risk acceptance | TRUE | |
| ComplexProductAllowed | Eligibility final decision | FALSE | Derived gating |
| IPOParticipationAllowed | IPO access | TRUE | |
| MarginAgreementStatus | Margin contract lifecycle | NOT_SIGNED | |
| LeverageTolerance | Preference level | LIMITED | |
| AdvisoryDiscretionFlag | Discretionary mandate present | FALSE | |
| VulnerableInvestorFlag | Vulnerability classification | TRUE | |
| VulnerabilityReasonCode | Reason | LOW_FINANCIAL_LITERACY | |
| VulnerabilityAssessmentTs | Last assessment timestamp | 2025-11-18T09:30:00Z | |
| NextReviewDueTs | Scheduled next review date | 2026-05-18T00:00:00Z | Min of component due dates |
| LastRiskReviewTs | Last suitability assessment timestamp | 2025-11-19T07:30:00Z | |
| DataQualityScore | Completeness/validity (0–1) | 0.90 | |
| ProfileReliabilityScore | Composite trust (0–1) | 0.84 | Includes penalties |

## 9. Reliability & Data Quality (Conceptual)
DataQualityScore:
- Base completeness % across mandatory fields (objective, risk level, ability to bear loss, investor category, KYCStatus, acknowledgements required for granted entitlements).
- Penalties for UNKNOWN mandatory attributes, stale LastRiskReviewTs beyond ReviewCycle threshold.

ProfileReliabilityScore:
- Reliability = DataQualityScore * (1 - sanctionsPenalty) * (1 - pepPenalty) * timelinessFactor * consistencyFactor * (1 - vulnerabilityPenaltyIfUnknownReason)

Consistency check example:
- If RiskLevelCode = CONSERVATIVE but ComplexProductAllowed = TRUE -> consistencyFactor < 1 (e.g., 0.9)
- If Objective = SPECULATION with RiskLevelCode = SPECULATIVE -> factor = 1.0

## 10. Vulnerable Investor Handling
Rules (illustrative):
| Rule | Logic | Outcome |
|------|-------|---------|
| Complex product block | VulnerableInvestorFlag=TRUE | ComplexProductAllowed=FALSE unless supervisory override |
| Margin suspension | VulnerableInvestorFlag=TRUE OR AbilityToBearLossTier=LOW | MarginAgreementStatus cannot transition to ACTIVE |
| Review acceleration | VulnerableInvestorFlag=TRUE | NextReviewDueTs = MIN(existing, LastRiskReviewTs + 6 months) |
| Reliability penalty | VulnerableInvestorFlag=TRUE AND VulnerabilityReasonCode=UNKNOWN | reliabilityPenalty += 0.10 |

## 11. Acknowledgements
- Stored as boolean flags in version for quick gating.
- Separate Acknowledgement fact table retains per acceptance event (AcceptedTs, ExpiresTs).
- Eligibility flag requires BOTH acknowledgement flag true AND suitability prerequisites (risk & experience thresholds).
- Umbrella vs per product category: currently umbrella COMPLEX_PRODUCT acknowledgment covers structured notes + perpetual bonds; extend enumeration if split needed.

## 12. Suitability Aggregation Policy
Model Option (Chosen): Independent root vs per customer code.
- ROOT questionnaire yields Customer scope profile.
- CUSTOMER_CODE scope questionnaire may override (no arithmetic averages).
- Fallback logic: if no code profile for a trade, use root; log fallback event.
- Potential future derived field: AggregatedConservativeRiskLevel = MIN(all code risk levels) for oversight dashboards only (not gating).

## 13. Relationships & Cardinality
- CustomerId 1:M InvestmentProfile (scopes)
- InvestmentProfile 1:M InvestmentProfileVersions
- InvestmentProfileVersion 1:M AcknowledgementRecords
- InvestmentProfileVersion 1:1 reliability & quality scores
- InvestmentProfileVersion 1:1 vulnerability classification active snapshot (historically versioned through SCD2)

## 14. Source Systems & Cadence
| Source | Feed Type | Cadence | Attributes |
|--------|-----------|---------|-----------|
| Suitability Questionnaire Engine | Event | On completion | RiskLevelCode, SuitabilityScore, Objective, Horizon |
| KYC / AML System | Batch | Daily | KYCStatus, KYCRiskRating, AMLRiskRating, PEPFlag, SanctionScreeningStatus, FATCAStatus |
| Wealth Classification Service | Batch | Weekly | HighNetWorthStatusCode, SourceOfWealthCode |
| Margin Agreement Workflow | Event | On approval/expires | MarginAgreementStatus |
| Acknowledgement Capture | Event | On acceptance | Acknowledgement flags |
| Mandate Management | Event | On mandate sign/revoke | AdvisoryDiscretionFlag |
| Vulnerability Assessment | Event | On initial/updated assessment | Vulnerability fields |

## 15. Data Quality Rules (Investment Module)
- No overlapping effective intervals per InvestmentProfileId.
- If ComplexProductAllowed=TRUE then ComplexProductAcknowledgedFlag=TRUE.
- MarginAgreementStatus=ACTIVE requires LeverageTolerance != NONE AND AbilityToBearLossTier != LOW AND VulnerableInvestorFlag=FALSE.
- NextReviewDueTs > LastRiskReviewTs.
- ReviewCycle must be consistent: if VulnerableInvestorFlag=TRUE and ReviewCycle=BIENNIAL → flag inconsistency.
- Acknowledgement expiry (ExpiresTs) must NOT be earlier than EffectiveStartTs of version referencing it.

## 16. Enumerations (Reference)
Uses enumerations from enumerations.md: InvestmentObjectiveCategory, InvestmentTimeHorizon, AbilityToBearLossTier, LiquidityNeedLevel, HighNetWorthStatus, KYCStatus, KYCRiskRating, AMLRiskRating, RiskLevelCode, SourceOfWealthCode, VulnerabilityReasonCode, MarginAgreementStatus, LeverageTolerance, ESGPreference, TaxResidencyStatus, ReviewCycle, SanctionScreeningStatus, FATCAStatus.

## 17. Point‑in‑Time Query Pattern (Customer Code)
```sql
select *
from dim_investment_profile_version
where customer_code = :code
  and effective_start_ts <= :trade_ts
  and (effective_end_ts is null or effective_end_ts > :trade_ts)
order by effective_start_ts desc
limit 1;
```
Fallback:
```sql
-- If no row returned, fallback to CUSTOMER scope
select *
from dim_investment_profile_version
where customer_id = :customer_id
  and scope_type = 'CUSTOMER'
  and effective_start_ts <= :trade_ts
  and (effective_end_ts is null or effective_end_ts > :trade_ts)
order by effective_start_ts desc
limit 1;
```

## 18. Sample JSON Snapshot
```json
{
  "investmentProfileId": "IP-CODE-111111",
  "currentVersion": {
    "versionNumber": 7,
    "effectiveStartTs": "2025-11-19T07:30:00Z",
    "scopeType": "CUSTOMERCODE",
    "customerId": "CUST-A",
    "customerCode": "111111",
    "overrideIndicator": true,
    "suitabilityScore": 76,
    "riskLevelCode": "BALANCED",
    "abilityToBearLossTier": "MODERATE",
    "investmentObjectiveCategory": "INCOME",
    "investmentTimeHorizon": "UNKNOWN",
    "liquidityNeedLevel": "MEDIUM",
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
    "complexProductAcknowledgedFlag": false,
    "derivativeRiskAcknowledgedFlag": false,
    "fxRiskAcknowledgedFlag": true,
    "complexProductAllowed": false,
    "ipoParticipationAllowed": true,
    "marginAgreementStatus": "NOT_SIGNED",
    "leverageTolerance": "LIMITED",
    "advisoryDiscretionFlag": false,
    "vulnerableInvestorFlag": true,
    "vulnerabilityReasonCode": "LOW_FINANCIAL_LITERACY",
    "vulnerabilityAssessmentTs": "2025-11-18T09:30:00Z",
    "nextReviewDueTs": "2026-05-18T00:00:00Z",
    "lastRiskReviewTs": "2025-11-19T07:30:00Z",
    "reviewCycle": "ANNUAL",
    "dataQualityScore": 0.90,
    "profileReliabilityScore": 0.84
  }
}
```

## 19. Open Questions
| # | Question | Impact |
|---|----------|--------|
| 1 | Minimum mandatory attributes for “active” investment profile? | DataQuality threshold |
| 2 | Horizon remains UNKNOWN – enforce conservative gating? | Product policy |
| 3 | Split complex product acknowledgment into categories later? | Disclosure overhead |
| 4 | Add separate fact for vulnerability changes (audit)? | Lineage |
| 5 | Include experience bucket enumeration? | Suitability logic |
| 6 | Supervisory override logging design? | Compliance audit |
| 7 | Reliability penalty exact weights finalization? | Scoring stability |
| 8 | Should ESGPreference influence product eligibility now? | Scope creep |
| 9 | Dedicated reason codes for margin suspension vs vulnerability? | Transparency |
| 10 | Aggregated risk posture roll‑up needed for analytics? | Additional derived field |

## 20. Next Steps
1. Confirm mandatory field list for DataQualityScore baseline.
2. Finalize scoring weights & override event logging.
3. Implement dim_investment_profile & dim_investment_profile_version DDL (aligned with attributes).
4. Build Acknowledgement fact table (acceptance events).
5. Add reliability calculation logic to ETL pipeline.
6. Define vulnerability override workflow & supervisor trace.
7. Decide initial horizon collection strategy; keep UNKNOWN handling documented.

## 21. Change Control
- Adding/removing versioned attributes requires ADR (ADR-INV-001) before schema alteration.
- Enumeration changes require update to enumerations.md & ENUM_VERSION bump.
- Reliability scoring formula changes require data governance sign‑off and versioned formula doc.

End of Draft Specification.