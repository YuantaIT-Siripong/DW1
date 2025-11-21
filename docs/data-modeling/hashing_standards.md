# Hashing Standards

## Purpose
This document defines the authoritative standards for generating deterministic hashes used in change detection, data lineage, and profile versioning across DW1. Consistent hashing is critical for SCD2 triggers, deduplication, and audit trails.

## Scope
These standards apply to:
- **Profile change hashes** for SCD2 dimensions (`profile_change_hash`, `profile_hash`)
- **Multi-valued set hashes** for bridge tables (`income_source_set_hash`, `investment_purpose_set_hash`, `contact_channel_set_hash`)
- **Record fingerprints** for deduplication and reconciliation
- **Composite key hashing** where natural keys are unwieldy

## Hash Algorithm: SHA256

### Standard
All hashes **MUST** use **SHA256** (256-bit secure hash algorithm).

**Rationale:**
- **Not MD5:** MD5 is cryptographically weak and collision-prone. It was previously used in legacy documentation but is **deprecated**.
- **SHA256 advantages:**
  - Collision-resistant
  - Industry standard for data integrity
  - Widely supported across database platforms and programming languages
  - Fixed 64-character hexadecimal output

### Implementation Examples

#### PostgreSQL
```sql
-- Using pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto;

SELECT encode(digest('concatenated_string', 'sha256'), 'hex') AS hash_value;
```

#### Python
```python
import hashlib

def calculate_sha256(input_string: str) -> str:
    return hashlib.sha256(input_string.encode('utf-8')).hexdigest()
```

#### Java
```java
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;

public static String calculateSHA256(String input) {
    MessageDigest digest = MessageDigest.getInstance("SHA-256");
    byte[] hash = digest.digest(input.getBytes(StandardCharsets.UTF_8));
    return bytesToHex(hash);
}
```

## Profile Change Hash Algorithm

### Definition
The `profile_change_hash` (or `profile_hash`) is a deterministic hash of **all SCD2 versioned attributes** used to detect when a new version should be created.

### Step-by-Step Algorithm

#### 1. Select Attributes
Include **only** the attributes listed in the `hash_fields` section of the dimension's SCD2 contract.

**Included:**
- All SCD2 versioned attributes (from contract `scd2_attributes`)
- Multi-valued set hashes (e.g., `income_source_set_hash`)

**Excluded (NEVER include):**
- Surrogate keys (`*_version_sk`, `*_sk`)
- Effective timestamps (`effective_start_ts`, `effective_end_ts`, `effective_start_date`, `effective_end_date`)
- Current flag (`is_current`, `current_flag`)
- Type 1 attributes (non-versioned fields like names, email, phone)
- **Derived metrics and scores** (`data_quality_score`, `profile_reliability_score`, `suitability_score` if calculated)
- Audit/lineage fields (`created_ts`, `created_by`, `ingestion_batch_id`, `source_extract_reference`)
- The hash field itself (`profile_change_hash`, `profile_hash`)

**Rationale for Excluding Scores:**
Scores like `data_quality_score` and `profile_reliability_score` are **derived outcomes** of the profile state, not drivers of business attribute changes. Including them would create spurious versions whenever scoring logic is recalibrated or recalculated, polluting the historical record with non-material changes.

**Exception:** If a score is a **client-declared input** (e.g., `suitability_score` provided by external system), it should be included. Consult the dimension contract to verify.

#### 2. Sort Attributes Alphabetically
Order the selected attributes **alphabetically by attribute name** (case-insensitive, ascending).

**Example:**
For `dim_investment_profile_version`, if hash_fields = `[risk_level_code, kyc_status, investment_time_horizon]`, sort as:
```
investment_time_horizon
kyc_status
risk_level_code
```

**Rationale:** Deterministic ordering ensures the same attributes always produce the same hash, regardless of insertion order or schema evolution.

#### 3. Normalize Values

Apply the following normalization rules to each attribute value:

| Data Type | Normalization Rule |
|-----------|-------------------|
| **String** | Lowercase, trim leading/trailing whitespace |
| **NULL** | Represent as literal string `__NULL__` |
| **Boolean** | Convert to lowercase string: `true` or `false` |
| **Integer** | Convert to string: `"42"` |
| **Decimal/Float** | Round to fixed precision (e.g., 2 decimals), convert to string: `"123.45"` |
| **Date** | Format as ISO 8601: `YYYY-MM-DD` (e.g., `2025-06-15`) |
| **Timestamp** | Format as ISO 8601 to **second precision**: `YYYY-MM-DDTHH:MM:SS` (e.g., `2025-06-15T14:30:00`) |
| **Enum/Code** | Uppercase (if enumerations are uppercase), trim |

