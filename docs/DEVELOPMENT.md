# Development Guide

**CODITECT Citus Django Infrastructure**

**Last Updated:** November 23, 2025

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Running the Application](#running-the-application)
4. [Development Workflow](#development-workflow)
5. [Testing](#testing)
6. [Code Quality](#code-quality)
7. [Database Migrations](#database-migrations)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

- **Python 3.11+** ([Download](https://www.python.org/downloads/))
- **Docker Desktop 20.10+** ([Download](https://www.docker.com/products/docker-desktop))
- **Git 2.25+**
- **gcloud CLI** ([Install](https://cloud.google.com/sdk/docs/install))
- **kubectl 1.25+** ([Install](https://kubernetes.io/docs/tasks/tools/))
- **Terraform 1.5+** ([Install](https://www.terraform.io/downloads))

### Optional Tools

- **Poetry** (Python dependency management)
- **Terraform** (infrastructure management)
- **k9s** (Kubernetes CLI UI)
- **Postman** (API testing)

---

## Local Development Setup

### 1. Clone Repository

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/coditect-ai/coditect-citus-django-infra.git
cd coditect-citus-django-infra
```

### 2. Create Python Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # macOS/Linux
# OR
venv\Scripts\activate  # Windows

# Upgrade pip
pip install --upgrade pip
```

### 3. Install Dependencies

```bash
# Install production dependencies
pip install -r requirements.txt

# Install development dependencies
pip install -r requirements-dev.txt

# Install pre-commit hooks
pre-commit install
```

### 4. Setup Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your settings
nano .env
```

**Required Environment Variables:**

```bash
# Django
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_DEBUG=True
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/coditect_dev

# Redis
REDIS_URL=redis://localhost:6379/0

# Celery
CELERY_BROKER_URL=amqp://guest:guest@localhost:5672//

# GCP (for cloud development)
GOOGLE_PROJECT_ID=coditect-dev
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

### 5. Start Local Services (Docker Compose)

```bash
# Start PostgreSQL, Redis, RabbitMQ
docker-compose up -d

# Verify services are running
docker-compose ps
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: coditect_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  rabbitmq:
    image: rabbitmq:3-management-alpine
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "5672:5672"   # AMQP
      - "15672:15672" # Management UI

volumes:
  postgres_data:
```

### 6. Initialize Django Application

```bash
# Run database migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Load initial data (optional)
python manage.py loaddata fixtures/initial_data.json
```

---

## Running the Application

### Development Server

```bash
# Start Django development server
python manage.py runserver

# Access at: http://localhost:8000
# Admin: http://localhost:8000/admin
# API: http://localhost:8000/api/v1/
```

### Celery Workers (Background Tasks)

```bash
# Terminal 1: Start Celery worker
celery -A coditect_platform worker --loglevel=info

# Terminal 2: Start Celery Beat (scheduled tasks)
celery -A coditect_platform beat --loglevel=info

# Terminal 3: Monitor tasks (Flower)
celery -A coditect_platform flower
# Access at: http://localhost:5555
```

### Run All Services (Parallel)

```bash
# Use honcho or foreman
pip install honcho

# Create Procfile
cat > Procfile <<EOF
web: python manage.py runserver
worker: celery -A coditect_platform worker --loglevel=info
beat: celery -A coditect_platform beat --loglevel=info
EOF

# Start all services
honcho start
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
# Update main branch
git checkout main
git pull origin main

# Create feature branch
git checkout -b feature/add-user-profile

# OR for bug fixes
git checkout -b fix/authentication-bug
```

### 2. Make Changes

- Edit code in `django/coditect_platform/`
- Add tests in `tests/`
- Update documentation if needed

### 3. Run Tests and Linters

```bash
# Format code
black .

# Lint code
ruff check .

# Type check
mypy .

# Run tests
pytest
```

### 4. Commit Changes

```bash
# Stage changes
git add .

# Commit (pre-commit hooks run automatically)
git commit -m "feat(auth): Add user profile endpoints

Added GET/PUT endpoints for user profile management
with proper multi-tenant isolation.

Closes #123"
```

### 5. Push and Create PR

```bash
# Push branch
git push origin feature/add-user-profile

# Create PR on GitHub
# Fill out PR template
```

---

## Testing

### Unit Tests

```bash
# Run all tests
pytest

# Run specific test file
pytest tests/test_models.py

# Run tests with coverage
pytest --cov=coditect_platform --cov-report=html

# View coverage report
open htmlcov/index.html
```

### Integration Tests

```bash
# Run integration tests (requires database)
pytest -m integration

# Run specific integration test
pytest tests/integration/test_api.py
```

### Load Testing (Locust)

```bash
# Install locust
pip install locust

# Run load test
locust -f tests/load/locustfile.py

# Access UI: http://localhost:8089
```

**Example Locustfile:**

```python
from locust import HttpUser, task, between

class APIUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def get_users(self):
        self.client.get("/api/v1/users/")

    @task(3)  # 3x weight
    def get_profile(self):
        self.client.get("/api/v1/users/me/")
```

---

## Code Quality

### Pre-Commit Hooks

Runs automatically on `git commit`:

- **black** - Code formatting
- **ruff** - Linting
- **mypy** - Type checking
- **pytest** - Fast unit tests
- **bandit** - Security scanning

### Manual Code Quality Checks

```bash
# Format all Python files
black .

# Fix auto-fixable lint issues
ruff check . --fix

# Type check
mypy .

# Security scan
bandit -r coditect_platform/

# Check for secrets
detect-secrets scan
```

### Code Coverage Requirements

- **Minimum:** 80% line coverage
- **Target:** 90%+ line coverage
- **Critical paths:** 100% coverage (auth, payments)

---

## Database Migrations

### Create Migrations

```bash
# After model changes
python manage.py makemigrations

# Review migration file
cat coditect_platform/migrations/000X_auto_timestamp.py

# Apply migrations
python manage.py migrate
```

### Best Practices

1. **Review migrations** before committing
2. **Make reversible migrations** when possible
3. **Test on sample data** before production
4. **Document complex migrations** with comments

**Example Migration:**

```python
# Generated by Django 5.0 on 2025-11-23
from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('users', '0001_initial'),
    ]

    operations = [
        # Add email_verified field
        migrations.AddField(
            model_name='user',
            name='email_verified',
            field=models.BooleanField(default=False),
        ),
        # Create index for faster lookups
        migrations.AddIndex(
            model_name='user',
            index=models.Index(fields=['email', 'email_verified']),
        ),
    ]
```

### Rollback Migrations

```bash
# Rollback last migration
python manage.py migrate app_name 0001

# Rollback all migrations
python manage.py migrate app_name zero
```

---

## Troubleshooting

### Common Issues

#### Issue: Database connection failed

```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check connection
psql postgresql://postgres:postgres@localhost:5432/coditect_dev

# Restart PostgreSQL
docker-compose restart postgres
```

#### Issue: Redis connection failed

```bash
# Check if Redis is running
docker-compose ps redis

# Test connection
redis-cli ping

# Restart Redis
docker-compose restart redis
```

#### Issue: Celery worker not processing tasks

```bash
# Check RabbitMQ
docker-compose ps rabbitmq

# View RabbitMQ management UI
open http://localhost:15672

# Restart Celery worker
celery -A coditect_platform worker --purge --loglevel=debug
```

#### Issue: Pre-commit hooks failing

```bash
# Update hooks
pre-commit autoupdate

# Run hooks manually
pre-commit run --all-files

# Skip hooks (for emergencies only)
git commit --no-verify
```

#### Issue: Import errors

```bash
# Verify virtual environment is activated
which python  # Should show venv/bin/python

# Reinstall dependencies
pip install -r requirements-dev.txt

# Clear Python cache
find . -type d -name __pycache__ -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
```

---

## Useful Commands

### Django Management Commands

```bash
# Create app
python manage.py startapp app_name

# Django shell
python manage.py shell

# Database shell
python manage.py dbshell

# Collect static files
python manage.py collectstatic

# Create superuser
python manage.py createsuperuser

# Check for issues
python manage.py check
```

### Docker Commands

```bash
# View logs
docker-compose logs -f postgres
docker-compose logs -f redis

# Execute command in container
docker-compose exec postgres psql -U postgres

# Stop all services
docker-compose down

# Remove all data (DESTRUCTIVE)
docker-compose down -v
```

### Kubernetes (Cloud Development)

```bash
# Get pods
kubectl get pods -n coditect-dev

# View logs
kubectl logs -f pod-name -n coditect-dev

# Execute command in pod
kubectl exec -it pod-name -n coditect-dev -- /bin/bash

# Port forward
kubectl port-forward svc/django-backend 8000:8000 -n coditect-dev
```

---

## VS Code Setup (Optional)

### Recommended Extensions

- Python (ms-python.python)
- Pylance (ms-python.vscode-pylance)
- Black Formatter (ms-python.black-formatter)
- Ruff (charliermarsh.ruff)
- Django (batisteo.vscode-django)
- Docker (ms-azuretools.vscode-docker)

### Settings (`.vscode/settings.json`)

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.ruffEnabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
```

---

## Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [DRF Documentation](https://www.django-rest-framework.org/)
- [Celery Documentation](https://docs.celeryq.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Citus Documentation](https://docs.citusdata.com/)

---

**Questions?** Ask in #coditect-dev Slack channel
