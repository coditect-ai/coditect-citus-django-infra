# CLAUDE.md - CODITECT Citus Django Infrastructure

## 🔗 Symlink Architecture

**IMPORTANT:** `.claude` IS `.coditect` via symlinks!
- `.coditect -> ../../../.coditect` (master repo reference)
- `.claude -> .coditect` (Claude Code compatibility)

All CODITECT framework components (52 agents, 81 commands, 26 skills) are **directly accessible**.

---

## Project Overview

**CODITECT Citus Django Infrastructure** provides Infrastructure-as-Code (IaC) for deploying a hyperscale, multi-tenant SaaS platform capable of serving **1 million+ tenant organizations**.

### Purpose

- **GCP/GKE Infrastructure:** Terraform modules for Google Cloud Platform resources
- **Citus Deployment:** Distributed PostgreSQL cluster configuration
- **Django Backend:** Kubernetes deployments for Django + django-multitenant
- **Microservices:** Auth (Ory Hydra), Billing, Core API services
- **Observability:** Prometheus, Grafana, Jaeger monitoring stack

### Development Status

**Status:** Initial Setup (Active)
**Phase:** Phase 0 - Foundation
**Completion:** 5%

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **IaC** | Terraform 1.5+ | GCP resource provisioning |
| **Orchestration** | Kubernetes (GKE) | Container management |
| **Database** | Citus (PostgreSQL extension) | Distributed database |
| **Backend** | Django 5.x + django-multitenant | Multi-tenant application |
| **Auth** | Ory Hydra + Authlib | OAuth2/OIDC server |
| **Caching** | Redis Cluster | Distributed caching |
| **Monitoring** | Prometheus + Grafana + Jaeger | Observability |

---

## Key Features

### Hyperscale Architecture
- **1M+ tenant organizations** supported
- **Horizontal sharding** via Citus
- **Auto-scaling** Kubernetes deployments
- **Multi-zone** high availability

### Infrastructure as Code
- **Terraform modules** for all GCP resources
- **Environment separation** (dev, staging, production)
- **GitOps workflow** for infrastructure changes
- **Automated testing** with Terraform validation

### Open Source
- **MIT License** - fully open source
- **Citus:** AGPL v3.0 (open source PostgreSQL extension)
- **No vendor lock-in** - deploy anywhere

---

## Directory Structure

```
coditect-citus-django-infra/
├── opentofu/               # Infrastructure as Code
│   ├── modules/            # Reusable OpenTofu modules
│   │   ├── gke/           # GKE cluster module
│   │   ├── citus/         # Citus cluster module
│   │   ├── redis/         # Redis cluster module
│   │   └── networking/    # VPC, subnets, firewall
│   └── environments/       # Environment-specific configs
│       ├── dev/
│       ├── staging/
│       └── production/
├── kubernetes/             # Kubernetes manifests
│   ├── base/              # Base configurations
│   ├── services/          # Service deployments
│   ├── ingress/           # API gateway (Kong)
│   └── monitoring/        # Observability stack
├── citus/                  # Citus-specific configs
│   ├── setup/             # Cluster initialization
│   ├── migrations/        # Schema migrations
│   └── sharding/          # Shard management
├── monitoring/             # Monitoring configurations
├── scripts/                # Automation scripts
├── docs/                   # Documentation
├── PROJECT-PLAN.md         # Implementation roadmap
└── TASKLIST.md             # Task tracking
```

---

## Distributed Intelligence Integration

### Available CODITECT Components

This repository has access to the complete CODITECT framework via `.coditect` symlink:

**52 Specialized Agents:**
- `devops-engineer` - Infrastructure automation specialist
- `cloud-architect` - GCP/GKE architecture expert
- `database-architect` - PostgreSQL/Citus specialist
- `security-specialist` - Infrastructure security
- `monitoring-specialist` - Observability stack

