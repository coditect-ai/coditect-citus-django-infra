## Description

<!-- Provide a brief description of the changes in this PR -->

## Type of Change

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Infrastructure change
- [ ] Refactoring (no functional changes)

## Motivation and Context

<!-- Why is this change required? What problem does it solve? -->
<!-- If it fixes an open issue, please link to the issue here -->

Fixes # (issue)

## Changes Made

<!-- List the specific changes made in this PR -->

-
-
-

## How Has This Been Tested?

<!-- Describe the tests you ran to verify your changes -->
<!-- Provide instructions so reviewers can reproduce -->

- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing
- [ ] Load testing

**Test Configuration:**
- Python version:
- Django version:
- Database: PostgreSQL / Citus

## Screenshots (if applicable)

<!-- Add screenshots to help explain your changes -->

## Checklist

### Code Quality
- [ ] My code follows the code style of this project (Black, Ruff)
- [ ] I have run `black .` and `ruff check .`
- [ ] I have run `mypy .` with no errors
- [ ] I have added type hints to all function signatures

### Testing
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] I have added pytest fixtures for new models/functionality
- [ ] Test coverage is >= 80% for new code

### Documentation
- [ ] I have updated the documentation accordingly
- [ ] I have added docstrings to new functions/classes (Google style)
- [ ] I have updated CHANGELOG.md (if applicable)
- [ ] I have updated API documentation (if applicable)

### Infrastructure (if applicable)
- [ ] Terraform changes: `terraform fmt` and `terraform validate` pass
- [ ] Kubernetes manifests: `kubectl apply --dry-run=client` passes
- [ ] I have tested infrastructure changes in dev environment
- [ ] I have updated infrastructure documentation

### Dependencies
- [ ] I have updated requirements.txt / pyproject.toml (if adding dependencies)
- [ ] I have run security scan: `bandit -r .`
- [ ] No new critical/high vulnerabilities introduced

### Database Migrations (if applicable)
- [ ] Django migrations created: `python manage.py makemigrations`
- [ ] Migrations are reversible
- [ ] Migrations tested with sample data
- [ ] Migrations documented in commit message

## Deployment Notes

<!-- Any special deployment considerations? -->
<!-- Database migrations required? Configuration changes? -->

## Reviewer Notes

<!-- Anything specific you want reviewers to focus on? -->

## Related PRs

<!-- Link to related PRs in other repositories -->

---

**By submitting this PR, I confirm that:**
- I have read and followed the [CONTRIBUTING.md](../CONTRIBUTING.md) guidelines
- My code adheres to the project's code of conduct
- I agree to the MIT license terms for my contributions
