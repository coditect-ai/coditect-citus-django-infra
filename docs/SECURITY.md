# Security Best Practices

**CODITECT Citus Django Infrastructure**

**Last Updated:** November 23, 2025

---

## Table of Contents

1. [Security Principles](#security-principles)
2. [Authentication & Authorization](#authentication--authorization)
3. [Data Security](#data-security)
4. [Network Security](#network-security)
5. [Secrets Management](#secrets-management)
6. [Security Scanning](#security-scanning)
7. [Incident Response](#incident-response)
8. [Compliance](#compliance)

---

## Security Principles

### Defense in Depth

- **Multiple layers** of security controls
- **Fail securely** - default deny
- **Least privilege** - minimal access rights
- **Separation of duties** - no single point of failure

### Security by Design

- **Threat modeling** during architecture phase
- **Security reviews** for all features
- **Automated security testing** in CI/CD
- **Regular penetration testing**

---

## Authentication & Authorization

### OAuth2/OIDC (Ory Hydra)

**Authentication Flow:**

```
User → Frontend → API Gateway → Ory Hydra → JWT Token → API
```

**Token Validation:**
- JWT signature verification (RS256)
- Token expiration check (1 hour)
- Scope validation
- Tenant isolation check

**Multi-Factor Authentication:**
- TOTP (Google Authenticator)
- SMS (Twilio)
- Email verification

### Role-Based Access Control (RBAC)

**Roles:**
- `owner` - Full organization access
- `admin` - Manage users and settings
- `member` - Read/write access
- `viewer` - Read-only access

**Permissions:**
- `organizations.view`
- `organizations.edit`
- `users.invite`
- `users.remove`
- `billing.view`
- `billing.edit`

**Example:**

```python
from rest_framework.permissions import BasePermission

class CanEditOrganization(BasePermission):
    def has_object_permission(self, request, view, obj):
        # Check if user is owner or admin
        return obj.members.filter(
            user=request.user,
            role__in=['owner', 'admin']
        ).exists()
```

---

## Data Security

### Encryption at Rest

**Database:**
- GCP Cloud SQL - Customer-Managed Encryption Keys (CMEK)
- Automated backups - encrypted with same key
- Export/import - encrypted in transit and at rest

**File Storage:**
- Google Cloud Storage - encryption enabled by default
- Customer-Managed Encryption Keys (CMEK) for sensitive data

### Encryption in Transit

- **TLS 1.3** for all connections
- **HTTPS only** (no HTTP allowed)
- **Certificate pinning** for mobile apps
- **mTLS** for service-to-service communication

### Multi-Tenant Data Isolation

**Row-Level Security:**

```python
# Django middleware enforces tenant context
class TenantMiddleware:
    def __call__(self, request):
        tenant_id = extract_tenant_from_request(request)
        set_current_tenant(tenant_id)
        response = self.get_response(request)
        return response

# All queries automatically filtered
users = User.objects.all()  # Only current tenant's users
```

**Database-Level Isolation:**

```sql
-- PostgreSQL Row-Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON users
    USING (tenant_id = current_setting('app.current_tenant')::uuid);
```

### PII Handling

**Data Classification:**
- **Public:** Organization name, public profiles
- **Internal:** User emails, phone numbers
- **Restricted:** Payment information, SSN
- **Confidential:** Passwords (hashed), API keys

**GDPR Compliance:**
- Data retention policies (7 years for billing, 90 days for logs)
- Right to be forgotten (user deletion)
- Data portability (export user data)
- Consent management (opt-in for marketing)

---

## Network Security

### VPC Configuration

**Network Segmentation:**

```
┌─────────────────────────────────────┐
│         Public Subnet               │
│  - Load Balancer                    │
│  - NAT Gateway                      │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│         Private Subnet              │
│  - GKE Nodes                        │
│  - Application Pods                 │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│      Database Subnet (Isolated)     │
│  - Cloud SQL                        │
│  - Redis                            │
└─────────────────────────────────────┘
```

**Firewall Rules:**

```hcl
# opentofu/modules/networking/firewall.tf

# Allow HTTPS from internet
resource "google_compute_firewall" "allow_https" {
  name    = "allow-https"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server"]
}

# Deny all other inbound traffic
resource "google_compute_firewall" "deny_all" {
  name     = "deny-all-inbound"
  network  = google_compute_network.vpc.name
  priority = 65535

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}
```

### Cloud Armor (DDoS Protection)

**Rate Limiting:**
- 1000 requests/minute per IP
- 10,000 requests/minute per tenant

**Bot Protection:**
- reCAPTCHA v3 integration
- Known bot IP blocking
- Challenge-response for suspicious traffic

**Geo-Blocking:**
- Block traffic from high-risk countries (optional)

---

## Secrets Management

### GCP Secret Manager

**Secret Storage:**

```bash
# Create secret
gcloud secrets create django-secret-key \
    --data-file=- \
    --replication-policy="automatic"

# Grant access to service account
gcloud secrets add-iam-policy-binding django-secret-key \
    --member="serviceAccount:django-sa@project.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"
```

**Secret Rotation:**
- Automatic rotation every 90 days
- Manual rotation for compromised secrets
- Version tracking for rollback

### Kubernetes Secrets

**External Secrets Operator:**

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: django-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcpsm-secret-store
    kind: SecretStore
  target:
    name: django-app-secrets
  data:
    - secretKey: SECRET_KEY
      remoteRef:
        key: django-secret-key
```

### Never Commit Secrets

**Pre-commit Hook:**

```yaml
# .pre-commit-config.yaml
- repo: https://github.com/Yelp/detect-secrets
  rev: v1.4.0
  hooks:
    - id: detect-secrets
      args: ['--baseline', '.secrets.baseline']
```

---

## Security Scanning

### Dependency Scanning

**Automated Scans:**

```bash
# Python dependencies
pip-audit

# GitHub Dependabot (automated PRs)
# Configured in .github/dependabot.yml
```

**Critical Vulnerability Response:**
- < 24 hours for critical
- < 7 days for high
- < 30 days for medium

### SAST (Static Application Security Testing)

**Bandit (Python):**

```bash
# Run security scan
bandit -r coditect_platform/

# Exclude false positives
bandit -r . -ll -i
```

**SonarQube:**
- Code quality and security issues
- Code coverage analysis
- Technical debt tracking

### DAST (Dynamic Application Security Testing)

**OWASP ZAP:**

```bash
# Run ZAP scan against staging
docker run -t owasp/zap2docker-stable zap-baseline.py \
    -t https://staging.coditect.ai \
    -r zap-report.html
```

**Nuclei:**

```bash
# Scan for known vulnerabilities
nuclei -u https://staging.coditect.ai \
    -t cves/ -t vulnerabilities/
```

### Container Scanning

**Trivy:**

```bash
# Scan Docker image
trivy image coditect/django-backend:latest

# Fail on HIGH or CRITICAL
trivy image --exit-code 1 --severity HIGH,CRITICAL coditect/django-backend:latest
```

---

## Incident Response

### Incident Classification

**Severity Levels:**
- **P0 (Critical):** Data breach, complete service outage
- **P1 (High):** Partial outage, security vulnerability exploit
- **P2 (Medium):** Degraded performance, non-exploited vulnerability
- **P3 (Low):** Minor issue, no security impact

### Incident Response Plan

**1. Detection**
- Automated alerts (Prometheus/Grafana)
- User reports
- Security scanning tools

**2. Containment**
- Isolate affected systems
- Block malicious traffic
- Rotate compromised credentials

**3. Investigation**
- Collect logs and evidence
- Identify root cause
- Determine scope of impact

**4. Remediation**
- Apply patches/fixes
- Restore from backup if needed
- Verify fix effectiveness

**5. Post-Incident Review**
- Document timeline
- Identify lessons learned
- Update runbooks and procedures

### Security Contacts

- **Security Team:** security@coditect.ai
- **On-Call Engineer:** +1 (555) 123-4567
- **Incident Slack Channel:** #security-incidents

---

## Compliance

### GDPR (General Data Protection Regulation)

**Requirements:**
- Data processing consent
- Right to access data
- Right to be forgotten
- Data portability
- Breach notification (<72 hours)

**Implementation:**
- Consent management system
- User data export API
- User deletion workflow
- Encrypted backups in EU region

### SOC 2 Type II

**Controls:**
- Access control policies
- Change management procedures
- Incident response plan
- Monitoring and logging
- Regular security audits

### HIPAA (if handling health data)

**Technical Safeguards:**
- Encryption at rest and in transit
- Access controls and audit logs
- Automatic logoff after inactivity
- Data backup and disaster recovery

---

## Security Checklist

### Development

- [ ] All dependencies are up-to-date
- [ ] No secrets in code or configuration
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (ORM)
- [ ] XSS prevention (template escaping)
- [ ] CSRF protection enabled
- [ ] Rate limiting configured
- [ ] Authentication required for sensitive endpoints

### Deployment

- [ ] TLS certificates valid and auto-renewing
- [ ] Database encryption enabled
- [ ] Firewall rules configured
- [ ] Secrets stored in Secret Manager
- [ ] Security scanning passed (SAST/DAST)
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery tested

### Production

- [ ] Regular security audits (quarterly)
- [ ] Penetration testing (annually)
- [ ] Incident response drills (bi-annually)
- [ ] Security training for team (annually)
- [ ] Vulnerability disclosure program
- [ ] Bug bounty program (optional)

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Django Security](https://docs.djangoproject.com/en/stable/topics/security/)
- [GCP Security Best Practices](https://cloud.google.com/security/best-practices)
- [Kubernetes Security](https://kubernetes.io/docs/concepts/security/)

---

**Document Owner:** CODITECT Security Team
**Review Cycle:** Quarterly
**Next Review:** February 2026
