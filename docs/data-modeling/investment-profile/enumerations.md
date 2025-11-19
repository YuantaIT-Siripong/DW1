# Investment Profile Enumerations (Example Content)

This file lists example enumeration (code set) definitions referenced by the Investment Profile Module.  
Purpose: Provide a canonical source for codes, descriptions, governance notes, and potential extension rules.  
Status: Example only – finalize with Compliance and Data Governance before production freeze.

---

## 1. General Principles

| Principle | Description |
|-----------|-------------|
| Explicit UNKNOWN | Every critical enumeration includes `UNKNOWN` for early schema adoption when source data not yet available. |
| Immutable Codes | Code values should not be changed; only descriptions may evolve. |
| Extension Protocol | New codes require: (1) Compliance approval, (2) Data Governance ticket, (3) Version bump of this file. |
| Deprecation | Mark codes deprecated via `DeprecatedFlag` instead of deletion; maintain historical integrity. |
| Multi-Language Labels | English baseline; Thai labels added later in localization table (not part of minimal model). |

---

## 2. Enumeration Master Table Pattern (Suggested)

Recommended physical design for a generic enumeration registry (if using a shared pattern):

| Column | Type | Notes |
|--------|------|-------|
| EnumDomain | STRING | e.g., INVESTMENT_OBJECTIVE |
| EnumCode | STRING | e.g., GROWTH |
| DisplayNameEN | STRING | Human-friendly English name |
| DisplayNameTH | STRING | Thai label (optional future) |
| Description | STRING | Semantic definition |
| RiskMapping | STRING | Optional (e.g., GROWTH -> MODERATE) |
| DeprecatedFlag | BOOLEAN | Active vs deprecated |
| EffectiveStartTs | TIMESTAMP | Start validity |
| EffectiveEndTs | TIMESTAMP | End validity (nullable) |
| CreatedBy | STRING | Governance tracking |
| CreatedTs | TIMESTAMP | Audit |
| LastUpdatedBy | STRING | Audit |
| LastUpdatedTs | TIMESTAMP | Audit |

---

## 3. Enumerations Detail

### 3.1 InvestmentObjectiveCategory

Domain: INVESTMENT_OBJECTIVE

| Code | Description | Typical Risk Level | Notes |
|------|-------------|--------------------|-------|
| CAPITAL_PRESERVATION | Focus on principal safety | CONSERVATIVE | Often blocks high-leverage products |
| INCOME | Generate regular cash flow | BALANCED/MODERATE | May allow bonds, dividend equities |
| GROWTH | Long-term capital appreciation | GROWTH | Enables broader equity scope |
| SPECULATION | Short-term aggressive gains | AGGRESSIVE/SPECULATIVE | Allows derivatives/leverage (if other criteria met) |
| HEDGING | Risk mitigation strategies | VARIES | Requires derivative eligibility |
| RETIREMENT | Long-term preservation & income mix | BALANCED | Could map to medium horizon |
| TAX_EFFICIENCY | Optimize after-tax returns | MODERATE | Product advice may consider tax wrappers |
| EDUCATION_FUNDING | Targeted future education costs | MODERATE | Structured around time horizon |
| OTHER | Goal not captured above | VARIES | Requires manual review for product gating |
| UNKNOWN | Not collected yet | N/A | Penalizes DataQualityScore |

### 3.2 InvestmentTimeHorizon

Domain: INVESTMENT_TIME_HORIZON

| Code | Years (Indicative) | Use |
|------|--------------------|-----|
| SHORT | ≤ 2 | Limits illiquid / long-tenor products |
| MEDIUM | >2–≤5 | Balanced product mix |
| LONG | >5 | Supports structured notes, long-term growth |
| UNKNOWN | Not provided | Completeness penalty |

### 3.3 AbilityToBearLossTier

Domain: ABILITY_TO_BEAR_LOSS

| Code | Definition | Impact |
|------|------------|--------|
| LOW | Limited financial resilience | Block high-risk / leveraged products |
| MODERATE | Some loss absorption capacity | Standard product set |
| HIGH | Strong capacity for potential losses | Allows broader complex exposure |
| UNKNOWN | Undetermined | DataQuality penalty; restrict speculative until clarified |

### 3.4 LiquidityNeedLevel

Domain: LIQUIDITY_NEED

| Code | Description | Impact |
|------|-------------|--------|
| LOW | Low urgency to liquidate | Structured / long-tenor instruments possible |
| MEDIUM | Balanced need | Normal risk alignment |
| HIGH | Needs ready cash | Restrict illiquid / lock-up / complex products |
| UNKNOWN | Not captured | Completeness penalty |

### 3.5 HighNetWorthStatus

Domain: HNW_STATUS

| Code | Criteria (Example Placeholder) | Notes |
|------|-------------------------------|-------|
| NONE | Below HNW threshold | Retail treatment |
| HNW | Meets HNW threshold | May unlock certain products |
| UHNW | Ultra high net worth | Broader eligibility + discretionary |
| UNKNOWN | Evaluation pending | Conservative gating applied |

