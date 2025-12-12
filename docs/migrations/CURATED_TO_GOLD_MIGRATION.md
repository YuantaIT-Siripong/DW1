# Migration Guide: Curated → Gold Schema

**Date**: 2025-12-12  
**Type**: Schema Rename  
**Status**: Documentation

---

## Overview

Migration from legacy `curated` schema to `gold` schema, aligning with Medallion Architecture.

## Repository Migration (Complete ✅)

### Changes Made
1. **Contracts**: `contracts/customer/` → `contracts/gold/`
2. **DDL Files**: Complete `db/gold/` with all 4 tables
3. **Documentation**: Updated 14 files, 27 references

## Database Migration (Pending)

### Recommended Approach
```sql
-- Simple schema rename
ALTER SCHEMA curated RENAME TO gold;
```

### Prerequisites
- [ ] Backup database
- [ ] Notify stakeholders
- [ ] Test in dev environment
- [ ] Schedule maintenance window

### Testing Checklist
- [ ] Verify all tables exist
- [ ] Check row counts
- [ ] Test ETL scripts
- [ ] Run dbt models
- [ ] Verify permissions

## Related Documents
- [Gap Analysis](../../GAP_ANALYSIS.md)
- [Layer Architecture](../layers/README.md)
- [Gold DDL Files](../../db/gold/)