**Examples:**
```
marital_status_id = "MARRIED" → "married"
birthdate = 1985-03-20 → "1985-03-20"
investment_experience_years = NULL → "__NULL__"
pep_flag = TRUE → "true"
suitability_score = 78.5 → "78.50" (if 2 decimals)
```

#### 4. Concatenate with Delimiter
Concatenate the **normalized values** (in alphabetical order by attribute name) using the pipe delimiter `|`.

**Format:**
```
value1|value2|value3|...|valueN
```

**Example:**
For attributes `[investment_time_horizon, kyc_status, risk_level_code]` with values `["LONG_TERM", "APPROVED", "MODERATE"]`:
```
Concatenated string: "long_term|approved|moderate"
```

**Edge Case (Empty String):**
If an attribute is an empty string `""`, include it as empty between delimiters:
```
value1||value3  (value2 is empty string)
```

#### 5. Generate SHA256 Hash
Apply the SHA256 algorithm to the concatenated string (UTF-8 encoded).

**Output:** 64-character hexadecimal string.

**Example:**
```sql
-- PostgreSQL
SELECT encode(
    digest('long_term|approved|moderate', 'sha256'), 
    'hex'
) AS profile_hash;
-- Result: '3f7a8b2c1d9e...' (64 chars)
```

### Full Example: Customer Profile Hash

**Dimension:** `dim_customer_profile`

**Hash Fields (from contract):**
```yaml
hash_fields:
  - marital_status_id
  - nationality_id
  - occupation_id
  - education_level_id
  - birthdate
  - income_source_list_hash
  - investment_purpose_list_hash
```

**Sample Record:**
```
marital_status_id: "MARRIED"
nationality_id: "TH"
occupation_id: "ENGINEER"
education_level_id: "BACHELOR"
birthdate: 1985-03-20
income_source_list_hash: "a3f2c..."
investment_purpose_list_hash: "d8e1b..."
```

**Step-by-Step:**
1. **Sort alphabetically:**
   ```
   birthdate, education_level_id, income_source_list_hash, investment_purpose_list_hash, marital_status_id, nationality_id, occupation_id
   ```

2. **Normalize:**
   ```
   "1985-03-20", "bachelor", "a3f2c...", "d8e1b...", "married", "th", "engineer"
   ```

3. **Concatenate:**
   ```
   "1985-03-20|bachelor|a3f2c...|d8e1b...|married|th|engineer"
   ```

4. **SHA256:**
   ```sql
   SELECT encode(
       digest('1985-03-20|bachelor|a3f2c...|d8e1b...|married|th|engineer', 'sha256'),
       'hex'
   ) AS profile_change_hash;
   ```

## Multi-Valued Set Hash Algorithm

### Definition
Multi-valued set hashes (e.g., `income_source_set_hash`) are used to detect changes in bridge table memberships without comparing individual rows.

### Algorithm

#### 1. Extract Set Members
Retrieve the list of member IDs from the bridge table for the given profile version.

**Example:**
For `customer_profile_version_sk = 1001`, retrieve income sources:
```
income_source_id: [201, 203, 205]
```

#### 2. Sort Members Ascending
Sort the member IDs in **ascending numerical order**.

**Example:**
```
[201, 203, 205] → [201, 203, 205] (already sorted)
```

**Rationale:** Deterministic ordering ensures `[201, 203]` and `[203, 201]` produce the same hash.

#### 3. Concatenate with Comma Delimiter
Join the sorted IDs with a comma `,`.

**Example:**
```
"201,203,205"
```

#### 4. Generate SHA256 Hash
Apply SHA256 to the concatenated string.

**Example:**
```sql
SELECT encode(
    digest('201,203,205', 'sha256'),
    'hex'
) AS income_source_set_hash;
```

### Edge Cases

| Scenario | Concatenated String | Hash |
|----------|---------------------|------|
| Empty set | `""` (empty string) | SHA256 of empty string |
| Single member | `"201"` | SHA256 of `"201"` |
| Duplicate IDs (before sort) | `[201, 201]` → deduplicate → `[201]` | SHA256 of `"201"` |

**Deduplication Rule:** If the source data contains duplicate IDs, deduplicate **before** sorting.

## Test Patterns

### Test Case 1: Determinism
**Objective:** Verify the same input always produces the same hash.

```python
def test_hash_determinism():
    input_string = "long_term|approved|moderate"
    hash1 = calculate_sha256(input_string)
    hash2 = calculate_sha256(input_string)
    assert hash1 == hash2
```