**81 Slash Commands:**
- `/implement` - Infrastructure code generation
- `/analyze` - Architecture review
- `/security_sast` - Security scanning
- `/optimize` - Cost and performance optimization

**26 Production Skills:**
- `production-patterns` - Circuit breakers, retry logic
- `framework-patterns` - Infrastructure patterns
- `deployment-automation` - CI/CD workflows

---

## Quick Start for AI Agents

### Essential Reading Order

1. **README.md** - Project overview and quick start
2. **PROJECT-PLAN.md** - 3-phase implementation roadmap
3. **TASKLIST.md** - Current progress and priorities
4. **docs/ARCHITECTURE.md** - System architecture (when created)

### Before Making Changes

1. **Read current infrastructure state:**
   ```bash
   cd opentofu/environments/dev
   tofu show
   ```

2. **Check Kubernetes cluster:**
   ```bash
   kubectl get all -A
   ```

3. **Review PROJECT-PLAN.md** for current phase

4. **Check TASKLIST.md** for active tasks

---

## Development Guidelines

### Terraform Standards

- **Format:** Run `tofu fmt` before commit
- **Validation:** Run `tofu validate` on all modules
- **Planning:** Always run `tofu plan` before apply
- **State:** Never commit `terraform.tfstate` files
- **Secrets:** Use GCP Secret Manager, never hardcode

### Kubernetes Standards

- **Namespaces:** Separate dev, staging, production
- **Labels:** Consistent labeling (app, environment, version)
- **Resources:** Define requests and limits for all containers
- **Security:** Use security contexts, non-root containers
- **ConfigMaps:** Externalize configuration

### Citus Standards

- **Shard Key:** Always use `tenant_id` for sharding
- **Co-location:** Keep related tables co-located by tenant
- **Rebalancing:** Plan shard rebalancing during low-traffic windows
- **Monitoring:** Monitor shard distribution and query performance

---

## Common Tasks

### Deploy Infrastructure (Development)

```bash
# Navigate to dev environment
cd opentofu/environments/dev

# Initialize OpenTofu
tofu init

# Plan changes
tofu plan -out=tfplan

# Apply changes
tofu apply tfplan
```

### Deploy Kubernetes Resources

```bash
# Deploy base configuration
kubectl apply -k kubernetes/base

# Deploy services
kubectl apply -k kubernetes/services

# Check deployment status
kubectl get pods -A
```

### Add Citus Worker Node

```bash
# Update OpenTofu configuration
cd opentofu/modules/citus
# Edit variables.tf to increase worker_count

# Apply change
cd ../../environments/production
tofu apply

# Verify in Citus
psql -h citus-coordinator -c "SELECT * FROM citus_get_active_worker_nodes();"
```

### Scale Kubernetes Deployment

```bash
# Scale Django backend
kubectl scale deployment django-backend --replicas=10 -n coditect-production

# Check status
kubectl rollout status deployment/django-backend -n coditect-production
```

---

## AI Agent Workflows

### When Implementing Infrastructure

1. **Phase 1 (Current):**
   - Focus on Terraform modules for GKE, Citus, Redis
   - Create base Kubernetes manifests
   - Setup monitoring stack

2. **Use These Agents:**
   - `devops-engineer` - Infrastructure automation
   - `cloud-architect` - GCP best practices
   - `database-architect` - Citus configuration

3. **Update Progress:**
   - Mark tasks complete in TASKLIST.md
   - Update PROJECT-PLAN.md status
   - Create checkpoints in MEMORY-CONTEXT

### When Reviewing Code

1. **Security Review:**
   - Use `/security_sast` command
   - Check for exposed secrets
   - Validate RBAC policies

2. **Cost Optimization:**
   - Use `/optimize` command
   - Review instance sizes
   - Check for unused resources

3. **Architecture Review:**
   - Use `/analyze` command
   - Validate against PROJECT-PLAN.md
   - Check scalability patterns

---

## Integration Points

### With coditect-cloud-backend

