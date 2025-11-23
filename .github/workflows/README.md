# GitHub Actions Workflows - OpenTofu CI/CD

This directory contains GitHub Actions workflows for automating OpenTofu infrastructure management.

## 📋 Workflows Overview

### 1. `tofu-validate.yml` - Validation & Security

**Triggers:**
- Pull requests that modify `opentofu/**`
- Pushes to `main` branch

**What it does:**
- ✅ Validates OpenTofu syntax across all 3 environments (dev, staging, production)
- ✅ Runs `tofu fmt -check` to ensure consistent formatting
- ✅ Performs security scanning with Trivy
- ✅ Lints code with tflint

**Matrix Strategy:** Runs validation for dev, staging, and production in parallel

---

### 2. `tofu-plan.yml` - Infrastructure Planning

**Triggers:**
- Pull requests that modify `opentofu/**`

**What it does:**
- 📊 Creates execution plans for all environments
- 💬 Posts plan output as PR comments
- 💰 Generates cost estimates using Infracost
- 📦 Uploads plan artifacts for review

**Artifacts:**
- `tofu-plan-{environment}` - Contains tfplan and readable plan output
- Retention: 30 days

**Requirements:**
- GCP Workload Identity configured
- Secret variables:
  - `GCP_WORKLOAD_IDENTITY_PROVIDER`
  - `GCP_SERVICE_ACCOUNT`

---

### 3. `tofu-apply.yml` - Infrastructure Deployment

**Triggers:**
- Manual (`workflow_dispatch`) only

**Parameters:**
- `environment` (required): dev | staging | production
- `auto_approve` (optional): Skip manual approval (use with caution!)

**What it does:**
1. **Validate** - Pre-deployment validation
2. **Approve** - Manual approval gate (unless auto_approve=true)
3. **Apply** - Deploys infrastructure changes
4. **Verify** - Post-deployment health checks

**Approval Flow:**
- Requires environment protection rules in GitHub
- Approvers configured per environment
- Production requires 2+ approvals (recommended)

**Post-Deployment Checks:**
- Verifies GKE cluster existence
- Verifies Cloud SQL instance
- Verifies Redis instance

**Artifacts:**
- `apply-log-{environment}-{run_number}` - Complete deployment log
- Retention: 90 days

---

### 4. `tofu-drift-detection.yml` - Daily Drift Monitoring

**Triggers:**
- Scheduled: Daily at 6 AM UTC
- Manual (`workflow_dispatch`)

**What it does:**
- 🔍 Detects infrastructure drift (manual changes outside OpenTofu)
- 📝 Creates GitHub issues when drift detected
- 📊 Generates daily drift summary

**Drift Detection Logic:**
- Exit code 0 = No changes needed (no drift)
- Exit code 1 = Error occurred
- Exit code 2 = Changes detected (drift!)

**Issue Management:**
- Creates new issue if none exists
- Updates existing issue with new drift details
- Labels: `drift-detection`, `infrastructure`, `{environment}`
- Priority based on environment:
  - Production: 🔴 HIGH
  - Staging/Dev: 🟡 MEDIUM

**Artifacts:**
- `drift-report-{environment}-{run_number}` - Drift and refresh logs
- Retention: 30 days

---

## 🔧 Setup Instructions

### 1. Configure GitHub Secrets

Required secrets (GitHub Settings → Secrets and variables → Actions):

```bash
GCP_WORKLOAD_IDENTITY_PROVIDER=projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID
GCP_SERVICE_ACCOUNT=github-actions@PROJECT_ID.iam.gserviceaccount.com
```

### 2. Setup GCP Workload Identity Federation

