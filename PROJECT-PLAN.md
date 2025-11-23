# Project Plan: Hyper-Scale SaaS with Django and Citus

**Project:** CODITECT Hyper-Scale Multi-Tenant SaaS Platform
**Date:** November 22, 2025
**Owner:** CODITECT Architecture Team
**Status:** DRAFT

---

## 1. Executive Summary

This document outlines the project plan for building and scaling the CODITECT SaaS platform to support **1 million+ tenant organizations**. The architecture is based on the "Hyper-Scale" recommendation from the `SAAS-FRAMEWORK-COMPARISON-2025.md` document.

The core of the architecture is a **shared-table multi-tenancy model** using **Django** as the application framework, **Citus** for distributed PostgreSQL, and **`django-multitenant`** for application-level tenant isolation.

The project is divided into three main phases:
1.  **Phase 1: Foundation (MVP on `django-tenants`)**: To achieve rapid product-market fit.
2.  **Phase 2: Scale Preparation**: To refactor the application in preparation for migration.
3.  **Phase 3: Migration to Citus**: To transition to the hyper-scale architecture.

---

## 2. Technology Stack

The technology stack is defined by the "Hyper-Scale (1M+ Tenants)" requirements.

| Component | Recommended Solution |
|---|---|
| **Architecture** | Microservices |
| **Backend Framework** | Django 5.x |
| **Multi-Tenancy** | `django-multitenant` + Citus |
| **Database** | Citus (Distributed PostgreSQL) |
| **Authentication** | Ory Hydra + Authlib |
| **Payments** | Stripe Billing API |
| **API Gateway** | Kong or Traefik |
| **Load Balancer** | Google Cloud Load Balancer |
| **Caching** | Redis Cluster |
| **Task Queue** | Celery + RabbitMQ Cluster |
| **Orchestration** | Kubernetes (GKE) |
| **Observability** | Prometheus + Grafana + Jaeger |

---

## 3. Phase 1: Foundation & MVP (0 - 10,000 Tenants)

**Goal:** Launch an MVP quickly to validate product-market fit. Use a simpler, schema-per-tenant architecture that is faster to develop.
**Timeline:** 3 Months
**Architecture:** Monolithic Django application with `django-tenants`.

### Phase 1 Tasks:

**Task ID** | **Task Name** | **Team** | **Effort (days)** | **Description**
---|---|---|---|---
**P1-T01** | **Environment Setup** | DevOps | 5 | Set up development, staging, and production environments on Google Cloud Platform (GCP).
**P1-T02** | **Django Project Initialization** | Backend | 3 | Initialize Django project, configure settings, and set up basic application structure.
**P1-T03** | **Multi-Tenancy with `django-tenants`**| Backend | 5 | Integrate `django-tenants` for schema-per-tenant isolation. Define `Tenant` and `Domain` models.
**P1-T04** | **Core API Development** | Backend | 15 | Build core business logic, models (Project, Task, etc.), and DRF-based APIs. **Crucially, all models must include a `tenant_id` field from day one to prepare for Phase 2.**
**P1-T05** | **User Authentication with Authlib** | Backend | 7 | Implement user registration, login, and session management using Authlib integrated into Django.
**P1-T06** | **Subscription & Billing with Stripe**| Backend | 10 | Integrate Stripe Billing for subscription management. Implement webhook handlers for payment events.
**P1-T07** | **Frontend Scaffolding** | Frontend | 10 | Set up a React/Vue frontend application. Implement routing, state management, and basic UI components.
**P1-T08** | **Frontend-Backend Integration** | Frontend/Backend| 10 | Connect frontend to backend APIs for all core features.
**P1-T09** | **CI/CD Pipeline** | DevOps | 5 | Implement GitHub Actions for automated testing and deployment to staging and production.
**P1-T10** | **MVP Launch** | All | 5 | Final testing, documentation, and go-live.

### Phase 1 Milestones:
-   **M1.1:** Development environment is fully operational.
-   **M1.2:** Core backend APIs with `django-tenants` are complete.
-   **M1.3:** User authentication and billing are functional.
-   **M1.4:** MVP is live and accepting tenants.

---

## 4. Phase 2: Scale Preparation (10,000 - 50,000 Tenants)

**Goal:** Refactor the application to be compatible with `django-multitenant` and Citus. Begin building out the microservices architecture in a staging environment.
**Timeline:** 6 Months
**Architecture:** Hybrid. Production remains on Phase 1 monolith. A new staging environment is built with the microservices architecture.

### Phase 2 Tasks:

