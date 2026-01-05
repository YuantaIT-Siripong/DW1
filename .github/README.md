# GitHub Configuration

**Purpose**: GitHub-specific configuration files (issue templates, PR templates, workflows)  
**Owner**: Repository Administrators  
**Last Updated**: 2026-01-05

---

## Overview

This directory contains configuration files that customize GitHub's behavior for this repository, including:
- Issue templates for structured bug reports and feature requests
- Pull request templates for consistent PR descriptions
- GitHub Actions workflows for CI/CD (if applicable)
- Code owners configuration (CODEOWNERS file at root)

---

## Files Inventory

### Issue Templates

#### ISSUE_TEMPLATE/data_task.md

**Type**: GitHub Issue Template  
**Purpose**: Structured template for creating data-related tasks  
**Used By**: Team members creating issues for:
- New module development
- Data quality issues
- Schema changes
- ETL issues

**Fields Included**:
- Task description
- Acceptance criteria
- Related modules
- Priority
- Dependencies

**How to Use**:
1. Click "New Issue" on GitHub
2. Select "Data Task" template
3. Fill in required fields
4. Submit issue

**Customization**: Edit this file to add/remove fields as needed

### Pull Request Templates

#### PULL_REQUEST_TEMPLATE.md

**Type**: GitHub PR Template  
**Purpose**: Ensures all PRs have consistent, complete descriptions  
**Automatically Applied**: When creating new PR

**Sections Included**:
- Description of changes
- Type of change (bug fix, feature, documentation, etc.)
- Testing performed
- Checklist (documentation updated, tests added, etc.)
- Related issues

**How It Works**:
- Automatically populates PR description field
- Developer fills in each section
- Reviewers use checklist to verify completeness

**Customization**: Edit this file to modify PR requirements

---

## GitHub Actions (Workflows)

**Status**: Not currently implemented  
**Future Plans**: May add workflows for:
- Automated validation on PR (schema validation, naming convention checks)
- Documentation generation on merge
- Automated testing
- Enumeration sync (YAML to CSV seeds)

**Location** (when implemented): `.github/workflows/*.yml`

---

## CODEOWNERS File

**Location**: Root directory (`/CODEOWNERS`)  
**Purpose**: Defines code ownership for automated review assignment

**How It Works**:
- When PR touches certain files/directories, GitHub automatically requests review from designated owners
- Ensures subject matter experts review relevant changes

**Current Ownership** (example):
```
# Data Architecture Team owns core documentation
/docs/                          @data-architecture-team
/contracts/                     @data-architecture-team

# Data Engineering Team owns ETL and dbt
/etl/                           @data-engineering-team
/dbt/                           @data-engineering-team

# All standards require architecture review
/docs/data-modeling/            @data-architecture-team
/docs/architecture/             @data-architecture-team
```

**Maintenance**: Update CODEOWNERS when:
- Team structure changes
- New directories added
- Ownership responsibilities shift

---

## Best Practices

### Issue Templates

**Do**:
- ✅ Keep templates focused and concise
- ✅ Include examples in template comments
- ✅ Make critical fields required
- ✅ Provide clear labels/categories

**Don't**:
- ❌ Make templates too complex
- ❌ Require information that's not always applicable
- ❌ Create too many templates (causes confusion)

### PR Templates

**Do**:
- ✅ Include testing checklist
- ✅ Require documentation updates
- ✅ Link to related issues
- ✅ Specify type of change

**Don't**:
- ❌ Make checklist too long
- ❌ Require irrelevant information
- ❌ Be too prescriptive

---

## Customization Guide

### Adding a New Issue Template

1. Create file: `.github/ISSUE_TEMPLATE/your_template.md`
2. Add YAML front matter:
```markdown
---
name: Your Template Name
about: Description of when to use this template
title: '[PREFIX] '
labels: 'label1, label2'
assignees: 'default-assignee'
---

## Description
[Template content here]
```
3. Commit and push
4. New template appears in "New Issue" dropdown

### Modifying PR Template

1. Edit `.github/PULL_REQUEST_TEMPLATE.md`
2. Commit and push
3. Changes apply to all new PRs

### Adding GitHub Actions

1. Create workflow file: `.github/workflows/your_workflow.yml`
2. Define triggers (on: push, pull_request, etc.)
3. Define jobs and steps
4. Commit and push
5. Workflow runs automatically on trigger

**Example Workflow** (validation on PR):
```yaml
name: Validate Repository

on:
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate Naming Conventions
        run: python scripts/validate_repository.py
```

---

## Troubleshooting

### Issue Template Not Showing

**Problem**: New template not appearing in issue creation  
**Solution**:
- Check YAML front matter syntax
- Ensure file is in `.github/ISSUE_TEMPLATE/`
- Clear browser cache
- Verify file extension is `.md`

### PR Template Not Auto-Filling

**Problem**: PR description blank instead of showing template  
**Solution**:
- Verify file name is exactly `PULL_REQUEST_TEMPLATE.md`
- Check file is in `.github/` directory
- Ensure not using GitHub's web editor (use actual PR creation)

### Workflow Not Triggering

**Problem**: GitHub Action not running  
**Solution**:
- Check workflow syntax with GitHub's validator
- Verify trigger conditions (branches, paths, events)
- Check Actions tab for errors
- Ensure workflows are enabled in repository settings

---

## Related Documentation

- `CODEOWNERS` - Code ownership configuration
- GitHub Docs: [Issue Templates](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/about-issue-and-pull-request-templates)
- GitHub Docs: [GitHub Actions](https://docs.github.com/en/actions)
- Repository Guidelines: `docs/CONTRIBUTION_GUIDE.md` (if exists)

---

## Governance

### Who Can Modify

**Templates**: Repository administrators and maintainers  
**Workflows**: Repository administrators with Actions permissions  
**CODEOWNERS**: Repository administrators

### Change Process

1. Propose changes in issue/PR
2. Discuss with team
3. Get approval from repository administrators
4. Implement and test
5. Document changes in this README

### Review Frequency

- **Quarterly**: Review templates for relevance
- **As needed**: Update workflows when process changes
- **On team changes**: Update CODEOWNERS

---

**Last Updated**: 2026-01-05  
**Maintained By**: Repository Administrators  
**Contact**: Repository admin team for questions or modifications
