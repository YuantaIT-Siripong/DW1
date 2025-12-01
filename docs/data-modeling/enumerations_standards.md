# Enumeration Standards

## Purpose
Define structure, versioning, and governance for machine-readable enumeration files.

## File Location Pattern
```
enumerations/<domain>_<entity>_types.yaml
```

**Examples**:
- `enumerations/audit_event_types.yaml`
- `enumerations/customer_attribute_types.yaml` (future)
- `enumerations/investment_product_types.yaml` (future)

## Required YAML Structure
```yaml
enumeration_version: "YYYY.MM.DD-N"
generated_at_utc: "ISO8601 timestamp"
purpose: "Brief description"
schema_version: 1

<domain>_values:
  - code: "ENUM_CODE"
    display_name: "Human Readable"
    description: "Purpose and usage"
    category: "Logical grouping"
    lifecycle_status: ACTIVE | DEPRECATED
    introduced_version: "YYYY.MM.DD-N"
    deprecated_version: null
    replacement_code: null
    notes: "Optional explanatory text"

change_control:
  addition_requires: "ADR reference + governance ticket"
  deprecation_requires: "Governance ticket + replacement documentation"
  last_review_date: "YYYY-MM-DD"
  reviewers: ["Data Architecture", "Domain Lead"]

change_log:
  - version: "YYYY.MM.DD-N"
    date: "YYYY-MM-DD"
    change: "Description"
    author: "Team Name"
```

## Governance Rules

### Adding New Value
1. Create governance ticket
2. Reference applicable ADR (if architectural impact)
3. Add entry to YAML with `lifecycle_status: ACTIVE`
4. Bump `enumeration_version` (date + increment)
5. Update CONTEXT_MANIFEST.yaml
6. Deploy with ETL validation

### Deprecating Value
1. Create governance ticket with replacement plan
2. Update YAML entry:
   ```yaml
   lifecycle_status: DEPRECATED
   deprecated_version: "2025.12.15-1"
   replacement_code: "NEW_CODE"
   ```
3.  Bump `enumeration_version`
4. **Never delete** historical values
5. Configure ETL warnings for deprecated usage

## Validation Rules
- ETL **rejects** unknown codes (outside controlled backfill mode)
- ETL **warns** on deprecated code usage
- Version mismatch blocks deployment
- Monitoring alerts if `UNKNOWN` usage > 2% monthly

## Example: audit_event_types.yaml
See [enumerations/audit_event_types.yaml](../../enumerations/audit_event_types.yaml) for complete reference implementation.

## Related Standards
- [STANDARDS_INDEX. md](../STANDARDS_INDEX.md) - Master standards index
- [naming_conventions.md](naming_conventions.md) - Enumeration value casing (UPPERCASE_SNAKE_CASE)
- [AI_CONTEXT.md](../../AI_CONTEXT.md) - Change discipline rules