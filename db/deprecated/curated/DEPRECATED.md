# ⚠️ THIS FOLDER IS DEPRECATED

**Status**: Legacy / Deprecated  
**Date Deprecated**: 2025-12-12

## Why Deprecated?

This folder contains DDL scripts that create tables in the **curated** schema.

The project has standardized on **gold** schema to align with **Medallion Architecture** naming conventions (Bronze/Silver/Gold).

## What to Use Instead

All Gold layer DDL scripts have been consolidated in:

```
/db/gold/
```

This includes:
- ✅ SCD2 dimensions (`gold.dim_*`)
- ✅ Bridge tables (`gold.bridge_*`)
- ✅ Audit fact tables (`gold.fact_*_audit`)

## Migration Notes

Files from `db/curated/` have been:

1. **Copied** to `db/gold/`
2. **Schema name changed** from `curated` to `gold`
3. **Original files kept here** for historical reference only

## Do Not Use

- ❌ **Do not create new files** in this folder
- ❌ **Do not reference curated schema** in new code
- ❌ **Do not run these DDL scripts** in production

## Use This Instead

✅ **Use `db/gold/` folder** and **`gold` schema** for all Gold layer objects

### Example Migration

**OLD (Deprecated)**:
```sql
-- db/curated/dimensions/dim_customer_profile.sql
CREATE TABLE curated.dim_customer_profile (
    customer_profile_version_sk BIGINT PRIMARY KEY,
    ...
);
```

**NEW (Current)**:
```sql
-- db/gold/dimensions/dim_customer_profile.sql
CREATE TABLE gold.dim_customer_profile (
    customer_profile_version_sk BIGINT PRIMARY KEY,
    ...
);
```

## Historical Context

- **Early versions** of this project used `curated` schema for the presentation/dimensional layer
- This was **renamed to `gold`** to align with modern Medallion Architecture adopted by:
  - Databricks
  - Snowflake
  - AWS Lake Formation
  - Azure Data Lake
- The Medallion Architecture uses clear, universally understood naming: Bronze (raw) → Silver (cleaned) → Gold (business-ready)

## Questions?

See:
- [Medallion Architecture Documentation](/docs/layers/README.md)
- [AI Context](/AI_CONTEXT.md) - Schema naming section
- [Architecture Overview](/docs/architecture/README.md)

---

**For AI Agents**: Always use `gold` schema, never `curated`. Reference this file when encountering curated schema references in legacy code.
