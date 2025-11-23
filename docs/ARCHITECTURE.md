# System Architecture

**CODITECT Hyperscale Multi-Tenant SaaS Platform**

**Version:** 1.0
**Last Updated:** November 23, 2025
**Status:** Design Phase

---

## Table of Contents

1. [Overview](#overview)
2. [High-Level Architecture](#high-level-architecture)
3. [Infrastructure Layer](#infrastructure-layer)
4. [Application Layer](#application-layer)
5. [Data Layer](#data-layer)
6. [Service Architecture](#service-architecture)
7. [Multi-Tenancy Strategy](#multi-tenancy-strategy)
8. [Scaling Strategy](#scaling-strategy)
9. [Security Architecture](#security-architecture)
10. [Monitoring & Observability](#monitoring--observability)

---

## Overview

This document describes the system architecture for the CODITECT platform, a hyperscale multi-tenant SaaS application designed to support 1 million+ tenant organizations.

### Design Principles

- **Horizontal Scalability:** All components scale horizontally
- **Multi-Tenant Isolation:** Strong tenant data isolation with shared infrastructure
- **Cloud-Native:** Kubernetes-first architecture on GCP
- **Microservices:** Domain-driven service decomposition
- **Infrastructure as Code:** All infrastructure managed via Terraform
- **Observability-First:** Comprehensive monitoring, logging, and tracing

### Technology Stack Summary

| Layer | Technology |
|-------|-----------|
| **Cloud Platform** | Google Cloud Platform (GCP) |
| **Container Orchestration** | Kubernetes (GKE Autopilot) |
| **Application Framework** | Django 5.x + Django REST Framework |
| **Multi-Tenancy** | django-multitenant (shared-table) |
| **Database** | PostgreSQL 15+ → Citus 12+ (at scale) |
| **Caching** | Redis Cluster |
| **Task Queue** | Celery + RabbitMQ |
| **API Gateway** | Kong |
| **Authentication** | Ory Hydra (OAuth2/OIDC) |
| **Payments** | Stripe Billing API |
| **Monitoring** | Prometheus + Grafana + Jaeger |

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet (Users)                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                 ┌───────────▼──────────┐
                 │  Google Cloud CDN    │
                 │  (Static Assets)     │
                 └───────────┬──────────┘
                             │
        ┌────────────────────▼────────────────────┐
        │   GCP Load Balancer (HTTPS)            │
        │   - SSL Termination                     │
        │   - DDoS Protection                     │
        └────────────────────┬────────────────────┘
                             │
        ┌────────────────────▼────────────────────┐
        │   Kong API Gateway (GKE)                │
        │   - Rate Limiting                       │
        │   - Authentication                      │
        │   - Request Routing                     │
        └────┬───────────────┬───────────────┬────┘
             │               │               │
    ┌────────▼──────┐  ┌────▼─────┐  ┌─────▼──────┐
    │ Django Backend│  │ Auth     │  │ Billing    │
    │ (GKE Pods)    │  │ Service  │  │ Service    │
    │               │  │ (Hydra)  │  │ (Stripe)   │
    └────────┬──────┘  └──────────┘  └────────────┘
             │
    ┌────────▼──────────────────────┐
    │  Citus Distributed Database   │
    │  - Coordinator Node           │
    │  - Worker Nodes (sharded)     │
    └───────────────────────────────┘
             │
    ┌────────▼──────┐
    │  Redis Cluster│
    │  (Caching)    │
    └───────────────┘
```

---

## Infrastructure Layer

### GCP Resources (Terraform-Managed)

**VPC Network:**
- CIDR: 10.0.0.0/16
- Subnets:
  - `gke-subnet`: 10.0.0.0/20 (GKE nodes)
  - `db-subnet`: 10.0.16.0/24 (Cloud SQL / Citus)
  - `redis-subnet`: 10.0.17.0/24 (Memorystore Redis)

**GKE Cluster (Autopilot):**
- Multi-zone deployment (us-central1-a, b, c)
- Workload Identity enabled
- Binary Authorization enabled
- Pod Security Policy enforced
- Auto-scaling: 3-100 nodes

**Cloud SQL / Citus:**
- PostgreSQL 15 (initial) → Citus 12 (at scale)
- High Availability: Regional replication
- Automated backups: Daily, 30-day retention
- Connection pooling: PgBouncer

**Redis Cluster (Memorystore):**
- 6GB - 100GB (auto-scaling)
- High Availability: Multi-zone replication
- Auth enabled, TLS enforced

**Cloud Load Balancer:**
- Global HTTPS Load Balancer
- SSL certificates (Let's Encrypt)
- Cloud Armor (DDoS protection)
- Cloud CDN for static assets

---

## Application Layer

### Django Backend

**Components:**
- **Django 5.x:** Core application framework
- **Django REST Framework:** API layer
- **django-multitenant:** Multi-tenancy middleware
- **Gunicorn:** WSGI server
- **Celery:** Asynchronous task processing

**Deployment:**
- Kubernetes Deployment with auto-scaling (HPA)
- Min replicas: 3
- Max replicas: 50
- Resource requests: 500m CPU, 1Gi RAM
- Resource limits: 1000m CPU, 2Gi RAM

**Environment Configuration:**
- Development: 3 replicas
- Staging: 5 replicas
- Production: 10-50 replicas (auto-scale)

### API Gateway (Kong)

**Features:**
- Rate limiting (per tenant)
- Request authentication (JWT validation)
- Request routing (service mesh)
- API versioning (v1, v2, etc.)
- Request/response transformation

**Plugins:**
- `jwt` - JWT validation
- `rate-limiting` - Per-tenant rate limits
- `cors` - Cross-origin support
- `prometheus` - Metrics export
- `request-transformer` - Header injection

---

## Data Layer

### PostgreSQL → Citus Migration Path

**Phase 1: Standard PostgreSQL (0-10K tenants)**
- Cloud SQL PostgreSQL 15
- Read replicas for scaling reads
- Connection pooling (PgBouncer)
- Vertical scaling as needed

**Phase 2: Citus Distributed Database (10K-1M+ tenants)**
- Citus extension on PostgreSQL
- Sharding strategy: tenant_id (distribution column)
- Coordinator node: Routes queries
- Worker nodes: Store sharded data (10-50 workers)
- Rebalancing: Dynamic shard distribution

### Database Schema

**Multi-Tenant Design:**
All tables include `tenant_id` column:

```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,  -- Shard key for Citus
    name VARCHAR(255),
    domain VARCHAR(255) UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Distribute table by tenant_id (Citus)
SELECT create_distributed_table('organizations', 'tenant_id');
```

**Key Tables:**
- `organizations` - Tenant organizations
- `users` - User accounts (multi-tenant)
- `workspaces` - Development workspaces
- `projects` - User projects
- `sessions` - Active user sessions
- `audit_logs` - Audit trail (append-only)

### Caching Strategy (Redis)

**Cache Layers:**
1. **Session Cache:** User sessions (TTL: 1 hour)
2. **Query Cache:** Expensive queries (TTL: 5 minutes)
3. **API Response Cache:** GET endpoints (TTL: 1 minute)
4. **Rate Limiting:** Request counters (TTL: 1 minute)

**Eviction Policy:** LRU (Least Recently Used)

---

## Service Architecture

### Microservices

**Core Services:**

1. **API Service (Django)**
   - RESTful API endpoints
   - GraphQL API (future)
   - WebSocket connections (Django Channels)

2. **Authentication Service (Ory Hydra)**
   - OAuth2/OIDC provider
   - User authentication
   - JWT token issuance
   - Multi-factor authentication (MFA)

3. **Billing Service (Stripe Integration)**
   - Subscription management
   - Payment processing
   - Usage tracking
   - Invoice generation

4. **Background Workers (Celery)**
   - Email sending
   - Report generation
   - Data exports
   - Scheduled tasks (Celery Beat)

**Service Communication:**
- Synchronous: HTTP/REST (service-to-service)
- Asynchronous: RabbitMQ (event-driven)

---

## Multi-Tenancy Strategy

### Shared-Table Multi-Tenancy (django-multitenant)

**Approach:**
- All tenants share same database tables
- Every table has `tenant_id` column
- Row-level security enforced by middleware
- Automatic tenant context injection

**Advantages:**
- Cost-effective (shared infrastructure)
- Easy to deploy and maintain
- Scales to millions of tenants

**Tenant Isolation:**
- Django middleware sets tenant context per request
- All queries automatically filtered by `tenant_id`
- Cross-tenant queries prevented at ORM level

**Example:**

```python
# Request headers include tenant context
# X-Tenant-ID: 123e4567-e89b-12d3-a456-426614174000

# Django middleware sets tenant
set_current_tenant(tenant_id)

# All queries automatically scoped
users = User.objects.all()  # Only returns users for current tenant
```

### Tenant Onboarding Flow

1. User signs up at `https://app.coditect.ai/signup`
2. New `Organization` created with unique `tenant_id`
3. User assigned as organization owner
4. Tenant domain registered: `{org_slug}.coditect.ai`
5. Welcome email sent (Celery task)

---

## Scaling Strategy

### Horizontal Scaling

**Application Tier:**
- Kubernetes HPA (Horizontal Pod Autoscaler)
- Metric: CPU > 70% → scale up
- Scale from 3 to 50 pods

**Database Tier (Citus):**
- Add worker nodes dynamically
- Rebalance shards across workers
- Scale from 2 to 50 worker nodes

**Cache Tier (Redis):**
- Redis Cluster mode (sharding)
- 6GB to 100GB memory
- Auto-scaling based on memory usage

### Load Testing Targets

| Metric | Target |
|--------|--------|
| **Concurrent Users** | 100,000+ |
| **Requests/Second** | 10,000+ |
| **p99 Latency** | <100ms |
| **Database Connections** | 10,000+ |
| **Tenants Supported** | 1,000,000+ |

---

## Security Architecture

### Network Security

- **VPC Isolation:** Private subnets for databases
- **Firewall Rules:** Least-privilege access
- **TLS Everywhere:** All communication encrypted
- **Cloud Armor:** DDoS protection at edge

### Application Security

- **Authentication:** OAuth2/OIDC (Ory Hydra)
- **Authorization:** Role-Based Access Control (RBAC)
- **Input Validation:** Django Forms + DRF Serializers
- **SQL Injection Prevention:** ORM parameterized queries
- **XSS Prevention:** Django template auto-escaping
- **CSRF Protection:** Django middleware

### Data Security

- **Encryption at Rest:** GCP-managed keys (CMEK available)
- **Encryption in Transit:** TLS 1.3
- **Tenant Isolation:** Row-level security
- **Audit Logging:** All mutations logged
- **PII Handling:** GDPR compliance, data retention policies

### Secrets Management

- **GCP Secret Manager:** All application secrets
- **Workload Identity:** No service account keys
- **Kubernetes Secrets:** Encrypted at rest (etcd)

---

## Monitoring & Observability

### Metrics (Prometheus + Grafana)

**Infrastructure Metrics:**
- GKE node CPU, memory, disk
- Pod resource usage
- Network throughput

**Application Metrics:**
- Request rate, latency, errors (RED method)
- Database connection pool
- Cache hit/miss ratio
- Celery queue length

**Business Metrics:**
- Active tenants
- API calls per tenant
- Subscription revenue (via Stripe webhook)

### Distributed Tracing (Jaeger)

- End-to-end request tracing
- Service dependency map
- Latency analysis
- Error root cause analysis

### Logging (Google Cloud Logging)

- Structured JSON logs
- Log levels: DEBUG, INFO, WARNING, ERROR
- Centralized log aggregation
- Log retention: 30 days

### Alerting

**Critical Alerts:**
- API error rate > 1%
- Database connection pool exhausted
- Pod crash loops
- Disk usage > 80%

**Warning Alerts:**
- p99 latency > 200ms
- Cache hit ratio < 70%
- Celery queue backlog > 1000 tasks

---

## Disaster Recovery

### Backup Strategy

**Database Backups:**
- Automated daily backups (Cloud SQL)
- Point-in-time recovery (7 days)
- Cross-region backups (monthly)

**Application Backups:**
- Kubernetes manifests in git (GitOps)
- Terraform state in GCS (versioned)

### Recovery Procedures

**RTO (Recovery Time Objective):** 1 hour
**RPO (Recovery Point Objective):** 1 hour

**Disaster Scenarios:**
1. **Pod failure:** Auto-restart by Kubernetes
2. **Node failure:** Reschedule pods to healthy nodes
3. **Zone failure:** Multi-zone deployment (no impact)
4. **Region failure:** Manual failover to backup region (1 hour)
5. **Database corruption:** Restore from backup (1 hour)

---

## Future Enhancements

### Phase 2 (Next 6 months)

- [ ] GraphQL API layer
- [ ] WebSocket real-time updates (Django Channels)
- [ ] Multi-region deployment (US, EU, APAC)
- [ ] Advanced analytics dashboard

### Phase 3 (6-12 months)

- [ ] Machine learning-based usage predictions
- [ ] Auto-scaling based on tenant usage patterns
- [ ] Advanced tenant customization (white-labeling)
- [ ] Mobile app backend (BFF pattern)

---

**Document Owner:** CODITECT Architecture Team
**Review Cycle:** Quarterly
**Next Review:** February 2026
