# Scripts Directory

**Purpose**: Utility scripts for repository maintenance and automation  
**Owner**: Data Engineering Team  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains utility scripts that automate common repository maintenance tasks. These scripts are NOT part of the ETL/ELT pipeline but are used for development, testing, and repository management.

---

## Scripts Inventory

### generate_seeds_from_yaml.py

**Type**: Python Utility Script  
**Purpose**: Generates dbt seed CSV files from enumeration YAML files  
**Status**: Legacy support (for backward compatibility)

**Usage**:
```bash
python scripts/generate_seeds_from_yaml.py
```

**What it does**:
1. Reads all YAML files from `/enumerations/` directory
2. Extracts enumeration values
3. Generates corresponding CSV files in `/dbt/seeds/reference/`
4. Preserves code, description, sort_order columns

**When to use**:
- When maintaining backward compatibility with seed-based workflows
- When BI tools require CSV lookup tables instead of direct codes
- When synchronizing YAML to CSV after enumeration updates

**Dependencies**:
- Python 3.x
- PyYAML package
- `/enumerations/*.yaml` files must exist

**Note**: This is part of the migration from seed-based to YAML-based enumerations. New development should use YAML directly and dbt enum models in `dbt/models/silver/enums/`.

---

## Future Scripts (Planned)

### validate_repository.py (Planned)
- Validates repository structure against standards
- Checks naming conventions
- Verifies contract-DDL alignment
- Validates enumeration files

### generate_documentation.py (Planned)
- Auto-generates module documentation
- Updates file index
- Generates dependency graphs

---

## Adding New Scripts

When adding a new script:

1. **Create the script file** in this directory
2. **Add executable permissions** (if shell script): `chmod +x script_name.sh`
3. **Document it here** in this README
4. **Include a header comment** in the script explaining:
   - Purpose
   - Usage
   - Dependencies
   - Example
5. **Update REPOSITORY_FILE_INDEX.md** with script details
6. **Add to .gitignore if temporary** outputs are created

---

## Script Guidelines

### Naming Convention
- Use `snake_case.py` or `snake_case.sh`
- Name should describe action: `generate_`, `validate_`, `sync_`, `update_`

### Documentation Requirements
All scripts MUST have:
- Header docstring (Python) or comment block (Shell)
- Purpose statement
- Usage examples
- Dependency list
- Author and date

### Example Header:
```python
#!/usr/bin/env python3
"""
generate_seeds_from_yaml.py

Purpose: Generates dbt seed CSV files from enumeration YAML files
Author: Data Engineering Team
Created: 2025-11-20
Updated: 2026-01-05

Usage:
    python scripts/generate_seeds_from_yaml.py

Dependencies:
    - PyYAML
    - enumerations/*.yaml files

Output:
    - dbt/seeds/reference/*.csv files
"""
```

---

## Testing Scripts

Before committing scripts:
1. Test in development environment
2. Verify outputs are correct
3. Check for side effects
4. Document any environment requirements
5. Test with missing dependencies (should fail gracefully)

---

## CI/CD Integration

Scripts may be integrated into CI/CD pipelines for:
- Automated validation on PR
- Documentation generation on merge
- Seed synchronization on enumeration changes

See `.github/workflows/` for CI configuration (if applicable).

---

**Last Updated**: 2026-01-05  
**Maintained By**: Data Engineering Team
