# AI Usage Guidelines

## When Asking Copilot
Provide: goal, grain (if fact), attribute list, versioned vs type1, desired output (DDL/YAML/docs/tests).

## Standard Prompts
- "Create PR for entitlement view logic"
- "Draft SCD2 contract for <dimension> with attributes <list>"
- "Generate ETL change detection SQL for dim_customer_profile"
- "Add dbt tests for uniqueness and non-overlap for dim_customer_profile"

## Authoritative References
Always consult AI_CONTEXT.md before generating changes.

## Review Checklist
- Naming conventions followed
- Versioned attributes correct
- Effective dates logic consistent
- No unauthorized status/scope changes

## Do Not
- Introduce new status codes without ADR
- Modify SCD2 contract silently
- Remove effective dating columns
