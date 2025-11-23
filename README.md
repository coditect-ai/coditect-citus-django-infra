# coditect-citus-django-infra

**Open Source Infrastructure for 1M+ Tenant Hyperscale SaaS Platform**

## Overview

Infrastructure-as-Code for deploying CODITECT's hyperscale multi-tenant architecture on Google Kubernetes Engine (GKE) using Citus (distributed PostgreSQL) and Django.

**Scale Target:** 1 million+ tenant organizations
**Architecture:** Microservices with shared-table multi-tenancy
**Cloud Provider:** Google Cloud Platform (GCP)
**License:** Open Source (MIT)

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Backend Framework** | Django 5.x + django-multitenant | Multi-tenant application layer |
| **Database** | Citus (Distributed PostgreSQL) | Horizontally sharded data storage |
| **Orchestration** | Kubernetes (GKE) | Container management and auto-scaling |
| **Infrastructure** | Terraform | GCP resource provisioning |
| **Authentication** | Ory Hydra + Authlib | Distributed OAuth2/OIDC |
| **Caching** | Redis Cluster | Distributed caching |
| **Monitoring** | Prometheus + Grafana + Jaeger | Observability stack |
| **API Gateway** | Kong | Rate limiting, routing |

---

## Repository Structure

```
coditect-citus-django-infra/
├── .coditect/               # Distributed intelligence (symlink to master)
├── .claude/                 # Claude Code compatibility (symlink)
├── opentofu/               # Infrastructure as Code
│   ├── modules/            # Reusable Terraform modules
│   │   ├── gke/           # GKE cluster configuration
│   │   ├── citus/         # Citus coordinator + workers
│   │   ├── redis/         # Redis cluster
│   │   └── networking/    # VPC, subnets, firewall
│   ├── environments/       # Environment-specific configs
│   │   ├── dev/           # Development environment
│   │   ├── staging/       # Staging environment
│   │   └── production/    # Production environment
│   └── README.md          # Terraform documentation
├── kubernetes/             # Kubernetes manifests
│   ├── base/              # Base configurations
│   │   ├── namespaces/    # Namespace definitions
│   │   ├── rbac/          # Role-based access control
│   │   └── secrets/       # Secret management
│   ├── services/          # Service deployments
│   │   ├── auth/          # Ory Hydra authentication
│   │   ├── backend/       # Django application
│   │   ├── billing/       # Billing service
│   │   └── workers/       # Celery workers
│   ├── ingress/           # Kong API gateway
│   ├── monitoring/        # Prometheus, Grafana, Jaeger
│   └── README.md          # Kubernetes documentation
├── citus/                  # Citus-specific configurations
│   ├── setup/             # Initial Citus cluster setup
│   ├── migrations/        # Schema migration scripts
│   ├── sharding/          # Shard management scripts
│   └── README.md          # Citus documentation
├── monitoring/             # Monitoring configurations
│   ├── prometheus/        # Prometheus configs
│   ├── grafana/           # Grafana dashboards
│   └── jaeger/            # Jaeger tracing
├── scripts/                # Automation scripts
│   ├── setup.sh           # Initial setup script
│   ├── deploy.sh          # Deployment script
│   └── scale.sh           # Scaling script
├── docs/                   # Documentation
│   ├── ARCHITECTURE.md    # Architecture overview
│   ├── DEPLOYMENT.md      # Deployment guide
│   ├── SCALING.md         # Scaling strategies
│   └── TROUBLESHOOTING.md # Common issues
├── .gitignore              # Git ignore patterns
├── PROJECT-PLAN.md         # Implementation roadmap
├── TASKLIST.md             # Task tracking
├── README.md               # This file
└── CLAUDE.md               # AI agent configuration

```

---

## Quick Start

### Prerequisites

- Google Cloud SDK (`gcloud`)
- Terraform 1.5+
- kubectl 1.28+
- Helm 3.0+
- Docker

### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/coditect-ai/coditect-citus-django-infra.git
cd coditect-citus-django-infra

# 2. Configure GCP credentials
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID

# 3. Initialize Terraform
cd opentofu/environments/dev
terraform init

# 4. Review and apply infrastructure
terraform plan
terraform apply

# 5. Configure kubectl
gcloud container clusters get-credentials coditect-dev --region us-central1

