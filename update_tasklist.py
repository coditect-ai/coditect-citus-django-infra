#!/usr/bin/env python3
"""Update TASKLIST-WITH-CHECKBOXES.md to mark Phase 0 tasks as complete."""

import re

# Read the tasklist
with open('TASKLIST-WITH-CHECKBOXES.md', 'r') as f:
    content = f.read()

# Tasks we've completed (0.1 through 0.7 are done, plus documentation)
completed_patterns = [
    # Task 0.1
    r'- \[ \] Create coditect-citus-django-infra repository',
    r'- \[ \] Setup \.gitignore for Python',
    r'- \[ \] Setup \.gitignore for Terraform',
    r'- \[ \] Setup \.gitignore for Kubernetes',
    
    # Task 0.2
    r'- \[ \] Create terraform/ directory structure',
    r'- \[ \] Create kubernetes/ directory',
    r'- \[ \] Create django/ directory',
    r'- \[ \] Create docs/ directory',
    r'- \[ \] Create scripts/ directory',
    r'- \[ \] Create tests/ directory',
    
    # Task 0.3
    r'- \[ \] Create \.coditect symlink',
    r'- \[ \] Create \.claude symlink',
    r'- \[ \] Verify symlinks work',
    r'- \[ \] Test access to CODITECT',
    
    # Task 0.4
    r'- \[ \] Create README\.md',
    r'- \[ \] Create CONTRIBUTING\.md',
    r'- \[ \] Create LICENSE',
    r'- \[ \] Create CLAUDE\.md',
    r'- \[ \] Create CODE_OF_CONDUCT\.md',
    
    # Task 0.5
    r'- \[ \] Create pyproject\.toml',
    r'- \[ \] Create requirements\.txt',
    r'- \[ \] Create requirements-dev\.txt',
    
    # Task 0.6
    r'- \[ \] Create \.ruff\.toml',
    r'- \[ \] Create pyproject\.toml \[tool\.black\]',
    r'- \[ \] Create \.pre-commit-config\.yaml',
    
    # Task 0.7
    r'- \[ \] Create \.github/pull_request_template\.md',
    r'- \[ \] Create \.github/ISSUE_TEMPLATE/',
    r'- \[ \] Document commit message conventions',
    r'- \[ \] Create commit message template',
]

# Replace unchecked with checked
for pattern in completed_patterns:
    content = re.sub(pattern, lambda m: m.group(0).replace('[ ]', '[x]'), content)

# Write back
with open('TASKLIST-WITH-CHECKBOXES.md', 'w') as f:
    f.write(content)

print("✅ Updated TASKLIST-WITH-CHECKBOXES.md with completed tasks")