**Task ID** | **Task Name** | **Team** | **Effort (days)** | **Description**
---|---|---|---|---
**P2-T01** | **Setup Citus Staging Cluster** | DevOps | 10 | Deploy a 3-worker Citus cluster in a dedicated staging environment.
**P2-T02** | **Data Migration Scripting** | Backend | 15 | Develop and test scripts to migrate data from `django-tenants` (schemas) to a shared-table model (using `tenant_id`).
**P2-T03** | **Refactor to `django-multitenant`**| Backend | 20 | In a separate branch, replace `django-tenants` with `django-multitenant`. Ensure all queries are correctly filtered by `tenant_id`.
**P2-T04** | **Microservices Scaffolding (GKE)** | DevOps | 15 | Set up a Google Kubernetes Engine (GKE) cluster. Define services for Auth, Core API, and Billing.
**P2-T05** | **Auth Service (`Ory Hydra`)** | Backend | 15 | Build and deploy the standalone authentication service using Ory Hydra.
**P2-T06** | **API Gateway Setup (Kong)** | DevOps | 10 | Deploy and configure Kong as the API gateway for routing requests to the new microservices.
**P2-T07** | **Observability Stack** | DevOps | 10 | Deploy Prometheus, Grafana, and Jaeger to the Kubernetes cluster for monitoring.
**P2-T08** | **Staging Migration Test** | Backend/DevOps | 10 | Perform a full migration of a subset of production data (e.g., 1,000 tenants) to the Citus staging environment. Validate data integrity and performance.
**P2-T09** | **Load Testing** | QA/DevOps | 10 | Use Locust to load-test the new microservices architecture to ensure it meets performance requirements.

### Phase 2 Milestones:
-   **M2.1:** Citus staging cluster is operational.
-   **M2.2:** Data migration scripts are complete and validated.
-   **M2.3:** All core services are containerized and deployed on Kubernetes in staging.
-   **M2.4:** Successful end-to-end test of the hyper-scale architecture in the staging environment.

---

## 5. Phase 3: Migration to Citus & Hyper-Scale (50,000 - 1M+ Tenants)

**Goal:** Complete the full migration of the production environment to the hyper-scale microservices architecture with zero downtime.
**Timeline:** 3-6 Months
**Architecture:** Blue-Green deployment strategy.

### Phase 3 Tasks:

**Task ID** | **Task Name** | **Team** | **Effort (days)** | **Description**
---|---|---|---|---
**P3-T01** | **Deploy Citus Production Cluster** | DevOps | 10 | Deploy a production-grade Citus cluster (e.g., 10+ worker nodes).
**P3-T02** | **Deploy Microservices to Production**| DevOps | 10 | Deploy the new microservices stack (the "Green" environment) into the production namespace, running parallel to the existing monolith (the "Blue" environment).
**P3-T03** | **Setup Real-time Data Sync** | Backend/DevOps | 15 | Implement a data synchronization mechanism (e.g., logical replication or application-level triggers) from the old database to the new Citus cluster.
**P3-T04** | **Blue-Green Traffic Routing** | DevOps | 5 | Configure the load balancer to allow for gradual traffic shifting from the Blue environment to the Green environment.
**P3-T05** | **Initial Tenant Migration (10%)** | All | 7 | Migrate a small percentage of new and low-activity tenants to the Green environment. Monitor closely for any issues.
**P3-T06** | **Incremental Tenant Migration** | All | 30 | Gradually migrate the remaining tenants in batches over several weeks.
**P3-T07** | **Full Cutover** | All | 2 | Shift 100% of traffic to the Green environment. The Blue environment is now on standby.
**P3-T08** | **Decommission Old Infrastructure** | DevOps | 5 | After a 30-day observation period with no major issues, decommission the old monolithic infrastructure.
**P3-T09** | **Scale Citus Cluster** | DevOps | Ongoing | Add more worker nodes to the Citus cluster as the number of tenants grows towards 1M+.

### Phase 3 Milestones:
-   **M3.1:** Production hyper-scale environment is live and running in parallel.
-   **M3.2:** 10% of tenants successfully migrated and operating on the new architecture.
-   **M3.3:** 100% of traffic is successfully routed to the new Citus-based architecture.
-   **M3.4:** Old infrastructure is successfully decommissioned. The project is complete.

---

## 6. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **`django-tenants` performance bottleneck** | Medium | Medium | Occurs during Phase 1. Mitigated by migrating to Phase 3. Monitor DB performance closely. |
| **Data Migration Complexity** | High | High | Develop robust, idempotent migration scripts (P2-T02). Perform multiple test runs in staging (P2-T08). Have a clear rollback plan. |
| **Citus Performance Tuning** | Medium | High | Engage with CitusData/Microsoft support. Dedicate DevOps time for performance tuning and query optimization. |
| **Microservice Complexity** | High | Medium | Invest heavily in the observability stack (P2-T07) and distributed tracing to manage complexity. |
| **Vendor Lock-in (Stripe/AWS/GCP)** | Medium | Medium | Abstract payment logic and infrastructure provisioning to allow for future changes if necessary. |
