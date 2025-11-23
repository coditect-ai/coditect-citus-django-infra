# Contributing to CODITECT Citus Django Infrastructure

Thank you for your interest in contributing to the CODITECT Citus Django Infrastructure project!

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a branch** for your changes: `git checkout -b feature/your-feature-name`
4. **Make your changes** following our guidelines below
5. **Test your changes** thoroughly
6. **Submit a pull request** with a clear description

## Development Setup

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for detailed setup instructions.

Quick start:
```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/coditect-citus-django-infra.git
cd coditect-citus-django-infra

# Setup Python environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install

# Run tests
pytest
```

## Code Quality Standards

### Python Code

- **Formatting:** Use Black (line length 100)
- **Linting:** Use Ruff (configured in .ruff.toml)
- **Type Checking:** Use mypy (strict mode)
- **Testing:** pytest with >80% coverage

Run before committing:
```bash
black .
ruff check .
mypy .
pytest
```

### Terraform Code

- **Formatting:** Run `terraform fmt` on all .tf files
- **Validation:** Run `terraform validate` before committing
- **Documentation:** Include comments for complex logic
- **Variables:** Document all variables with descriptions

### Kubernetes Manifests

- **Validation:** Use `kubectl apply --dry-run=client`
- **Labels:** Consistent labeling (app, environment, version, component)
- **Resources:** Always define requests and limits
- **Security:** Use security contexts, non-root containers

## Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Examples:**
```
feat(terraform): Add GKE autopilot cluster module

Added Terraform module for GKE autopilot cluster with
auto-scaling and workload identity enabled.

Closes #123

---

fix(kubernetes): Correct resource limits for Django pods

Django pods were OOMKilled due to insufficient memory limits.
Increased from 512Mi to 1Gi based on profiling.

Fixes #456
```

## Pull Request Process

1. **Update documentation** if you changed APIs or behavior
2. **Add tests** for new features or bug fixes
3. **Ensure CI passes** (all tests, linting, type checking)
4. **Request review** from at least one maintainer
5. **Address feedback** promptly and respectfully
6. **Squash commits** before merging (if requested)

### PR Template

When creating a PR, fill out the template:
- **Description:** What does this PR do?
- **Motivation:** Why is this change needed?
- **Testing:** How was this tested?
- **Screenshots:** If applicable (for UI changes)
- **Checklist:** Mark all completed items

## Code Review Guidelines

### As a Reviewer

- **Be respectful** and constructive
- **Explain why** when requesting changes
- **Approve** if changes look good (minor nits OK)
- **Request changes** if blockers exist
- **Respond within 24 hours** (during work week)

### As an Author

- **Respond to all comments** (even if just "done")
- **Don't take it personally** - reviews improve code quality
- **Ask questions** if feedback unclear
- **Update the PR** based on feedback
- **Notify reviewers** when ready for re-review

## Testing Requirements

### Unit Tests

- **Coverage:** Aim for >80% line coverage
- **Isolation:** Mock external dependencies
- **Fast:** Unit tests should complete in <10 seconds

```python
# Example pytest test
def test_tenant_creation():
    tenant = Tenant.objects.create(name="Test Tenant")
    assert tenant.schema_name == "test_tenant"
    assert tenant.is_active is True
```

### Integration Tests

- **Database:** Use pytest-django with transaction support
- **APIs:** Test full request/response cycle
- **Fixtures:** Use factories (factory_boy) for test data

### Infrastructure Tests

- **Terraform:** Use `terraform plan` and validate output
- **Kubernetes:** Use `kubectl apply --dry-run=client`

## Documentation

### Code Documentation

- **Docstrings:** Use Google-style docstrings for Python
- **Comments:** Explain "why", not "what"
- **Type hints:** Use for all function signatures

```python
def create_tenant(name: str, domain: str) -> Tenant:
    """
    Create a new tenant organization.

    Args:
        name: Human-readable tenant name
        domain: Unique domain for the tenant

    Returns:
        Created Tenant instance

    Raises:
        ValidationError: If domain already exists
    """
    ...
```

### Architecture Documentation

Update [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for:
- New services or components
- Changes to data flow
- Infrastructure changes
- Security-relevant changes

## Issue Reporting

### Bug Reports

Use the bug report template and include:
- **Description:** What went wrong?
- **Steps to reproduce:** Exact steps to trigger the bug
- **Expected behavior:** What should have happened?
- **Actual behavior:** What actually happened?
- **Environment:** OS, Python version, dependencies
- **Logs/Screenshots:** If applicable

### Feature Requests

Use the feature request template and include:
- **Problem statement:** What problem does this solve?
- **Proposed solution:** How should this work?
- **Alternatives considered:** What else could work?
- **Additional context:** Links, screenshots, etc.

## Security

**DO NOT** report security vulnerabilities publicly.

Instead:
1. Email security@coditect.ai with details
2. Include "SECURITY" in subject line
3. We'll respond within 48 hours
4. Coordinate disclosure timeline

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

- **Slack:** #coditect-infrastructure
- **GitHub Discussions:** For general questions
- **Email:** dev@coditect.ai

---

Thank you for contributing to CODITECT! 🚀