```bash
# Create workload identity pool
gcloud iam workload-identity-pools create "github-actions" \
  --project="PROJECT_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create workload identity provider
gcloud iam workload-identity-pools providers create-oidc "github" \
  --project="PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-actions" \
  --display-name="GitHub provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Create service account
gcloud iam service-accounts create github-actions \
  --display-name="GitHub Actions Service Account"

# Grant permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:github-actions@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Allow GitHub to impersonate service account
gcloud iam service-accounts add-iam-policy-binding \
  github-actions@PROJECT_ID.iam.gserviceaccount.com \
  --project="PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/attribute.repository/coditect-ai/coditect-citus-django-infra"
```

### 3. Configure Environment Protection Rules

**GitHub Settings → Environments:**

**Development:**
- No protection rules (auto-deploy for testing)

**Staging:**
- Required reviewers: 1+
- Deployment branches: `main` only

**Production:**
- Required reviewers: 2+
- Wait timer: 5 minutes
- Deployment branches: `main` only
- Prevent self-review

### 4. Install Required GitHub Apps

- **Dependabot** - Already configured in `dependabot.yml`
- **CodeQL** - For security scanning (optional but recommended)

---

## 📊 Workflow Outputs

### Validation Workflow
- ✅ Pass/Fail status on PRs
- Security scan results in GitHub Security tab
- Lint warnings in job logs

### Plan Workflow
- PR comments with full plan output (collapsible)
- Cost estimates as separate PR comment
- Downloadable plan artifacts

### Apply Workflow
- Deployment summary in job summary
- Apply logs as downloadable artifacts
- Post-deployment verification results

### Drift Detection
- GitHub issues for drift alerts
- Daily summary in workflow runs
- Drift reports as downloadable artifacts

---

## 🚨 Common Issues & Solutions

### Issue: "Error: Failed to get existing workspaces"

**Cause:** Backend not initialized or GCS bucket doesn't exist

**Solution:**
```bash
cd opentofu/environments/dev
tofu init -backend-config="bucket=PROJECT_ID-terraform-state"
```

### Issue: Workflow fails with "Workload Identity authentication failed"

**Cause:** Workload Identity Federation not configured correctly

**Solution:**
1. Verify `GCP_WORKLOAD_IDENTITY_PROVIDER` secret is correct
2. Check service account has `roles/iam.workloadIdentityUser`
3. Verify repository attribute mapping in provider config

### Issue: Cost estimation fails

**Cause:** Infracost API key not configured

**Solution:**
- This is optional - workflow will continue without cost estimates
- To enable: Sign up at infracost.io and add `INFRACOST_API_KEY` secret

### Issue: Drift detection creates duplicate issues

**Cause:** Issue labels don't match

**Solution:**
- Ensure drift issues have labels: `drift-detection` and `{environment}`
- Close old drift issues manually if needed

---

## 🎯 Best Practices

### For Developers

1. **Always run validation locally first:**
   ```bash
   cd opentofu/environments/dev
   tofu fmt -recursive
   tofu validate
   ```

2. **Review plans before merging:**
   - Check PR comments for plan output
   - Verify cost estimates are acceptable
   - Ensure no unexpected deletions

3. **Use meaningful commit messages:**
   - `feat(infra): Add Redis caching layer`
   - `fix(gke): Increase node pool max size`
   - `chore(config): Update Cloud SQL backup retention`

### For Operators

1. **Production deployments:**
   - Always deploy to dev → staging → production
   - Never use `auto_approve=true` for production
   - Monitor post-deployment verification

2. **Drift management:**
   - Address drift issues within 24 hours
   - Document why manual changes were made
   - Update OpenTofu code or re-apply to fix drift

3. **Cost monitoring:**
   - Review Infracost estimates on every PR
   - Set up GCP billing alerts
   - Monthly cost review meetings

---

## 📚 Additional Resources

- [OpenTofu Documentation](https://opentofu.org/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [Infracost Documentation](https://www.infracost.io/docs/)

---

**Last Updated:** November 23, 2025
**OpenTofu Version:** 1.10.7
**Maintained by:** CODITECT Infrastructure Team