### 3.6 KYCStatus

Domain: KYC_STATUS

| Code | Description |
|------|-------------|
| PENDING | Awaiting initial submission |
| IN_PROGRESS | Documents under review |
| VERIFIED | Fully approved |
| EXPIRED | Past validity / needs refresh |
| UNKNOWN | Not propagated yet |

### 3.7 KYCRiskRating / AMLRiskRating

Domain: KYC_RISK / AML_RISK

| Code | Description | Typical Action |
|------|-------------|----------------|
| LOW | Low inherent risk | Standard monitoring |
| MEDIUM | Elevated factors | Additional periodic review |
| HIGH | High risk indicators | Enhanced due diligence; product restriction |
| UNKNOWN | Not assessed | Treat as medium until clarified (policy decision) |

### 3.8 RiskLevelCode

Domain: RISK_LEVEL

| Code | Behavior Summary | Example Products Allowed |
|------|------------------|--------------------------|
| CONSERVATIVE | Capital stability priority | Government bonds, blue-chip equity |
| MODERATE | Some volatility acceptable | Mixed funds, ETF |
| BALANCED | Blend growth and preservation | Broader equity, some structured |
| GROWTH | Higher volatility tolerance | Global equity, thematic funds |
| AGGRESSIVE | Significant volatility accepted | Derivatives, leveraged ETFs (if acknowledged) |
| SPECULATIVE | Very high risk tolerance | Short-term leveraged, complex structured |
| UNKNOWN | Not yet classified | Restrict high-risk products |

### 3.9 SourceOfWealthCode

Domain: SOURCE_OF_WEALTH

| Code | Description | AML Notes |
|------|-------------|----------|
| SALARY | Employment income | Standard verification |
| BUSINESS_INCOME | Company profits | May need business registration evidence |
| INVESTMENT_PORTFOLIO | Returns from investments | Check legitimacy of prior holdings |
| INHERITANCE | Received estate assets | Document inheritance sources |
| RENTAL_INCOME | Property rental stream | Validate property ownership |
| OTHER | Not in list | Manual classification required |
| UNKNOWN | Missing | AML risk monitoring escalates |

### 3.10 VulnerabilityReasonCode

Domain: VULNERABILITY_REASON

| Code | Description | Product Gating Implication |
|------|------------|----------------------------|
| ELDERLY_HIGH_COGNITIVE_RISK | Age/cognitive concerns | Restrict complex/leverage unless supervised |
| DISABILITY_SUPPORT_NEEDED | Assistance requirements | Extra disclosure clarity |
| LOW_FINANCIAL_LITERACY | Limited understanding | Narrow product set |
| RECENT_BEREAVEMENT | Temporary emotional stress | Delay speculative approvals |
| SERIOUS_ILLNESS | Sustained health impact | Heightened oversight |
| TEMPORARY_DISTRESS | Short-lived hardship | Reassess after period |
| OTHER | Not categorized | Manual review mandatory |
| UNKNOWN | Flag set but reason absent | Reliability penalty |

### 3.11 MarginAgreementStatus

Domain: MARGIN_AGREEMENT_STATUS

| Code | Meaning | Action |
|------|--------|--------|
| NOT_SIGNED | No approved margin agreement | Block margin/leverage |
| ACTIVE | Valid, approved agreement | Allow margin trading if other criteria met |
| EXPIRED | Agreement validity lapsed | Suspend margin until renewal |
| SUSPENDED | Manual/compliance suspension | Investigate risk/violation |

### 3.12 LeverageTolerance

Domain: LEVERAGE_TOLERANCE

| Code | Meaning |
|------|---------|
| NONE | No leverage comfort |
| LIMITED | Low leverage boundaries |
| HIGH | High leverage acceptable |
| UNKNOWN | Not evaluated |

### 3.13 ESGPreference (Optional)

Domain: ESG_PREFERENCE

| Code | Meaning |
|------|---------|
| NONE | No explicit ESG preference |
| MODERATE | General ESG interest |
| STRONG | Active ESG prioritization |
| UNKNOWN | Not collected |

### 3.14 TaxResidencyStatus

Domain: TAX_RESIDENCY_STATUS

| Code | Meaning |
|------|---------|
| PRIMARY | Single jurisdiction |
| MULTI | Multiple jurisdictions |
| UNKNOWN | Not determined |

### 3.15 ReviewCycle

Domain: REVIEW_CYCLE

| Code | Meaning |
|------|---------|
| ANNUAL | Yearly full review |
| BIENNIAL | Every two years |
| EVENT_DRIVEN | Triggered by life / compliance events |
| UNKNOWN | Not defined |

### 3.16 SanctionScreeningStatus

Domain: SANCTION_SCREENING_STATUS

