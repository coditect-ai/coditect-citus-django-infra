# PROJECT PLAN: Django + Citus Hyperscale SaaS Platform

**Project:** CODITECT Hyperscale Multi-Tenant SaaS Platform
**Date:** November 23, 2025
**Owner:** CODITECT Architecture Team
**Status:** ACTIVE DEVELOPMENT
**Version:** 2.0 (Comprehensive)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Technology Stack](#2-technology-stack)
3. [Architecture Overview](#3-architecture-overview)
4. [Phase 0: Project Foundation](#4-phase-0-project-foundation)
5. [Phase 1: Infrastructure Foundation](#5-phase-1-infrastructure-foundation)
6. [Phase 2: Django Backend Application](#6-phase-2-django-backend-application)
7. [Phase 3: Authentication & Billing](#7-phase-3-authentication--billing)
8. [Phase 4: Frontend & Admin](#8-phase-4-frontend--admin)
9. [Phase 5: Monitoring & Production Readiness](#9-phase-5-monitoring--production-readiness)
10. [Phase 6: Citus Migration & Hyperscale](#10-phase-6-citus-migration--hyperscale)
11. [Multi-Agent Orchestration Strategy](#11-multi-agent-orchestration-strategy)
12. [Timeline & Resource Requirements](#12-timeline--resource-requirements)
13. [Budget & Cost Analysis](#13-budget--cost-analysis)
14. [Risk Assessment](#14-risk-assessment)
15. [Quality Gates & Success Metrics](#15-quality-gates--success-metrics)

---

## 1. Executive Summary

This comprehensive plan outlines the complete implementation of a hyperscale, multi-tenant SaaS platform capable of serving **1 million+ tenant organizations**. The platform is built on a modern stack using Django 5.x, Citus distributed PostgreSQL, Kubernetes orchestration, and microservices architecture.

### Key Objectives

- **Hyperscale Support:** Handle 1M+ tenant organizations with horizontal scaling
- **Modern Architecture:** Microservices-based design with distributed database
- **Production-Ready:** Comprehensive monitoring, testing, and deployment automation
- **Cost-Effective:** Start with standard PostgreSQL, migrate to Citus at scale
- **Open Source:** Built entirely on open-source technologies (MIT/AGPL)

### Phased Approach

The project is structured in 6 phases over 20-24 weeks:

1. **Phase 0: Foundation** (Week 1-2) - Project setup, team onboarding
2. **Phase 1: Infrastructure** (Week 3-6) - Terraform, GKE, Cloud SQL
3. **Phase 2: Django Backend** (Week 7-12) - Application development, APIs
4. **Phase 3: Auth & Billing** (Week 13-16) - Ory Hydra, Stripe integration
5. **Phase 4: Frontend & Admin** (Week 17-20) - React dashboard, Django Admin
6. **Phase 5: Monitoring & Production** (Week 21-24) - Observability, load testing
7. **Phase 6: Citus Migration** (Ongoing) - Scale to 1M+ tenants

### Success Criteria

- ✅ Support 1M+ tenants with <100ms p99 latency
- ✅ 99.9% uptime SLA
- ✅ Automated deployment pipeline (CI/CD)
- ✅ Comprehensive monitoring and alerting
- ✅ Security best practices implemented
- ✅ Complete documentation and runbooks

---

## 2. Technology Stack

### Core Platform

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Backend Framework** | Django | 5.x | Application framework |
| **Multi-Tenancy** | django-multitenant | 3.x | Shared-table multi-tenancy |
| **Database (Initial)** | PostgreSQL | 15+ | Relational database |
| **Database (Scale)** | Citus | 12+ | Distributed PostgreSQL |
| **API Framework** | Django REST Framework | 3.14+ | REST API development |
| **Authentication** | Ory Hydra + Authlib | Latest | OAuth2/OIDC server |
| **Payments** | Stripe Billing API | Latest | Subscription management |

### Infrastructure

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Cloud Platform** | Google Cloud Platform (GCP) | Cloud infrastructure |
| **Orchestration** | Kubernetes (GKE) | Container orchestration |
| **Infrastructure as Code** | OpenTofu v1.10.7 | GCP resource provisioning (open-source, MPL 2.0) |
| **API Gateway** | Kong | Request routing, rate limiting |
| **Load Balancer** | GCP Load Balancer | Traffic distribution |
| **Caching** | Redis Cluster | Distributed caching |
| **Task Queue** | Celery + RabbitMQ | Background job processing |
| **Container Registry** | Google Container Registry | Docker image storage |

### Observability & Monitoring

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Metrics** | Prometheus | Metrics collection |
| **Visualization** | Grafana | Metrics dashboards |
| **Distributed Tracing** | Jaeger | Request tracing |
| **Logging** | Google Cloud Logging | Centralized logging |
| **APM** | Django Silk (dev) | Application performance monitoring |
| **Error Tracking** | Sentry | Exception tracking |

### Development & CI/CD

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Version Control** | Git + GitHub | Source code management |
| **CI/CD** | GitHub Actions | Automated testing and deployment |
| **Testing** | pytest + Locust | Unit/integration/load testing |
| **Code Quality** | Ruff + Black + MyPy | Linting and type checking |
| **Security Scanning** | Trivy + Safety | Vulnerability scanning |
| **Documentation** | Sphinx + MkDocs | API and user documentation |

### Frontend (Admin Dashboard)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | React 18 | UI framework |
| **Language** | TypeScript | Type-safe JavaScript |
| **Build Tool** | Vite | Fast development server |
| **State Management** | Zustand | Lightweight state management |
| **UI Components** | Chakra UI | Component library |
| **API Client** | Axios | HTTP client |
| **Form Validation** | React Hook Form + Zod | Form handling and validation |

---

## 3. Architecture Overview

### Multi-Tenant Architecture

**Shared-Table Model with Row-Level Security**

- All tenant data in shared tables with `tenant_id` column
- Application-level filtering via `django-multitenant`
- Database-level RLS (Row-Level Security) for defense-in-depth
- Horizontal sharding via Citus when scaling to 100K+ tenants

### Microservices Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GCP Load Balancer                       │
└─────────────┬───────────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Kong API Gateway                        │
│  (Rate Limiting, Auth, Routing, Analytics)                  │
└─────────────┬───────────────────────────────────────────────┘
              │
        ┌─────┴─────┬──────────┬──────────┬──────────┐
        ▼           ▼          ▼          ▼          ▼
   ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐
   │  Auth  │  │  Core  │  │Billing │  │ Admin  │  │Celery  │
   │Service │  │  API   │  │Service │  │  UI    │  │Workers │
   │(Hydra) │  │(Django)│  │(Django)│  │(React) │  │(Django)│
   └────┬───┘  └────┬───┘  └────┬───┘  └────┬───┘  └────┬───┘
        │           │           │           │           │
        └───────────┴───────────┴───────────┴───────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────────┐
        │         Citus Distributed PostgreSQL        │
        │  ┌────────────┐  ┌──────────┐  ┌──────────┐│
        │  │Coordinator │  │ Worker 1 │  │ Worker N ││
        │  └────────────┘  └──────────┘  └──────────┘│
        └─────────────────────────────────────────────┘
```

### Data Flow

**Typical Request Flow:**

1. Client → GCP Load Balancer → Kong API Gateway
2. Kong validates JWT, checks rate limits, routes to service
3. Service queries Citus (application filters by `tenant_id`)
4. Citus coordinator routes query to appropriate worker node
5. Response flows back through Kong to client

**Background Job Flow:**

1. API creates task → Celery broker (RabbitMQ)
2. Celery worker picks up task
3. Worker processes task (e.g., send email, generate report)
4. Worker updates database with result

---

## 4. Phase 0: Project Foundation

**Duration:** 2 weeks
**Team:** All
**Goal:** Establish project foundation, team onboarding, and development environment

### Objectives

- Setup project repository structure
- Onboard team members to CODITECT framework
- Configure development environments
- Establish coding standards and workflows
- Create initial documentation

### Tasks

#### Week 1: Repository Setup

1. **Initialize Git Repository**
   - Create coditect-citus-django-infra repository
   - Setup .gitignore for Python, Terraform, Kubernetes
   - Configure branch protection rules
   - Setup GitHub Actions runners
   - Create README.md, CONTRIBUTING.md, LICENSE

2. **Project Structure**
   - Create directory structure (opentofu/, kubernetes/, django/, docs/)
   - Setup .coditect symlink to master repo
   - Initialize Python project (pyproject.toml, requirements.txt)
   - Create Docker development environment

3. **Development Standards**
   - Define Python coding standards (PEP 8, type hints)
   - Configure linting (Ruff, Black, MyPy)
   - Setup pre-commit hooks
   - Create PR template
   - Establish commit message conventions

#### Week 2: Team Onboarding & Environment Setup

4. **Team Onboarding**
   - Review PROJECT-PLAN.md with team
   - Assign roles and responsibilities
   - Setup communication channels (Slack, GitHub Discussions)
   - Schedule daily standups and weekly reviews

5. **Local Development Environment**
   - Install required tools (Docker, kubectl, terraform, gcloud)
   - Setup GCP project and service accounts
   - Configure kubectl access to GKE
   - Test local Django development server
   - Verify Terraform and kubectl access

6. **Documentation Foundation**
   - Create ARCHITECTURE.md
   - Create DEPLOYMENT.md
   - Create TROUBLESHOOTING.md
   - Setup MkDocs for user documentation
   - Initialize API documentation with Sphinx

### Deliverables

- ✅ Git repository with proper structure
- ✅ Team onboarded and environments configured
- ✅ Development standards documented
- ✅ Initial documentation created
- ✅ PR workflow operational

### Success Criteria

- [ ] All team members can run local development environment
- [ ] First PR merged following established workflow
- [ ] Documentation site accessible
- [ ] GCP project configured with proper IAM roles

---

## 5. Phase 1: Infrastructure Foundation

**Duration:** 4 weeks (Weeks 3-6)
**Team:** DevOps Engineer, Cloud Architect
**Goal:** Deploy production-ready infrastructure on GCP using OpenTofu
**Status:** IN PROGRESS (60% Complete - OpenTofu Migration Completed ✅)

### Objectives

- Provision GKE cluster with auto-scaling
- Deploy Cloud SQL PostgreSQL (HA configuration)
- Setup Redis cluster for caching
- Configure networking (VPC, subnets, firewall rules)
- Implement secrets management
- Establish CI/CD pipeline for infrastructure

### Architecture Decisions

- **Infrastructure as Code:** OpenTofu v1.10.7 (migrated from Terraform due to BUSL licensing)
  - **Reason:** HashiCorp changed Terraform license to BUSL (Business Source License) in August 2023
  - **Solution:** OpenTofu is a Linux Foundation fork, 100% compatible, MPL 2.0 licensed
  - **Migration Status:** ✅ Completed (November 23, 2025) - All modules validated successfully
- **Initial Database:** Cloud SQL PostgreSQL (HA) - easier to manage initially
- **Migration Path:** Migrate to self-managed Citus when reaching 10K+ tenants
- **Networking:** Private GKE cluster with VPC peering to Cloud SQL
- **Secrets:** GCP Secret Manager for all credentials

### Tasks

#### Week 3: OpenTofu Modules - Part 1 ✅ COMPLETED

1. **GKE Cluster Module**
   - Multi-zone GKE cluster (us-central1-a, us-central1-b, us-central1-c)
   - Node pool with auto-scaling (min: 3, max: 100 nodes)
   - Machine type: n2-standard-4 (4 vCPU, 16GB RAM)
   - Enable workload identity, binary authorization
   - Configure cluster autoscaler
   - Setup node taints and labels for workload segregation

2. **Cloud SQL PostgreSQL Module**
   - PostgreSQL 15 instance (HA with failover replica)
   - Machine type: db-custom-4-15360 (4 vCPU, 15GB RAM)
   - Storage: 100GB SSD with auto-increase
   - Enable automated backups (daily, 7-day retention)
   - Configure maintenance window (Sunday 2-6 AM)
   - Enable query insights and performance insights

3. **VPC Networking Module**
   - Custom VPC with RFC 1918 address space
   - Subnets: gke-subnet (10.0.0.0/20), db-subnet (10.0.16.0/24)
   - VPC peering between GKE and Cloud SQL
   - Cloud NAT for outbound internet access
   - Private Google Access enabled

#### Week 4: OpenTofu Modules - Part 2 ✅ COMPLETED

4. **Redis Cluster Module**
   - Memorystore Redis instance (5GB, HA)
   - VPC peering to GKE cluster
   - Redis version 7.x
   - Enable AUTH and in-transit encryption
   - Configure eviction policy (allkeys-lru)

5. **Firewall Rules Module**
   - Allow internal traffic between GKE pods
   - Allow GKE to Cloud SQL (port 5432)
   - Allow GKE to Redis (port 6379)
   - Deny all other inbound traffic (default deny)
   - Allow egress to internet for package updates

6. **Secret Manager Integration**
   - Create secrets for database credentials
   - Create secrets for Django SECRET_KEY
   - Create secrets for Stripe API keys (placeholder)
   - Configure workload identity for secret access
   - Setup secret rotation policies

#### Week 5: Environment Configurations ✅ COMPLETED

7. **Development Environment** ✅
   - opentofu/environments/dev/
   - Small instance sizes (cost optimization)
   - Single-zone GKE cluster
   - Non-HA Cloud SQL instance
   - Auto-delete unused resources
   - OpenTofu validation: PASSED

8. **Staging Environment** ✅
   - opentofu/environments/staging/
   - Production-like configuration
   - Multi-zone GKE cluster
   - HA Cloud SQL instance
   - Blue-green deployment capability
   - OpenTofu validation: PASSED

9. **Production Environment** ✅
   - opentofu/environments/production/
   - Maximum redundancy and HA
   - Multi-zone, multi-region planning
   - Strict change management
   - Comprehensive monitoring
   - OpenTofu validation: PASSED

#### Week 6: CI/CD & Kubernetes Base

10. **OpenTofu CI/CD Pipeline** 🔄 IN PROGRESS
    - GitHub Actions workflow for tofu validate
    - Automated tofu plan on PR
    - Manual approval for tofu apply
    - State stored in GCS bucket with versioning
    - Drift detection (daily tofu plan)
    - **Note:** Migration from terraform to tofu commands needed in CI/CD

11. **Kubernetes Base Configuration**
    - Namespaces: coditect-dev, coditect-staging, coditect-production
    - RBAC policies for service accounts
    - Network policies (deny all by default)
    - Resource quotas per namespace
    - LimitRanges for pod resource constraints

12. **Infrastructure Validation** ✅ COMPLETED (Validation Only)
    - OpenTofu validation tests ✅ (all 3 environments passing)
    - GKE cluster health checks ⏸️ (pending deployment)
    - Database connectivity tests ⏸️ (pending deployment)
    - Redis connectivity tests ⏸️ (pending deployment)
    - Cost analysis and optimization review ⏸️ (pending deployment)

### Deliverables

- ✅ Complete OpenTofu modules for all infrastructure components (6 modules, 4,172 lines)
- ✅ OpenTofu migration from Terraform completed (November 23, 2025)
- ✅ Three environments (dev, staging, production) configured and validated
- 🔄 CI/CD pipeline for infrastructure changes (needs tofu command updates)
- ⏸️ Kubernetes cluster with base configuration (pending - P1-T04)
- ⏸️ All resources deployed to GCP (pending - awaiting deployment decision)

### Success Criteria

- [x] OpenTofu modules created and validated ✅
- [x] All 3 environments pass `tofu validate` ✅
- [ ] GKE cluster running in all environments ⏸️
- [ ] Cloud SQL PostgreSQL accessible from GKE ⏸️
- [ ] Redis cluster operational and accessible ⏸️
- [ ] OpenTofu apply succeeds without errors in dev environment ⏸️
- [ ] Infrastructure costs within budget ($800/month for dev)

---

## 6. Phase 2: Django Backend Application

**Duration:** 6 weeks (Weeks 7-12)
**Team:** Backend Engineers, Database Architect
**Goal:** Build complete Django application with multi-tenant support

### Objectives

- Setup Django project structure
- Implement multi-tenancy with django-multitenant
- Create core data models (Tenant, User, Project, Task)
- Build REST APIs with Django REST Framework
- Implement authentication and authorization
- Create database migrations
- Write comprehensive tests

### Tasks

#### Week 7: Django Project Setup

13. **Django Project Initialization**
    - Create Django project: `coditect_platform`
    - Configure settings.py (split: base, dev, staging, production)
    - Setup Django apps: accounts, tenants, projects, billing
    - Configure Django REST Framework
    - Setup CORS middleware
    - Configure static files and media storage (GCS)

14. **Multi-Tenancy Foundation**
    - Install django-multitenant
    - Configure TenantMiddleware
    - Setup tenant model (Organization)
    - Create tenant-aware manager
    - Configure database routing
    - Add tenant context to all requests

15. **Database Configuration**
    - Configure PostgreSQL connection (via Cloud SQL Proxy)
    - Setup connection pooling (psycopg2-pool)
    - Configure read replicas (for future scaling)
    - Add database health check endpoint
    - Setup Django database router for tenant isolation

#### Week 8: Core Data Models

16. **Tenant Models**
    - Organization model (tenant_id, name, subdomain, status)
    - TenantSettings model (features, limits, preferences)
    - TenantDomain model (custom domains)
    - Add RLS (Row-Level Security) policies
    - Create indexes for tenant_id columns

17. **User Models**
    - CustomUser model (extends AbstractUser)
    - TenantUser model (links users to organizations)
    - UserProfile model (additional user metadata)
    - UserRole model (role-based access control)
    - Setup permissions and groups

18. **Project Models**
    - Project model (tenant_id, name, description, status)
    - Task model (tenant_id, project_id, title, assignee, status)
    - Comment model (tenant_id, task_id, user_id, content)
    - Attachment model (tenant_id, task_id, file_url)
    - Activity log model (audit trail)

#### Week 9: Django REST Framework APIs - Part 1

19. **Tenant Management APIs**
    - POST /api/v1/tenants/ (create organization)
    - GET /api/v1/tenants/me/ (current organization details)
    - PUT /api/v1/tenants/me/ (update organization)
    - GET /api/v1/tenants/me/settings/ (tenant settings)
    - PUT /api/v1/tenants/me/settings/ (update settings)

20. **User Management APIs**
    - POST /api/v1/users/ (create user)
    - GET /api/v1/users/me/ (current user profile)
    - PUT /api/v1/users/me/ (update profile)
    - GET /api/v1/users/ (list organization users)
    - POST /api/v1/users/invite/ (invite user to organization)

21. **Authentication APIs**
    - POST /api/v1/auth/register/ (user registration)
    - POST /api/v1/auth/login/ (JWT token generation)
    - POST /api/v1/auth/refresh/ (refresh JWT token)
    - POST /api/v1/auth/logout/ (invalidate token)
    - POST /api/v1/auth/password-reset/ (password reset flow)

#### Week 10: Django REST Framework APIs - Part 2

22. **Project Management APIs**
    - POST /api/v1/projects/ (create project)
    - GET /api/v1/projects/ (list projects with pagination)
    - GET /api/v1/projects/{id}/ (project details)
    - PUT /api/v1/projects/{id}/ (update project)
    - DELETE /api/v1/projects/{id}/ (soft delete project)

23. **Task Management APIs**
    - POST /api/v1/projects/{id}/tasks/ (create task)
    - GET /api/v1/projects/{id}/tasks/ (list tasks)
    - GET /api/v1/tasks/{id}/ (task details)
    - PUT /api/v1/tasks/{id}/ (update task)
    - DELETE /api/v1/tasks/{id}/ (soft delete task)

24. **API Middleware & Filters**
    - Tenant isolation middleware (validate tenant_id)
    - Request/response logging middleware
    - DRF filters (search, ordering, filtering)
    - Pagination (cursor-based for performance)
    - API versioning (URL-based)

#### Week 11: Business Logic & Celery

25. **Business Logic Implementation**
    - Task assignment logic (check user permissions)
    - Project permissions (owner, admin, member roles)
    - Activity logging (audit trail for all changes)
    - Soft delete implementation (deleted_at timestamp)
    - Cascade deletion logic (tasks when project deleted)

26. **Celery Background Tasks**
    - Setup Celery with RabbitMQ broker
    - Email notification tasks (async)
    - Report generation tasks
    - Data export tasks (CSV, JSON)
    - Scheduled tasks (daily summaries)
    - Task retry logic and error handling

27. **Caching Strategy**
    - Redis caching for frequently accessed data
    - Cache tenant settings (5 min TTL)
    - Cache user permissions (15 min TTL)
    - Cache project lists (1 min TTL)
    - Implement cache invalidation on updates

#### Week 12: Testing & Documentation

28. **Unit Tests**
    - Model tests (validation, constraints)
    - API endpoint tests (CRUD operations)
    - Serializer tests (data validation)
    - Permission tests (RBAC)
    - Target: 80%+ code coverage

29. **Integration Tests**
    - Multi-tenant isolation tests
    - End-to-end API flow tests
    - Database transaction tests
    - Celery task execution tests
    - Cache invalidation tests

30. **API Documentation**
    - Generate OpenAPI/Swagger schema
    - Add docstrings to all API endpoints
    - Create API usage examples
    - Setup Swagger UI at /api/docs/
    - Create Postman collection

### Deliverables

- ✅ Complete Django application with multi-tenancy
- ✅ REST APIs for all core features
- ✅ Database models with migrations
- ✅ Celery background task processing
- ✅ Comprehensive test suite (80%+ coverage)
- ✅ API documentation (Swagger + Postman)

### Success Criteria

- [ ] All API endpoints return correct responses
- [ ] Multi-tenant isolation verified (tenant A can't access tenant B data)
- [ ] Unit tests pass with 80%+ coverage
- [ ] API documentation complete and accessible
- [ ] Celery tasks execute successfully

---

## 7. Phase 3: Authentication & Billing

**Duration:** 4 weeks (Weeks 13-16)
**Team:** Backend Engineers, Security Specialist
**Goal:** Implement OAuth2 authentication and Stripe billing integration

### Objectives

- Deploy Ory Hydra OAuth2/OIDC server
- Integrate Authlib in Django for OAuth client
- Implement SSO (Single Sign-On)
- Integrate Stripe Billing API
- Setup subscription management
- Handle payment webhooks
- Implement usage-based billing

### Tasks

#### Week 13: Ory Hydra Deployment

31. **Ory Hydra Setup**
    - Deploy Hydra in Kubernetes (StatefulSet)
    - Configure PostgreSQL backend for Hydra
    - Setup Hydra admin API
    - Configure OAuth2 clients (Django app)
    - Enable PKCE flow for SPAs

32. **Hydra Configuration**
    - Configure consent flow
    - Setup login UI (Django templates)
    - Configure logout flow
    - Setup ID token claims (tenant_id, roles)
    - Configure token lifetimes (access: 1h, refresh: 7d)

33. **Authlib Integration in Django**
    - Install Authlib in Django
    - Configure OAuth2 client settings
    - Create OAuth callback endpoints
    - Implement token storage (database)
    - Add JWT validation middleware

#### Week 14: Authentication Features

34. **SSO Implementation**
    - OAuth2 authorization code flow
    - Handle OAuth callbacks
    - Exchange authorization code for tokens
    - Store tokens securely (encrypted)
    - Refresh token logic

35. **Multi-Tenant SSO**
    - Tenant-specific login pages (/login/{tenant_slug}/)
    - Tenant context in OAuth state parameter
    - Custom domain support (CNAME to tenant)
    - Organization-level SSO settings
    - Auto-provisioning users from SSO

36. **Session Management**
    - Redis-backed session storage
    - Session expiration (7 days)
    - "Remember me" functionality
    - Concurrent session handling
    - Session revocation API

#### Week 15: Stripe Billing Integration

37. **Stripe Setup**
    - Create Stripe account (test mode initially)
    - Configure Stripe webhook endpoint
    - Setup Stripe API keys in Secret Manager
    - Create Stripe products (Free, Pro, Enterprise)
    - Define pricing plans (monthly, annual)

38. **Subscription Management**
    - Create Subscription model (tenant_id, stripe_subscription_id)
    - POST /api/v1/billing/subscribe/ (create subscription)
    - GET /api/v1/billing/subscription/ (get subscription status)
    - POST /api/v1/billing/cancel/ (cancel subscription)
    - POST /api/v1/billing/upgrade/ (upgrade/downgrade plan)

39. **Payment Method Management**
    - POST /api/v1/billing/payment-method/ (add payment method)
    - GET /api/v1/billing/payment-methods/ (list payment methods)
    - DELETE /api/v1/billing/payment-method/{id}/ (remove)
    - Set default payment method
    - Handle 3D Secure authentication

#### Week 16: Webhooks & Usage Billing

40. **Stripe Webhook Handling**
    - POST /api/v1/webhooks/stripe/ (webhook endpoint)
    - Handle invoice.payment_succeeded
    - Handle invoice.payment_failed
    - Handle customer.subscription.deleted
    - Handle customer.subscription.updated
    - Retry logic for failed webhooks

41. **Usage-Based Billing**
    - Create UsageRecord model (tenant_id, metric, quantity)
    - Track API usage (requests per tenant)
    - Track storage usage (files uploaded)
    - Report usage to Stripe (daily batch job)
    - Display usage in admin dashboard

42. **Billing Tests & Documentation**
    - Unit tests for subscription logic
    - Integration tests with Stripe test mode
    - Test webhook handling
    - Document billing flows
    - Create billing runbook for support team

### Deliverables

- ✅ Ory Hydra OAuth2 server operational
- ✅ SSO authentication working
- ✅ Stripe billing integrated
- ✅ Subscription management APIs
- ✅ Webhook handling implemented
- ✅ Usage-based billing operational

### Success Criteria

- [ ] Users can login via OAuth2 flow
- [ ] SSO works across tenant subdomains
- [ ] Subscriptions can be created and managed via Stripe
- [ ] Webhooks correctly update subscription status
- [ ] Usage metrics tracked and reported to Stripe

---

## 8. Phase 4: Frontend & Admin

**Duration:** 4 weeks (Weeks 17-20)
**Team:** Frontend Engineers
**Goal:** Build React admin dashboard and configure Django Admin

### Objectives

- Setup React application with TypeScript
- Implement routing and state management
- Create UI components for tenant/project/task management
- Integrate with backend APIs
- Configure Django Admin for support team
- Implement responsive design

### Tasks

#### Week 17: React Project Setup

43. **React Application Initialization**
    - Create React app with Vite + TypeScript
    - Setup Chakra UI component library
    - Configure Zustand for state management
    - Setup React Router for navigation
    - Configure Axios for API calls

44. **Authentication UI**
    - Login page with OAuth2 flow
    - Registration page
    - Password reset flow
    - Session management (store JWT in localStorage)
    - Protected routes (redirect to login if unauthenticated)

45. **Layout & Navigation**
    - Main layout with sidebar navigation
    - Top bar with user menu
    - Responsive design (mobile, tablet, desktop)
    - Dark mode support
    - Breadcrumb navigation

#### Week 18: Core UI Components

46. **Tenant Management UI**
    - Organization settings page
    - Update organization name, logo
    - Manage custom domains
    - View subscription status
    - Billing history table

47. **User Management UI**
    - User list with search and filters
    - Invite user dialog
    - User details drawer
    - Role assignment UI
    - User activity log

48. **Project Management UI**
    - Project list (card view and table view)
    - Create project dialog
    - Project details page
    - Update project form
    - Delete project confirmation modal

#### Week 19: Task Management UI

49. **Task Management UI**
    - Task board (Kanban view)
    - Task list (table view)
    - Create task dialog
    - Task details drawer
    - Task comments section
    - Attach files to tasks

50. **Dashboard & Analytics**
    - Dashboard with key metrics (active projects, tasks)
    - Activity feed (recent changes)
    - Charts (tasks by status, projects over time)
    - Search functionality (global search)

51. **Forms & Validation**
    - React Hook Form integration
    - Zod schema validation
    - Form error handling
    - Loading states and spinners
    - Success/error toast notifications

#### Week 20: Django Admin & Testing

52. **Django Admin Configuration**
    - Customize admin site branding
    - Register all models (Tenant, User, Project, Task)
    - Add list filters and search
    - Create custom admin actions (bulk operations)
    - Setup read-only fields for auditing

53. **Frontend Testing**
    - Unit tests for components (Vitest)
    - Integration tests for API calls
    - E2E tests (Playwright)
    - Test user flows (login, create project, create task)
    - Target: 70%+ code coverage

54. **Frontend Documentation**
    - Component documentation (Storybook)
    - API integration guide
    - Deployment guide (build and deploy to GCS)
    - User guide (how to use the dashboard)

### Deliverables

- ✅ Complete React admin dashboard
- ✅ All core features implemented (tenants, users, projects, tasks)
- ✅ Django Admin configured for support team
- ✅ Responsive design working on all devices
- ✅ Frontend tests (70%+ coverage)
- ✅ Component documentation with Storybook

### Success Criteria

- [ ] Users can manage tenants, users, projects, tasks via UI
- [ ] OAuth2 login flow works end-to-end
- [ ] UI is responsive on mobile, tablet, desktop
- [ ] Django Admin accessible and functional
- [ ] Frontend tests pass with 70%+ coverage

---

## 9. Phase 5: Monitoring & Production Readiness

**Duration:** 4 weeks (Weeks 21-24)
**Team:** DevOps, Monitoring Specialist, QA
**Goal:** Implement comprehensive monitoring, testing, and production hardening

### Objectives

- Deploy Prometheus for metrics collection
- Configure Grafana dashboards
- Setup Jaeger for distributed tracing
- Implement logging with GCP Cloud Logging
- Setup alerting and on-call rotation
- Perform load testing
- Security hardening
- Create runbooks and documentation

### Tasks

#### Week 21: Prometheus & Grafana

55. **Prometheus Deployment**
    - Deploy Prometheus in Kubernetes (StatefulSet)
    - Configure service discovery (Kubernetes SD)
    - Setup metric scraping (Django, Celery, PostgreSQL, Redis)
    - Create recording rules (aggregations)
    - Configure remote write to GCP Managed Prometheus

56. **Custom Metrics**
    - Django middleware for request metrics
    - Track API response times (histogram)
    - Track error rates by endpoint
    - Track database query performance
    - Track Celery task duration

57. **Grafana Dashboards**
    - Deploy Grafana in Kubernetes
    - Connect to Prometheus data source
    - Infrastructure dashboard (CPU, memory, disk)
    - Database health dashboard (connections, query time)
    - Application metrics dashboard (API latency, error rate)
    - Business metrics dashboard (active tenants, API usage)

#### Week 22: Distributed Tracing & Logging

58. **Jaeger Deployment**
    - Deploy Jaeger in Kubernetes
    - Configure OpenTelemetry SDK in Django
    - Instrument API endpoints (auto-tracing)
    - Instrument database queries
    - Configure sampling (100% in dev, 10% in prod)

59. **Trace Visualization**
    - Create trace dashboards in Jaeger UI
    - Identify slow requests (>500ms)
    - Analyze database query performance
    - Track cross-service calls (Django → Hydra)

60. **Centralized Logging**
    - Configure Django logging (JSON format)
    - Send logs to GCP Cloud Logging
    - Setup log-based metrics (4xx/5xx errors)
    - Create log filters for common issues
    - Setup log retention (30 days)

#### Week 23: Alerting & Load Testing

61. **Prometheus Alerting**
    - Deploy Alertmanager
    - Configure alert rules:
      - High error rate (>5% 5xx errors)
      - High latency (p99 >1s)
      - Database connection pool exhaustion
      - Celery queue backlog (>1000 tasks)
      - Pod crash loops
    - Route alerts to PagerDuty/Slack

62. **On-Call Setup**
    - Configure PagerDuty schedules
    - Create escalation policies
    - Document on-call runbooks
    - Setup incident response process

63. **Load Testing with Locust**
    - Create Locust test scenarios:
      - 1,000 concurrent users
      - 10,000 tenants
      - Mixed workload (read/write 80/20)
    - Run load tests against staging environment
    - Identify bottlenecks (database, API, cache)
    - Performance tuning (optimize queries, add indexes)

#### Week 24: Security & Production Hardening

64. **Security Hardening**
    - Enable Pod Security Policies (restrict privileged containers)
    - Configure Network Policies (deny-all by default)
    - Enable binary authorization (only signed images)
    - Setup vulnerability scanning (Trivy for images)
    - Run SAST scanning (Bandit for Python)

65. **Secret Rotation**
    - Implement secret rotation for database passwords
    - Rotate Stripe API keys
    - Rotate Django SECRET_KEY
    - Document rotation procedures

66. **Runbooks & Documentation**
    - Incident response runbook
    - Deployment runbook
    - Rollback procedures
    - Database backup and restore procedures
    - Disaster recovery plan
    - Capacity planning guide

### Deliverables

- ✅ Prometheus + Grafana operational
- ✅ Jaeger distributed tracing working
- ✅ Centralized logging configured
- ✅ Alerting and on-call setup
- ✅ Load testing completed with performance tuning
- ✅ Security hardening implemented
- ✅ Complete runbooks and documentation

### Success Criteria

- [ ] Prometheus scraping all metrics successfully
- [ ] Grafana dashboards show real-time data
- [ ] Distributed tracing captures >90% of requests
- [ ] Alerts fire correctly for test scenarios
- [ ] Load tests pass (1,000 concurrent users, <500ms p99 latency)
- [ ] Security scan shows no critical vulnerabilities

---

## 10. Phase 6: Citus Migration & Hyperscale

**Duration:** Ongoing (starts at 10K+ tenants)
**Team:** DevOps, Database Architect
**Goal:** Migrate to Citus for horizontal scalability to 1M+ tenants

### When to Migrate

**Trigger Conditions:**
- 10,000+ tenant organizations
- Database CPU >70% sustained
- Query latency p99 >500ms
- Storage approaching 1TB
- Need for horizontal scaling

### Migration Strategy

**Blue-Green Deployment:**
- Blue environment: Current Cloud SQL PostgreSQL
- Green environment: New Citus cluster
- Gradual tenant migration over 4-8 weeks
- Zero-downtime cutover

### Tasks

#### Phase 6.1: Citus Cluster Setup

67. **Provision Citus Cluster**
    - Deploy 1 coordinator node (n2-standard-8)
    - Deploy 10 worker nodes (n2-standard-8)
    - Configure 32 shards (distribute across workers)
    - Setup replication (2 replicas per shard)
    - Configure connection pooling (PgBouncer)

68. **Citus Configuration**
    - Configure distributed tables (all tenant tables)
    - Set shard key: tenant_id
    - Co-locate related tables (tenant_id co-location)
    - Configure reference tables (lookup tables)
    - Optimize Citus settings (work_mem, shared_buffers)

69. **Monitoring Citus**
    - Add Citus-specific Prometheus metrics
    - Create Grafana dashboard for shard distribution
    - Monitor query routing (coordinator vs workers)
    - Track rebalancing progress

#### Phase 6.2: Data Migration

70. **Migration Tool Development**
    - Create Python migration scripts
    - Implement incremental data sync
    - Handle schema differences
    - Validate data integrity (checksums)
    - Create rollback procedures

71. **Staging Migration Test**
    - Migrate 1,000 test tenants to Citus staging
    - Run full application test suite
    - Compare query performance (before/after)
    - Validate data consistency
    - Test failover scenarios

72. **Production Migration - Phase 1 (10%)**
    - Setup real-time data replication (Blue → Green)
    - Migrate low-activity tenants (10%)
    - Route traffic to Green environment
    - Monitor for errors and performance issues
    - Rollback capability (keep Blue in sync)

#### Phase 6.3: Full Cutover

73. **Production Migration - Phase 2 (50%)**
    - Migrate next batch of tenants (40% total)
    - Continue monitoring
    - Performance tuning (optimize Citus queries)
    - Update application code for Citus-specific optimizations

74. **Production Migration - Phase 3 (100%)**
    - Migrate remaining tenants (100% total)
    - Full cutover to Green environment
    - Stop replication from Blue
    - Blue environment on standby (30 days)

75. **Decommission Cloud SQL**
    - Observation period (30 days)
    - Final data validation
    - Decommission Blue environment
    - Cost savings analysis
    - Document migration lessons learned

#### Phase 6.4: Hyperscale Operations

76. **Shard Rebalancing**
    - Monitor shard distribution
    - Rebalance shards (move to new workers)
    - Minimize downtime during rebalancing
    - Update connection strings

77. **Scale Worker Nodes**
    - Add worker nodes as tenants grow
    - Target: 100K tenants per worker node
    - Automate worker provisioning
    - Configure auto-scaling triggers

78. **Query Optimization**
    - Analyze slow queries (pg_stat_statements)
    - Add indexes on tenant_id + other columns
    - Optimize JOIN queries (ensure co-location)
    - Use Citus-specific query patterns
    - Implement query result caching

### Deliverables

- ✅ Citus cluster operational
- ✅ All tenants migrated from Cloud SQL
- ✅ Zero-downtime migration completed
- ✅ Performance equal or better than Cloud SQL
- ✅ Horizontal scaling proven (add workers)
- ✅ Migration documentation

### Success Criteria

- [ ] Citus cluster supports 1M+ tenants
- [ ] Query latency p99 <100ms
- [ ] 99.9% uptime during migration
- [ ] Cost per tenant reduced (vs Cloud SQL)
- [ ] Ability to scale horizontally (add workers)

---

## 11. Multi-Agent Orchestration Strategy

### Agent Assignments by Phase

This section defines which CODITECT specialized agents are responsible for each phase and task.

#### Phase 0: Project Foundation

**Primary Agents:**
- `project-discovery-agent` - Requirements gathering, team onboarding
- `project-structure-optimizer` - Repository structure design
- `devops-engineer` - Development environment setup

**Invocation Syntax:**
```python
# Project initialization
Task(subagent_type="general-purpose", prompt="Use project-discovery-agent to gather requirements for Django + Citus SaaS platform")

# Repository structure
Task(subagent_type="general-purpose", prompt="Use project-structure-optimizer to create production-ready directory structure for full-stack Django/React project")

# Environment setup
Task(subagent_type="general-purpose", prompt="Use devops-engineer to configure GCP project and local development environments")
```

#### Phase 1: Infrastructure Foundation

**Primary Agents:**
- `devops-engineer` - Terraform modules, GKE deployment
- `cloud-architect` - GCP architecture design
- `database-architect` - Cloud SQL configuration

**Invocation Syntax:**
```python
# Terraform modules
Task(subagent_type="general-purpose", prompt="Use devops-engineer to create Terraform module for multi-zone GKE cluster with auto-scaling")

# GCP architecture
Task(subagent_type="general-purpose", prompt="Use cloud-architect to design VPC networking for GKE + Cloud SQL with private connectivity")

# Database setup
Task(subagent_type="general-purpose", prompt="Use database-architect to configure Cloud SQL PostgreSQL HA instance with optimal settings")
```

#### Phase 2: Django Backend Application

**Primary Agents:**
- `rust-expert-developer` (adapted for Python/Django)
- `database-architect` - Data modeling
- `multi-tenant-architect` - Multi-tenancy patterns
- `api-documentation-specialist` - API docs

**Invocation Syntax:**
```python
# Django project setup (use Rust agent's backend expertise)
Task(subagent_type="general-purpose", prompt="Use rust-expert-developer expertise (adapted to Python/Django) to create Django project structure with best practices")

# Data models
Task(subagent_type="general-purpose", prompt="Use database-architect to design multi-tenant data models (Tenant, User, Project, Task) with proper indexing")

# Multi-tenancy
Task(subagent_type="general-purpose", prompt="Use multi-tenant-architect to implement django-multitenant with row-level isolation and tenant context")

# API documentation
Task(subagent_type="general-purpose", prompt="Use api-documentation-specialist to generate OpenAPI schema and Swagger UI for Django REST Framework APIs")
```

#### Phase 3: Authentication & Billing

**Primary Agents:**
- `security-specialist` - OAuth2 implementation
- `devops-engineer` - Ory Hydra deployment
- `rust-expert-developer` (for Django integration)

**Invocation Syntax:**
```python
# Ory Hydra deployment
Task(subagent_type="general-purpose", prompt="Use devops-engineer to deploy Ory Hydra OAuth2 server in Kubernetes with PostgreSQL backend")

# OAuth2 integration
Task(subagent_type="general-purpose", prompt="Use security-specialist to implement OAuth2 authorization code flow with PKCE in Django using Authlib")

# Stripe integration
Task(subagent_type="general-purpose", prompt="Use rust-expert-developer (Python) to integrate Stripe Billing API with webhook handling and subscription management")
```

#### Phase 4: Frontend & Admin

**Primary Agents:**
- `frontend-react-typescript-expert` - React development
- `ui-ux-specialist` - Component design
- `rust-expert-developer` (for Django Admin)

**Invocation Syntax:**
```python
# React app setup
Task(subagent_type="general-purpose", prompt="Use frontend-react-typescript-expert to create React + TypeScript app with Vite, Chakra UI, and Zustand")

# UI components
Task(subagent_type="general-purpose", prompt="Use ui-ux-specialist to design responsive UI components for tenant, user, project, and task management")

# Django Admin
Task(subagent_type="general-purpose", prompt="Use rust-expert-developer (Python) to configure Django Admin with custom list filters and bulk actions")
```

#### Phase 5: Monitoring & Production Readiness

**Primary Agents:**
- `monitoring-specialist` - Prometheus, Grafana, Jaeger
- `devops-engineer` - Production hardening
- `security-specialist` - Security scanning
- `qa-specialist` - Load testing

**Invocation Syntax:**
```python
# Monitoring stack
Task(subagent_type="general-purpose", prompt="Use monitoring-specialist to deploy Prometheus + Grafana + Jaeger with comprehensive dashboards")

# Load testing
Task(subagent_type="general-purpose", prompt="Use qa-specialist to create Locust load test scenarios for 1,000 concurrent users across 10,000 tenants")

# Security hardening
Task(subagent_type="general-purpose", prompt="Use security-specialist to implement Pod Security Policies, Network Policies, and binary authorization")
```

#### Phase 6: Citus Migration & Hyperscale

**Primary Agents:**
- `database-architect` - Citus cluster design
- `devops-engineer` - Citus deployment
- `multi-tenant-architect` - Sharding strategy
- `orchestrator` - Migration coordination

**Invocation Syntax:**
```python
# Citus cluster design
Task(subagent_type="general-purpose", prompt="Use database-architect to design Citus cluster topology with coordinator and 10 worker nodes for 1M+ tenants")

# Migration planning
Task(subagent_type="general-purpose", prompt="Use orchestrator to coordinate blue-green migration from Cloud SQL to Citus with zero downtime")

# Sharding strategy
Task(subagent_type="general-purpose", prompt="Use multi-tenant-architect to implement tenant_id sharding with co-location of related tables")
```

### Cross-Functional Workflows

**Example: End-to-End Feature Development**

```python
# Step 1: Database changes
Task(subagent_type="general-purpose", prompt="Use database-architect to add new Comment model with foreign key to Task")

# Step 2: Backend API
Task(subagent_type="general-purpose", prompt="Use rust-expert-developer (Python) to create Django REST API endpoints for task comments")

# Step 3: Frontend UI
Task(subagent_type="general-purpose", prompt="Use frontend-react-typescript-expert to build comment section UI component with real-time updates")

# Step 4: Testing
Task(subagent_type="general-purpose", prompt="Use qa-specialist to create integration tests for comment API and UI")

# Step 5: Documentation
Task(subagent_type="general-purpose", prompt="Use api-documentation-specialist to update OpenAPI schema with new comment endpoints")
```

---

## 12. Timeline & Resource Requirements

### Overall Timeline

**Total Duration:** 24 weeks (6 months)
**Start Date:** Week of December 2, 2025
**Target Completion:** Week of May 25, 2026

### Weekly Breakdown

| Week | Phase | Focus Area | Team |
|------|-------|-----------|------|
| 1-2 | Phase 0 | Project Foundation | All |
| 3-6 | Phase 1 | Infrastructure (Terraform, GKE, Cloud SQL) | DevOps, Cloud Architect |
| 7-12 | Phase 2 | Django Backend (Models, APIs, Celery) | Backend Engineers |
| 13-16 | Phase 3 | Auth & Billing (Ory Hydra, Stripe) | Backend, Security |
| 17-20 | Phase 4 | Frontend & Admin (React, Django Admin) | Frontend Engineers |
| 21-24 | Phase 5 | Monitoring & Production (Prometheus, Load Testing) | DevOps, QA |
| 25+ | Phase 6 | Citus Migration (Hyperscale) | Database, DevOps |

### Team Composition

**Required Team:**
- **1x Tech Lead / Architect** (40 hrs/week)
- **2x Backend Engineers** (Python/Django) (40 hrs/week each)
- **1x Frontend Engineer** (React/TypeScript) (40 hrs/week)
- **1x DevOps Engineer** (Terraform/Kubernetes/GCP) (40 hrs/week)
- **1x Database Engineer** (PostgreSQL/Citus) (20 hrs/week)
- **1x QA Engineer** (Testing/Load Testing) (20 hrs/week)
- **1x Security Specialist** (Part-time, 10 hrs/week)

**Total:** 6.5 FTEs

### Weekly Effort Distribution

| Phase | Backend | Frontend | DevOps | Database | QA | Security | Total Hours |
|-------|---------|----------|--------|----------|----|-----------|-----------:|
| Phase 0 | 40 | 20 | 40 | 10 | 10 | 5 | 125 |
| Phase 1 | 20 | 0 | 80 | 20 | 10 | 10 | 140 |
| Phase 2 | 80 | 20 | 20 | 20 | 20 | 10 | 170 |
| Phase 3 | 60 | 20 | 20 | 10 | 20 | 20 | 150 |
| Phase 4 | 20 | 80 | 10 | 0 | 20 | 5 | 135 |
| Phase 5 | 20 | 10 | 60 | 10 | 40 | 20 | 160 |
| Phase 6 | 40 | 10 | 60 | 40 | 20 | 10 | 180 |

**Total Project Hours:** ~1,060 hours over 24 weeks

---

## 13. Budget & Cost Analysis

### Development Costs

**Labor Costs (24 weeks):**

| Role | Rate | Hours/Week | Weeks | Total |
|------|------|------------|-------|------:|
| Tech Lead | $150/hr | 40 | 24 | $144,000 |
| Backend Engineer (x2) | $120/hr | 80 | 24 | $230,400 |
| Frontend Engineer | $110/hr | 40 | 24 | $105,600 |
| DevOps Engineer | $130/hr | 40 | 24 | $124,800 |
| Database Engineer | $140/hr | 20 | 24 | $67,200 |
| QA Engineer | $100/hr | 20 | 24 | $48,000 |
| Security Specialist | $150/hr | 10 | 24 | $36,000 |

**Total Labor:** $756,000

### Infrastructure Costs

**Development Environment (24 weeks):**
- GKE cluster: $150/month × 6 months = $900
- Cloud SQL: $500/month × 6 months = $3,000
- Redis: $100/month × 6 months = $600
- Monitoring: $50/month × 6 months = $300
- Misc (networking, storage): $100/month × 6 months = $600

**Development Total:** $5,400

**Staging Environment (20 weeks):**
- GKE cluster: $300/month × 5 months = $1,500
- Cloud SQL: $800/month × 5 months = $4,000
- Redis: $200/month × 5 months = $1,000
- Monitoring: $100/month × 5 months = $500

**Staging Total:** $7,000

**Production Environment (initial):**
- GKE cluster: $2,000/month
- Cloud SQL: $5,000/month
- Redis: $500/month
- Monitoring: $300/month

**Production (first month):** $7,800

**Total Infrastructure (Development Period):** $20,200

### Third-Party Services

**Development & Staging:**
- Stripe (test mode): Free
- Ory Hydra: Free (self-hosted)
- GitHub: Free (public repo)
- Domain name: $20/year

**Production (monthly):**
- Stripe: 2.9% + $0.30 per transaction (variable)
- Sentry (error tracking): $26/month
- PagerDuty: $21/user/month × 3 = $63/month
- SSL certificates: Free (Let's Encrypt)

**Third-Party Total (Development):** ~$100
**Third-Party Total (Production, monthly):** ~$90

### Total Project Budget

| Category | Cost |
|----------|-----:|
| **Labor** | $756,000 |
| **Infrastructure (Dev/Staging)** | $12,400 |
| **Infrastructure (Prod, 1 month)** | $7,800 |
| **Third-Party Services** | $190 |
| **Contingency (10%)** | $77,639 |
| **TOTAL** | **$854,029** |

### Ongoing Costs (Post-Launch)

**Monthly Recurring Costs:**

| Item | Cost/Month |
|------|----------:|
| Infrastructure (1K-10K tenants) | $7,800 |
| Infrastructure (10K-100K tenants) | $20,000 |
| Infrastructure (100K-1M tenants) | $50,000 |
| Third-Party Services | $90 |
| Support & Maintenance (2 FTE) | $40,000 |

**Total (1K tenants):** ~$48,000/month
**Total (10K tenants):** ~$60,000/month
**Total (1M tenants):** ~$90,000/month

---

## 14. Risk Assessment

### Critical Risks

| Risk | Likelihood | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| **Citus Migration Complexity** | High | Critical | Start with thorough staging tests; blue-green deployment; gradual rollout; maintain rollback capability |
| **Performance Bottlenecks** | Medium | High | Load testing early and often; database query optimization; implement caching; horizontal scaling ready |
| **Multi-Tenant Data Leakage** | Medium | Critical | Comprehensive testing of tenant isolation; code reviews focused on tenant_id filtering; automated tests |
| **Third-Party API Changes** (Stripe, Ory) | Medium | Medium | Version lock dependencies; monitor changelogs; maintain abstraction layer for easier migration |
| **Team Availability** | Medium | High | Cross-train team members; document extensively; onboard backup engineers |
| **Cost Overruns** | Medium | Medium | Weekly cost monitoring; set budget alerts; optimize resource usage; use committed use discounts |
| **Security Vulnerabilities** | Low | Critical | Regular security audits; dependency scanning; penetration testing; bug bounty program |
| **Vendor Lock-in (GCP)** | Low | Medium | Use Terraform for portability; avoid GCP-specific features where possible; maintain exit strategy |

### Medium Risks

| Risk | Likelihood | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| **Database Schema Changes** | High | Medium | Use Django migrations; test migrations in staging; maintain backward compatibility |
| **Frontend Browser Compatibility** | Medium | Low | Test on major browsers; use polyfills; progressive enhancement |
| **Celery Task Failures** | Medium | Medium | Implement retry logic; dead letter queue; monitoring and alerting |
| **OAuth Flow Complexity** | Medium | Medium | Thorough testing; clear documentation; user-friendly error messages |
| **Monitoring Blind Spots** | Medium | Medium | Comprehensive instrumentation; regular review of metrics; user feedback integration |

### Risk Response Plans

**If Citus Migration Fails:**
1. Rollback to Cloud SQL (Blue environment)
2. Analyze failure root cause
3. Fix issues in staging
4. Retry migration after validation

**If Performance Below SLA:**
1. Identify bottleneck (database, API, cache)
2. Optimize hot path queries
3. Add indexes, optimize caching
4. Scale horizontally (add workers/pods)

**If Security Breach:**
1. Activate incident response plan
2. Isolate affected systems
3. Notify affected users (GDPR compliance)
4. Patch vulnerability
5. Post-mortem and preventive measures

---

## 15. Quality Gates & Success Metrics

### Phase Completion Criteria

Each phase must meet the following criteria before proceeding to the next phase:

#### Phase 0: Project Foundation
- [ ] Repository structure approved by tech lead
- [ ] All team members onboarded and environments configured
- [ ] Development standards documented
- [ ] First PR merged successfully

#### Phase 1: Infrastructure Foundation
- [ ] Terraform apply succeeds in all environments (dev, staging, production)
- [ ] GKE cluster healthy and accessible
- [ ] Cloud SQL instance accessible from GKE
- [ ] Redis cluster operational
- [ ] CI/CD pipeline functional (terraform validate on PR)

#### Phase 2: Django Backend Application
- [ ] All API endpoints return correct responses (200/201/204)
- [ ] Multi-tenant isolation verified (integration tests)
- [ ] Unit test coverage ≥80%
- [ ] API documentation published (Swagger UI accessible)
- [ ] Celery tasks execute successfully

#### Phase 3: Authentication & Billing
- [ ] OAuth2 login flow works end-to-end
- [ ] SSO functional across tenant subdomains
- [ ] Stripe subscriptions can be created and managed
- [ ] Webhooks handle all test scenarios correctly
- [ ] Security review passed (no critical vulnerabilities)

#### Phase 4: Frontend & Admin
- [ ] All core features accessible via UI (tenants, users, projects, tasks)
- [ ] OAuth2 login works in browser
- [ ] UI responsive on mobile, tablet, desktop (tested)
- [ ] Django Admin functional for support team
- [ ] Frontend test coverage ≥70%

#### Phase 5: Monitoring & Production Readiness
- [ ] Prometheus scraping all metrics successfully
- [ ] Grafana dashboards display real-time data
- [ ] Distributed tracing captures ≥90% of requests
- [ ] Alerts tested and firing correctly
- [ ] Load tests pass (1,000 concurrent users, p99 <500ms)
- [ ] Security scan shows no critical/high vulnerabilities
- [ ] Runbooks complete and reviewed

#### Phase 6: Citus Migration & Hyperscale
- [ ] Citus cluster operational with 10 workers
- [ ] Data migration tested in staging (100% success)
- [ ] 10% tenant migration successful with zero errors
- [ ] 100% tenant migration completed
- [ ] Performance meets or exceeds Cloud SQL baseline
- [ ] Old infrastructure decommissioned

### Key Performance Indicators (KPIs)

**Technical KPIs:**

| Metric | Target | Measurement |
|--------|--------|-------------|
| API Latency (p99) | <500ms | Prometheus histogram |
| API Error Rate | <1% | Prometheus counter |
| Database Query Time (p99) | <100ms | Prometheus histogram |
| Uptime | 99.9% | Grafana uptime panel |
| Test Coverage | ≥80% backend, ≥70% frontend | pytest, Vitest |
| Security Vulnerabilities | 0 critical/high | Trivy, Safety |
| Deployment Success Rate | ≥95% | GitHub Actions |
| Mean Time to Recovery (MTTR) | <1 hour | PagerDuty |

**Business KPIs (Post-Launch):**

| Metric | Target | Measurement |
|--------|--------|-------------|
| Active Tenants | 1,000 (Month 1) → 1M (Year 3) | Database query |
| Monthly Recurring Revenue (MRR) | $10K (Month 1) → $10M (Year 3) | Stripe dashboard |
| Customer Acquisition Cost (CAC) | <$100 | Analytics |
| Churn Rate | <5% monthly | Database query |
| API Usage per Tenant | 10,000 requests/month | Kong analytics |
| Support Tickets | <1% of active tenants | Support system |

### Acceptance Testing

**Pre-Launch Checklist:**

- [ ] All features functional in production environment
- [ ] Load test passed (1,000 concurrent users)
- [ ] Security audit completed (no critical issues)
- [ ] Disaster recovery tested (backup restore)
- [ ] Documentation complete (API, user guide, runbooks)
- [ ] On-call rotation established
- [ ] Monitoring and alerting validated
- [ ] Legal review completed (ToS, Privacy Policy)
- [ ] GDPR compliance verified
- [ ] Beta testing with 10 pilot customers successful

---

## Appendices

### A. Glossary

- **Citus:** Distributed PostgreSQL extension for horizontal scaling
- **django-multitenant:** Django library for shared-table multi-tenancy
- **Ory Hydra:** Open-source OAuth2 and OIDC server
- **GKE:** Google Kubernetes Engine (managed Kubernetes)
- **Cloud SQL:** Google Cloud managed PostgreSQL service
- **Terraform:** Infrastructure as Code tool
- **Celery:** Distributed task queue for Python
- **JWT:** JSON Web Token (for authentication)
- **RBAC:** Role-Based Access Control
- **SLA:** Service Level Agreement
- **p99:** 99th percentile (latency metric)
- **HA:** High Availability
- **SAST:** Static Application Security Testing

### B. References

- Django Documentation: https://docs.djangoproject.com/
- django-multitenant: https://github.com/citusdata/django-multitenant
- Citus Documentation: https://docs.citusdata.com/
- Ory Hydra: https://www.ory.sh/docs/hydra/
- Stripe Billing API: https://stripe.com/docs/billing
- Terraform GCP Provider: https://registry.terraform.io/providers/hashicorp/google/latest
- GKE Documentation: https://cloud.google.com/kubernetes-engine/docs
- Prometheus: https://prometheus.io/docs/
- Grafana: https://grafana.com/docs/

### C. Decision Log

See `docs/adrs/` directory for Architecture Decision Records (ADRs):
- ADR-001: Choice of Django over FastAPI
- ADR-002: Shared-table multi-tenancy with Citus
- ADR-003: Ory Hydra for OAuth2 server
- ADR-004: Stripe for billing (vs custom solution)
- ADR-005: React + TypeScript for frontend
- ADR-006: GKE for container orchestration

---

**Document Version:** 2.0
**Last Updated:** November 23, 2025
**Next Review:** December 1, 2025
**Owner:** CODITECT Architecture Team
**Status:** APPROVED FOR EXECUTION

---

## Document Change History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Nov 22, 2025 | Architecture Team | Initial high-level plan (3 phases, 28 tasks) |
| 2.0 | Nov 23, 2025 | Architecture Team | Comprehensive expansion covering all components (6 phases, 150+ tasks) |