**Dependency:** This infrastructure hosts the backend service
- Backend deployed to GKE cluster
- Connects to Citus database
- Uses Redis for caching

### With Master Repo

**Context Sharing:** Via .coditect symlinks
- Access to all CODITECT agents/commands/skills
- Shared PROJECT-PLAN.md and TASKLIST.md tracking
- Memory continuity via MEMORY-CONTEXT

---

## Environment Variables

**Required for Terraform:**
- `GOOGLE_PROJECT_ID` - GCP project ID
- `GOOGLE_REGION` - Default GCP region
- `GOOGLE_APPLICATION_CREDENTIALS` - Service account key path

**Required for Kubernetes:**
- `KUBE_CONFIG_PATH` - Kubernetes config file path
- `CLUSTER_NAME` - GKE cluster name
- `CLUSTER_REGION` - GKE cluster region

---

## Security Best Practices

### Secrets Management

- ✅ Use GCP Secret Manager for all secrets
- ✅ Rotate credentials quarterly
- ✅ Never commit secrets to git
- ✅ Use Kubernetes secrets for runtime config

### Network Security

- ✅ Private GKE cluster (no public IPs)
- ✅ VPC peering for database access
- ✅ Firewall rules (least privilege)
- ✅ TLS for all service communication

### Access Control

- ✅ Kubernetes RBAC policies
- ✅ GCP IAM roles (service accounts)
- ✅ Audit logging enabled
- ✅ Multi-factor authentication required

---

## Monitoring & Alerts

### Prometheus Metrics

- GKE cluster health
- Citus database performance
- Redis cache hit rates
- API response times

### Grafana Dashboards

- Infrastructure overview
- Database sharding status
- Service dependencies
- Cost tracking

### Alert Rules

- Pod crash loops
- High memory usage (>80%)
- Database connection pool exhaustion
- Shard imbalance

---

## Cost Tracking

### Monthly Cost Estimates

**Development:**
- GKE: $150/month
- Citus: $500/month
- Redis: $100/month
- Monitoring: $50/month
- **Total:** ~$800/month

**Production (1M tenants):**
- GKE: $5,000/month
- Citus: $40,000/month
- Redis: $1,000/month
- Monitoring: $500/month
- **Total:** ~$46,500/month

**Optimization Tips:**
- Use preemptible VMs for workers
- Enable auto-scaling (scale down at night)
- Use committed use discounts
- Archive old data to Cloud Storage

---

## Troubleshooting

### Common Issues

**Terraform apply fails:**
```bash
# Check GCP quota limits
gcloud compute project-info describe --project=PROJECT_ID

# Verify service account permissions
gcloud projects get-iam-policy PROJECT_ID
```

**Kubernetes pods not starting:**
```bash
# Check pod events
kubectl describe pod POD_NAME -n NAMESPACE

# View logs
kubectl logs POD_NAME -n NAMESPACE
```

**Citus connection issues:**
```bash
# Test coordinator connection
psql -h citus-coordinator -p 5432 -U postgres

# Check worker nodes
SELECT * FROM citus_get_active_worker_nodes();
```

---

## Support & Resources

### Documentation

- **Terraform:** https://registry.terraform.io/providers/hashicorp/google/latest/docs
- **GKE:** https://cloud.google.com/kubernetes-engine/docs
- **Citus:** https://docs.citusdata.com/
- **Kubernetes:** https://kubernetes.io/docs/

### Internal Docs

- `docs/ARCHITECTURE.md` - System architecture
- `docs/DEPLOYMENT.md` - Deployment procedures
- `docs/SCALING.md` - Scaling strategies
- `docs/TROUBLESHOOTING.md` - Common issues

---

## Related Repositories

- **coditect-cloud-backend** - Django backend application
- **coditect-cloud-frontend** - Admin dashboard UI
- **coditect-rollout-master** - Master orchestration repo

---

**Last Updated:** November 23, 2025
**Status:** Active Development
**Owner:** AZ1.AI INC
**License:** MIT