### Test Case 2: Ordering Independence (Set Hash)
**Objective:** Verify different orderings produce the same hash after sorting.

```python
def test_set_hash_ordering():
    set1 = [201, 203, 205]
    set2 = [205, 201, 203]
    hash1 = calculate_set_hash(set1)  # Sorts internally
    hash2 = calculate_set_hash(set2)
    assert hash1 == hash2
```

### Test Case 3: NULL Handling
**Objective:** Verify NULL values are represented as `__NULL__`.

```python
def test_null_normalization():
    attributes = {"risk_level": "MODERATE", "kyc_status": None}
    normalized = normalize_attributes(attributes)
    assert normalized["kyc_status"] == "__NULL__"
```

### Test Case 4: Change Detection
**Objective:** Verify hash changes when an attribute changes.

```python
def test_change_detection():
    profile1 = {"risk_level": "MODERATE", "kyc_status": "APPROVED"}
    profile2 = {"risk_level": "HIGH", "kyc_status": "APPROVED"}
    hash1 = calculate_profile_hash(profile1)
    hash2 = calculate_profile_hash(profile2)
    assert hash1 != hash2
```

### Test Case 5: Score Exclusion
**Objective:** Verify derived scores do NOT affect the hash.

```python
def test_score_exclusion():
    # Same SCD2 attributes, different scores
    profile1 = {
        "risk_level": "MODERATE",
        "kyc_status": "APPROVED",
        "data_quality_score": 85.0  # Excluded
    }
    profile2 = {
        "risk_level": "MODERATE",
        "kyc_status": "APPROVED",
        "data_quality_score": 92.0  # Excluded (different score)
    }
    hash1 = calculate_profile_hash(profile1, exclude=['data_quality_score'])
    hash2 = calculate_profile_hash(profile2, exclude=['data_quality_score'])
    assert hash1 == hash2  # Hashes must be identical
```

## Validation and Troubleshooting

### Common Issues

1. **Different Hashes for Same Data:**
   - Check normalization: Are strings lowercased? Whitespace trimmed?
   - Verify sorting: Are attributes in alphabetical order?
   - Check delimiter: Using `|` for profiles, `,` for sets?

2. **Spurious Version Creation:**
   - Ensure derived scores are excluded from hash.
   - Check for floating-point precision issues (round to fixed decimals).
   - Verify timestamp precision (normalize to seconds, not microseconds).

3. **Hash Collisions (Extremely Rare):**
   - SHA256 collisions are theoretically possible but astronomically unlikely in practice.
   - If suspected, log the full concatenated string for debugging.

### Debugging SQL Function
```sql
-- Example: Debug hash calculation
CREATE OR REPLACE FUNCTION debug_profile_hash(
    p_risk_level TEXT,
    p_kyc_status TEXT,
    p_investment_horizon TEXT
) RETURNS TABLE (
    concatenated_string TEXT,
    hash_value TEXT
) AS $$
BEGIN
    -- Sort and normalize
    concatenated_string := LOWER(TRIM(p_investment_horizon)) || '|' ||
                           LOWER(TRIM(p_kyc_status)) || '|' ||
                           LOWER(TRIM(p_risk_level));
    
    hash_value := encode(digest(concatenated_string, 'sha256'), 'hex');
    
    RETURN QUERY SELECT concatenated_string, hash_value;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT * FROM debug_profile_hash('MODERATE', 'APPROVED', 'LONG_TERM');
```

## Migration from MD5 to SHA256

### Legacy MD5 References
Some earlier documentation referenced MD5. All MD5 usage is **deprecated** and must be replaced with SHA256.

### Migration Steps
1. Update all hash calculation functions to use SHA256.
2. Recalculate hashes for existing records (one-time batch update).
3. Update SCD2 change detection logic to use new SHA256 hashes.
4. Add database comments or migration notes for auditability.

**Backward Compatibility:** If MD5 hashes are stored, add a `profile_hash_sha256` column, populate it, then drop the MD5 column after validation.

## Related Documents
- [Standard SCD2 Policy](../../contracts/scd2/STANDARD_SCD2_POLICY.md)
- [Naming Conventions](naming_conventions.md)
- [SCD2 Contract: Customer Profile](../../contracts/scd2/dim_customer_profile_columns.yaml)
- [SCD2 Contract: Investment Profile](../../contracts/scd2/dim_investment_profile_version_columns.yaml)
- [AI_CONTEXT.md](../../AI_CONTEXT.md)

## Change Log
| Version | Date | Change | Author |
|---------|------|--------|--------|
| 1.0 | 2025-11-21 | Initial hashing standards (SHA256, profile hash, set hash) | Data Architecture |
