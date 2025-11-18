---
name: Data Task
about: Add or modify a data modeling / ETL artifact
title: "[Data] <short description>"
labels: ["data", "design"]
---

## Summary
<Describe change or new artifact>

## Classification
- [ ] Fact
- [ ] Dimension (Type 1)
- [ ] Dimension (SCD2)
- [ ] Bridge
- [ ] Audit / Log

## Grain (if Fact)
One row per: <define>

## Attributes / Measures
<List key fields>

## Versioning (if SCD2)
Version-trigger attributes: <list>

## Dependencies
<List upstream tables or contracts>

## Tests Needed
- [ ] Uniqueness
- [ ] Non-overlapping effective dates
- [ ] Foreign keys
- [ ] Value domain / constants

## Acceptance Criteria
<List completion conditions>
