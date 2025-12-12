# Test DDL compiles
psql -U postgres -d dw1 -f db/bronze/<entity>_standardized.sql --dry-run
psql -U postgres -d dw1 -f db/gold/dim_<entity>.sql --dry-run

# Expected:  No syntax errors


# Compile dbt models
dbt compile --models silver. <entity>_standardized
dbt compile --models gold. dim_<entity>

# Expected: Models compiled successfully

Check these generated files for syntax errors:

1. db/bronze/<entity>_standardized.sql
2. db/gold/dim_<entity>.sql
3. dbt/models/silver/<entity>_standardized.sql
4. dbt/models/gold/dim_<entity>.sql

Verify: 
- All SQL statements end with semicolon
- All parentheses balanced
- All quotes closed
- No typos in keywords (CREAT → CREATE, PRIMRAY → PRIMARY)
- All Jinja tags closed ({% ... %})
- All dbt refs valid ({{ ref('...') }})

Report:  ✅ PASS or ❌ ERRORS with line numbers