# 6. Deploy Kubernetes resources
kubectl apply -k kubernetes/base
kubectl apply -k kubernetes/services
```

---

## Architecture

### Multi-Tenant Data Isolation

**Shared-Table Model with Citus Sharding:**
- All tenants share the same tables
- Every row has `tenant_id` column
- Citus shards data by `tenant_id` across worker nodes
- Application-level filtering via django-multitenant

### Scaling Strategy

| Tenant Count | Citus Workers | Cost/Month | Team Size |
|--------------|---------------|------------|-----------|
| 0-10K | 3 workers | $2,000 | 2 engineers |
| 10K-100K | 6-10 workers | $10,000 | 3 engineers |
| 100K-1M | 20+ workers | $40,000 | 5 engineers |

### High Availability

- **GKE:** Multi-zone cluster (3 zones)
- **Citus:** Coordinator + worker node redundancy
- **Redis:** Cluster mode with failover
- **Load Balancing:** GCP Cloud Load Balancer

---

## Deployment

### Development Environment

```bash
# Deploy to dev cluster
./scripts/deploy.sh dev

# Check deployment status
kubectl get pods -n coditect-dev

# View logs
kubectl logs -f deployment/django-backend -n coditect-dev
```

### Staging Environment

```bash
# Deploy to staging
./scripts/deploy.sh staging

# Run smoke tests
./scripts/test-staging.sh
```

### Production Environment

```bash
# Production deployment (requires approval)
./scripts/deploy.sh production

# Monitor deployment
kubectl rollout status deployment/django-backend -n coditect-production
```

---

## Cost Optimization

### Infrastructure Costs

**Development:**
- 1 small GKE cluster: $150/month
- 1 Citus coordinator + 3 workers: $500/month
- Redis cluster: $100/month
- **Total:** ~$750/month

**Production (1M tenants):**
- 1 large GKE cluster: $5,000/month
- 1 Citus coordinator + 20 workers: $40,000/month
- Redis cluster: $1,000/month
- Monitoring stack: $500/month
- **Total:** ~$46,500/month

**At $50/tenant/month pricing:**
- Revenue: 1M × $50 = $50M/month
- Infrastructure: $46.5K/month
- Margin: 99.9%

---

## Monitoring & Observability

### Metrics (Prometheus)

- Request latency (p50, p95, p99)
- Error rates by endpoint
- Database connection pool usage
- Citus shard distribution

### Dashboards (Grafana)

- API performance overview
- Database health
- Kubernetes cluster status
- Business metrics (tenants, users, revenue)

### Tracing (Jaeger)

- End-to-end request tracing
- Service dependency mapping
- Performance bottleneck identification

---

## Security

### Best Practices

- **Secrets:** GCP Secret Manager (never commit credentials)
- **Network:** Private GKE cluster, VPC peering
- **Authentication:** mTLS between services
- **Database:** Encrypted at rest and in transit
- **RBAC:** Kubernetes role-based access control

### Compliance

- SOC 2 Type II ready architecture
- GDPR data isolation (tenant-level)
- PCI DSS for payment processing

---

## Migration Path

### Phase 1: PostgreSQL (0-10K tenants)

Start simple with managed Cloud SQL PostgreSQL:
- No Citus complexity
- Fast MVP launch
- Migrate to Citus when needed

### Phase 2: Citus Staging (10K-50K tenants)

Deploy Citus in staging:
- Test migration scripts
- Validate performance
- Train team on Citus operations

### Phase 3: Citus Production (50K-1M+ tenants)

Blue-Green deployment:
- Run old and new infrastructure in parallel
- Gradual tenant migration
- Zero-downtime cutover

---

## Contributing

This is an open source project. Contributions welcome!

### Development Workflow

1. Fork repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards

- Terraform: `terraform fmt` before commit
- Kubernetes: Validate with `kubectl apply --dry-run`
- Scripts: shellcheck validation
- Documentation: Update README for all changes

---

## Support

- **Documentation:** See `docs/` directory
- **Issues:** https://github.com/coditect-ai/coditect-citus-django-infra/issues
- **Discussions:** https://github.com/coditect-ai/coditect-citus-django-infra/discussions

---

## License

MIT License - See LICENSE file for details

**Owner:** AZ1.AI INC
**Maintainers:** CODITECT Infrastructure Team
**Status:** Active Development

---

**Last Updated:** November 23, 2025
**Version:** 0.1.0 (Initial Release)