| Code | Meaning | Action |
|------|--------|--------|
| CLEAR | No hits | Normal operation |
| HIT_PENDING_REVIEW | Potential match evaluating | Freeze high-risk entitlements |
| REJECTED | Confirmed name match / blocked | Restrict trading |
| UNKNOWN | Not processed | Treat as HIT_PENDING_REVIEW until screened (policy choice) |

### 3.17 FATCAStatus

Domain: FATCA_STATUS

| Code | Meaning |
|------|---------|
| NOT_APPLICABLE | No US indicia |
| PENDING_SELF_CERT | Awaiting client form |
| CERTIFIED | Valid FATCA documentation |
| REPORTED | Certified and reported (if required) |
| EXPIRED | Documentation lapsed |
| UNKNOWN | Not evaluated |

---

## 4. Reliability & Data Quality Scoring (Reference)

Suggested weight model (example only):

```yaml
data_quality:
  mandatory_attributes:
    - riskLevelCode
    - suitabilityScore
    - investmentObjectiveCategory
    - investmentTimeHorizon
    - abilityToBearLossTier
    - kycStatus
    - investorCategory
  unknown_penalty_per_attribute: 0.05
  stale_threshold_days:
    lastRiskReviewTs: 365
  stale_penalty: 0.05

reliability:
  base = data_quality_score
  penalties:
    sanctions:
      HIT_PENDING_REVIEW: 0.10
      REJECTED: 0.30
    pepFlag_true: 0.15
    vulnerability_unknown_reason: 0.10
  timeliness_factor:
    overdue_review: 0.85
    normal: 1.00
  objective_risk_mismatch_penalty: 0.05
```

---

## 5. SQL DDL Stubs (Optional Example)

```sql
-- Example dimension-specific enumeration for investment objectives
CREATE TABLE dim_investment_objective (
  InvestmentObjectiveSK    BIGINT GENERATED ALWAYS AS IDENTITY,
  ObjectiveCode            VARCHAR(40) NOT NULL,
  DisplayNameEN            VARCHAR(200) NOT NULL,
  DisplayNameTH            VARCHAR(200),
  Description              VARCHAR(500),
  DeprecatedFlag           BOOLEAN DEFAULT FALSE,
  EffectiveStartTs         TIMESTAMP NOT NULL,
  EffectiveEndTs           TIMESTAMP,
  CreatedTs                TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (InvestmentObjectiveSK),
  UNIQUE (ObjectiveCode, EffectiveStartTs)
);

-- Example insert seed (partial)
INSERT INTO dim_investment_objective (ObjectiveCode, DisplayNameEN, Description, EffectiveStartTs)
VALUES
('CAPITAL_PRESERVATION', 'Capital Preservation', 'Protect principal; low volatility products.', CURRENT_TIMESTAMP),
('GROWTH', 'Growth', 'Seek long-term capital appreciation.', CURRENT_TIMESTAMP),
('UNKNOWN', 'Unknown', 'Not yet captured.', CURRENT_TIMESTAMP);
```

---

## 6. Governance Checklist

| Item | Required Before New Code Addition |
|------|-----------------------------------|
| Compliance Approval | Yes |
| Data Steward Review | Yes |
| Enumeration File Update | Yes |
| Impact Assessment (Products / Rules) | Yes |
| Version Tag (ENUM_VERSION) | Yes |

Maintain an overall enumeration version constant (e.g., `ENUM_VERSION = 2025.11.19-1`) to detect changes and trigger downstream cache refresh.

---

## 7. Open Enumeration Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Should SPECULATION and AGGRESSIVE remain separate risk levels? | Product gating sensitivity |
| 2 | Do we require multi-objective support (bridge table) soon? | Schema complexity |
| 3 | Add ULTRA_LONG horizon (>10 years)? | Retirement planning |
| 4 | Introduce granular ESG categories later? | Product recommendation refinement |
| 5 | Formal thresholds for HNW/UHNW? | Regulatory / internal classification |
| 6 | Need a DISCRETIONARY vs ADVISORY segmentation enum? | Mandate modeling |
| 7 | Add reason codes for margin suspension? | Transparency & audit |
| 8 | Add multi-jurisdiction tax residency detail codes? | Cross-border compliance |
| 9 | Should vulnerability reasons expire automatically? | Review workflow |
| 10 | Standardize SourceOfWealth evidence mapping? | AML audit linkage |

---

## 8. Version Tag

`ENUM_VERSION: 2025.11.19-EXAMPLE`

Update this tag whenever codes are added, removed (deprecated), or semantics change.

---

## 9. Change Log (Example Placeholder)

| Version | Date | Change | Author |
|---------|------|--------|--------|
| 2025.11.19-EXAMPLE | 2025-11-19 | Initial draft enumerations file | Data Architecture |

---

## 10. Next Steps

1. Confirm mandatory enumerations with Compliance.
2. Define exact HNW/UHNW thresholds (attach to separate numeric criteria table).
3. Decide on multi-valued investment objectives support.
4. Freeze ENUM_VERSION for first production load.
5. Publish ingestion mapping doc referencing EnumDomain + code validation rules.

---

End of Example File.
