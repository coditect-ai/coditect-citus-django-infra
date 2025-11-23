# Local Development Guide

**CODITECT Citus Django Infrastructure**

**Last Updated:** November 23, 2025

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Docker Compose Development](#docker-compose-development)
4. [GCP Integration](#gcp-integration)
5. [Database Management](#database-management)
6. [Running Tests](#running-tests)
7. [Debugging](#debugging)
8. [Common Tasks](#common-tasks)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

Before starting local development, ensure you have these tools installed:

```bash
# Verify installation
./scripts/verify-tools.sh
```

**Required:**
- Git 2.25+
- Docker Desktop 4.0+
- Python 3.10+
- gcloud CLI
- kubectl
- Terraform 1.5+
- Helm 3.0+

**Optional but recommended:**
- Poetry (Python dependency management)
- pre-commit (Git hooks)
- direnv (Environment variable management)
- pgcli (Enhanced PostgreSQL CLI)

### Install Missing Tools

Run the automated installation script:

```bash
./scripts/install-tools.sh
```

---

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/coditect-ai/coditect-citus-django-infra.git
cd coditect-citus-django-infra
```

### 2. Create Environment File

```bash
# Copy example environment file
cp .env.example .env

# Edit with your settings
nano .env  # or vim, code, etc.
```

### 3. Configure GCP Credentials

```bash
# Authenticate with GCP
gcloud auth login

# Set default project
gcloud config set project coditect-dev

# Download service account key (for local development only)
# This should be done via ./scripts/iam-setup.sh
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/keys/coditect-dev-terraform-key.json
```

### 4. Install Python Dependencies

**Using Poetry (recommended):**

```bash
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Install dependencies
poetry install

# Activate virtual environment
poetry shell
```

**Using pip:**

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### 5. Setup Pre-commit Hooks

```bash
# Install pre-commit hooks
pre-commit install

# Test hooks
pre-commit run --all-files
```

---

## Docker Compose Development

### Quick Start

The fastest way to get a local development environment running is with Docker Compose:

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

### Services Included

The `docker-compose.yml` includes:

- **PostgreSQL 15** - Database (port 5432)
- **Redis 7** - Cache and message broker (port 6379)
- **RabbitMQ** - Task queue (port 5672, management UI: 15672)
- **Django** - Application server (port 8000)
- **Celery Worker** - Background tasks
- **Celery Beat** - Scheduled tasks
- **Prometheus** - Metrics collection (port 9090)
- **Grafana** - Metrics visualization (port 3000)

### Accessing Services

```bash
# Django API
curl http://localhost:8000/api/v1/health/

# Django Admin
open http://localhost:8000/admin/

# RabbitMQ Management
open http://localhost:15672/  # guest/guest

# Grafana
open http://localhost:3000/  # admin/admin

# Prometheus
open http://localhost:9090/
```

### Development Workflow

```bash
# Rebuild after code changes
docker-compose up -d --build

# Run migrations
docker-compose exec django python manage.py migrate

# Create superuser
docker-compose exec django python manage.py createsuperuser

# Run Django shell
docker-compose exec django python manage.py shell

# Run tests
docker-compose exec django pytest

# View logs for specific service
docker-compose logs -f django
docker-compose logs -f celery
```

---

## GCP Integration

### Local Development with Cloud SQL Proxy

Connect to GCP Cloud SQL from your local machine:

```bash
# Install Cloud SQL Proxy
curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
chmod +x cloud_sql_proxy

# Get connection name
gcloud sql instances describe coditect-postgres-dev \
    --format="value(connectionName)"

# Run proxy
./cloud_sql_proxy -instances=coditect-dev:us-central1:coditect-postgres-dev=tcp:5432

# In another terminal, connect
psql -h 127.0.0.1 -U django coditect_dev
```

### Testing with GKE Cluster

```bash
# Get cluster credentials
gcloud container clusters get-credentials coditect-gke-dev \
    --region=us-central1

# Verify connection
kubectl get nodes

# Deploy to dev cluster
kubectl apply -k kubernetes/base/
kubectl apply -k kubernetes/services/

# Port-forward to local
kubectl port-forward service/django-api 8000:8000
```

### Using GCS Locally

```bash
# Set environment variables
export USE_GCS_STORAGE=True
export GCS_BUCKET_NAME=coditect-dev-static

# Test upload
python manage.py collectstatic --noinput

# List files
gsutil ls gs://coditect-dev-static/
```

---

## Database Management

### Using Local PostgreSQL (Docker)

```bash
# Connect to database
docker-compose exec postgres psql -U postgres coditect_dev

# Or use pgcli (better UX)
pgcli postgresql://postgres:postgres@localhost:5432/coditect_dev
```

### Running Migrations

```bash
# Create migration
docker-compose exec django python manage.py makemigrations

# Apply migrations
docker-compose exec django python manage.py migrate

# Show migration status
docker-compose exec django python manage.py showmigrations
```

### Database Fixtures

```bash
# Load fixtures
docker-compose exec django python manage.py loaddata fixtures/dev-data.json

# Create fixtures
docker-compose exec django python manage.py dumpdata \
    --indent=2 \
    --natural-foreign \
    --natural-primary \
    > fixtures/dev-data.json
```

### Reset Database

```bash
# Stop services
docker-compose down

# Remove volumes (WARNING: destroys all data)
docker-compose down -v

# Start fresh
docker-compose up -d

# Run migrations
docker-compose exec django python manage.py migrate

# Load fixtures
docker-compose exec django python manage.py loaddata fixtures/dev-data.json
```

---

## Running Tests

### Unit Tests

```bash
# Run all tests
docker-compose exec django pytest

# Run specific test file
docker-compose exec django pytest tests/test_models.py

# Run with coverage
docker-compose exec django pytest --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html
```

### Integration Tests

```bash
# Run integration tests
docker-compose exec django pytest tests/integration/

# Run end-to-end tests
docker-compose exec django pytest tests/e2e/
```

### Performance Tests

```bash
# Run load tests with locust
docker-compose exec django locust -f tests/load/locustfile.py
```

---

## Debugging

### Django Debug Toolbar

```bash
# Enable in .env
ENABLE_DEBUG_TOOLBAR=True

# Restart Django
docker-compose restart django

# Access at http://localhost:8000 (toolbar will appear)
```

### Python Debugger (pdb)

```python
# Add breakpoint in code
import pdb; pdb.set_trace()

# Or use breakpoint() (Python 3.7+)
breakpoint()
```

```bash
# Attach to running container
docker-compose exec django python manage.py runserver 0.0.0.0:8000
```

### VS Code Debugging

Create `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Django: Docker",
            "type": "python",
            "request": "attach",
            "pathMappings": [
                {
                    "localRoot": "${workspaceFolder}",
                    "remoteRoot": "/app"
                }
            ],
            "port": 5678,
            "host": "localhost"
        }
    ]
}
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f django
docker-compose logs -f celery

# Last 100 lines
docker-compose logs --tail=100 django
```

---

## Common Tasks

### Create Django App

```bash
docker-compose exec django python manage.py startapp myapp
```

### Create Superuser

```bash
docker-compose exec django python manage.py createsuperuser
```

### Collect Static Files

```bash
docker-compose exec django python manage.py collectstatic --noinput
```

### Run Django Shell

```bash
# Standard shell
docker-compose exec django python manage.py shell

# Shell Plus (with auto-imports)
docker-compose exec django python manage.py shell_plus
```

### Clear Cache

```bash
# Django cache
docker-compose exec django python manage.py clear_cache

# Redis cache
docker-compose exec redis redis-cli FLUSHALL
```

### Monitor Celery Tasks

```bash
# Celery events (real-time)
docker-compose exec celery celery -A coditect_platform events

# Flower (web UI)
docker-compose exec celery celery -A coditect_platform flower
open http://localhost:5555/
```

---

## Troubleshooting

### Port Already in Use

```bash
# Find process using port 8000
lsof -i :8000

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Database Connection Errors

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Restart database
docker-compose restart postgres
```

### Permission Denied Errors

```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# For Docker volumes
docker-compose down
docker volume rm coditect-citus-django-infra_postgres_data
docker-compose up -d
```

### "Module not found" Errors

```bash
# Rebuild containers
docker-compose up -d --build

# Or reinstall dependencies
docker-compose exec django pip install -r requirements.txt
```

### Slow Performance

```bash
# Check Docker resources
# Docker Desktop → Preferences → Resources
# Increase CPU/Memory allocation

# Clean up Docker
docker system prune -a

# Optimize database
docker-compose exec postgres vacuumdb -U postgres -d coditect_dev -z
```

### GCP Authentication Issues

```bash
# Re-authenticate
gcloud auth login
gcloud auth application-default login

# Verify credentials
gcloud auth list

# Check service account
gcloud iam service-accounts list
```

---

## Best Practices

### Code Quality

```bash
# Format code
black .
isort .

# Lint
flake8 .
pylint coditect_platform/

# Type checking
mypy .
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/my-feature

# Commit changes (pre-commit hooks run automatically)
git add .
git commit -m "feat: Add my feature"

# Push to remote
git push origin feature/my-feature
```

### Environment Variables

```bash
# Use direnv for automatic environment loading
echo "dotenv" > .envrc
direnv allow

# Now .env is loaded automatically when you cd into the directory
```

---

## Next Steps

1. **Review Architecture**: Read [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Deploy to Dev**: Follow [GCP-SETUP.md](GCP-SETUP.md)
3. **Production Deployment**: See [DEPLOYMENT.md](DEPLOYMENT.md)
4. **Security**: Review [SECURITY.md](SECURITY.md)

---

## Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Celery Documentation](https://docs.celeryq.dev/)

---

**Document Owner:** CODITECT Development Team
**Review Cycle:** Monthly
**Next Review:** December 2025
