# HoneyBadgers Infrastructure Overview

## 1. Purpose & High-Level Architecture

HoneyBadgers is a honeynet/honeypot environment on AWS designed to capture, store, and analyze real-world attacker activity.  
The infrastructure (Dev A) focuses on:

- A secure, isolated network (VPC with public/private subnets).
- Centralized logging (S3, CloudWatch Logs, VPC Flow Logs).
- A ThreatIntel data store (DynamoDB) for parsed attacker events.
- Automation via Lambda functions and WAF IP sets to block bad IPs.
- An API Gateway entry point to expose health/status (and later additional APIs).

Two environments are defined:

- **dev**  Actively used for experimentation and development.
- **prod**  A skeleton that mirrors dev, but has **not** been applied yet.

---

## 2. Environments: `infra/envs/dev` and `infra/envs/prod`

Both environments share the same module structure, but have separate state and variables.  
Each environment has:

- `backend.tf`  S3 backend configuration for Terraform state.
- `providers.tf`  AWS provider + `required_providers` block.
- `variables.tf`  Common inputs (region, project name, env, etc.).
- `terraform.tfvars`  Environment-specific values (log bucket name, table name, profile, etc.).
- `main.tf`  Wires all core modules together.
- `outputs.tf`  Exposes IDs, ARNs, and URLs needed by other dev roles.

### 2.1 Backend Configuration

- **Dev backend** (`infra/envs/dev/backend.tf`):

  - `bucket = "honeybadgers-tf-state-dev-usw2"`
  - `key    = "dev/terraform.tfstate"`
  - `region = "us-west-2"`

- **Prod backend** (`infra/envs/prod/backend.tf`):

  - `bucket = "honeybadgers-tf-state-dev-usw2"`
  - `key    = "prod/terraform.tfstate"`
  - `region = "us-west-2"`

> Note: `backend.tf` files are **backend-only** (no provider block).

### 2.2 Provider Configuration & Profiles

Both dev and prod use the same provider pattern in `providers.tf`:

- `terraform` block with `required_providers` for AWS (version `>= 5.0, < 7.0`).
- `provider "aws"` block:

  - `region  = var.aws_region`
  - `profile = var.aws_profile`

Per-environment:

- `var.aws_region` and `var.aws_profile` are defined in `variables.tf`.
- Values are set in `terraform.tfvars`, for example in **dev**:

  - `aws_region  = "us-west-2"`
  - `aws_profile = "honeybadgers-dev"`

---

## 3. Core Infrastructure Modules (`infra/modules/`)

This section summarizes each Terraform module and what it does.

### 3.1 `vpc/`  Networking

Responsible for the core network layout:

- Creates a VPC (`vpc_cidr`).
- Defines public and private subnets.
- Attaches an Internet Gateway for public access.
- Configures route tables and associations.
- Provides outputs for VPC ID, subnet IDs, and route tables.

Used by:

- Honeypot EC2 instances (public subnets).
- Any private components in later phases (private subnets).

---

### 3.2 `s3_logs/`  Central Logs Bucket

Provides an S3 bucket for centralized logging:

- Versioning enabled (keeps history of log objects).
- Server-side encryption (SSE) enabled.
- Lifecycle rules to manage long-term storage (for cost control).

Typical usage:

- VPC Flow Logs delivery.
- CloudWatch Logs exports (if configured later).
- Other log sources (honeypot system logs, etc.).

---

### 3.3 `cw/`  CloudWatch Log Groups

Defines CloudWatch Log Groups used by the platform, such as:

- Honeypot event logs (attacks, sessions).
- Log Groups for Lambda functions (parser, WAF automation, health).
- Retention period is controlled by `cw_log_retention` (for example, 90 days in dev).

These log groups are the source of truth for raw events that the parser Lambda will consume.

---

### 3.4 `flow_logs/`  VPC Flow Logs

Connects VPC Flow Logs to CloudWatch:

- Configures a Flow Log for the VPC.
- Uses an IAM role and policy so Flow Logs can write to CloudWatch.
- Sends network traffic metadata into the CloudWatch log group.

This allows analysis of:

- Source/destination IPs.
- Ports and protocols.
- Accept/deny decisions from the VPC network layer.

---

### 3.5 `dynamodb/`  ThreatIntel Table

Creates the DynamoDB **ThreatIntel** table:

- Stores attacker IPs and related metadata.

Typical (logical) schema:

- `ip`  partition key.
- `first_seen`.
- `last_seen`.
- `attack_types`.
- `score` or similar risk metric.

Table options:

- Time to Live (TTL) for automatic expiry of old entries.
- Point-in-time recovery (PITR) for safety.

The parser Lambda writes here; the WAF automation Lambda reads from here.

---

### 3.6 `iam/`  IAM Roles & Policies

Defines IAM roles and policies for automation:

- **Parser Lambda role**:

  - Allows reading from CloudWatch Logs.
  - Allows writing to the ThreatIntel DynamoDB table.

- **WAF automation Lambda role**:

  - Allows reading from the ThreatIntel DynamoDB table.
  - Allows updating the WAF IPSet.

These roles are consumed by the respective Lambda functions in the `lambdas/` module.

---

### 3.7 `waf/`  WAFv2 IPSet

Creates a WAFv2 **REGIONAL** IPSet:

- Resource: `aws_wafv2_ip_set "blocked_ips"`.
- Used to store IPs that should be blocked at the edge.

Outputs:

- `waf_blocked_ipset_id`.
- `waf_blocked_ipset_arn`.

The WAF automation Lambda uses this IPSet to programmatically block attacker IPs detected in ThreatIntel.

---

### 3.8 `lambdas/`  Parser, WAF Automation, Health

Wires Lambda functions and their triggers:

- **Parser Lambda**:

  - Subscribed to CloudWatch Logs (for example, honeypot events).
  - Parses logs and extracts attacker IPs/events.
  - Writes parsed data into the ThreatIntel DynamoDB table.

- **WAF Automation Lambda**:

  - Scheduled via EventBridge (for example, `rate(5 minutes)`).
  - Reads ThreatIntel data and updates the WAF blocked IPSet.

- **Health Lambda**:

  - Simple function used for API Gateway `/health` checks.
  - Allows quick verification that the Lambda and API wiring is working.

---

### 3.9 `apigw/`  API Gateway

Exposes a REST API entry point:

- Defines a REST API in `us-west-2`.
- Configures a `/health` endpoint using Lambda proxy integration with the health Lambda.

Outputs:

- REST API ID/ARN.
- Stage name.
- Invoke URL (base URL for the API).

This provides a starting point for:

- Operational health checks.
- Later expansion (for example, `/events`, `/threats` for Dev Cs backend).

---

## 4. Terraform Workflow

### 4.1 Dev Environment (`infra/envs/dev`)

Path: `infra/envs/dev`

Typical workflow:

1. Change into the dev env directory:

   - `cd infra/envs/dev`

2. Initialize the backend and providers:

   - `terraform init`

3. Validate the configuration:

   - `terraform validate`

4. Review the planned changes:

   - `terraform plan`

5. Apply the changes (dev only):

   - `terraform apply`

Note: Dev has already been applied; re-running `terraform apply` should normally show no changes unless new infra has been added.

---

### 4.2 Prod Environment (`infra/envs/prod`)

Path: `infra/envs/prod`

Workflow is similar:

1. Change into the prod env directory:

   - `cd infra/envs/prod`

2. Initialize:

   - `terraform init`

3. Validate:

   - `terraform validate`

4. Plan:

   - `terraform plan`

Important: As of Phase 2.13, **prod has not been applied yet**.  
Any `terraform apply` in prod should be a deliberate decision after validating costs and architecture with the team.

---

## 5. AWS Credentials, Region, and Profiles

Key variables:

- `aws_region`  The AWS region for resources (currently `us-west-2`).
- `aws_profile`  The named AWS CLI profile Terraform should use.

Where they are defined:

- `variables.tf`  Declares `aws_region` and `aws_profile`.
- `terraform.tfvars`  Sets environment-specific values.

Example (dev):

- `aws_region  = "us-west-2"`
- `aws_profile = "honeybadgers-dev"`

To use the correct profile locally, ensure your AWS CLI configuration defines a matching profile.

---

## 6. Cost & Safety Notes

- **Logging Volume**

  - VPC Flow Logs and CloudWatch Logs can generate a meaningful amount of data over time.
  - Retention is configured (for example, 90 days in dev) to control costs.
  - For long-term storage, S3 lifecycle rules help manage costs (transition to cheaper storage classes).

- **Dev vs Prod**

  - **Dev** is the active playground. Infrastructure has already been applied and can be used for testing.
  - **Prod** mirrors the structure but is currently a skeleton only; it has not been applied.
  - Before applying prod, confirm:

    - AWS account and billing owner.
    - Logging retention periods appropriate for production.
    - Any GuardDuty or other security services (managed by Dev E) are in place.

- **Turning Things Off**

  - If cost becomes a concern during development:

    - Avoid applying new changes in prod.
    - Temporarily disable high-frequency scheduled tasks (for example, WAF automation schedule) by adjusting the schedule expression or commenting out the resource in dev.
    - As a last resort, `terraform destroy` in dev is possible, but should be coordinated so other team members do not lose dependent resources.

---

## 7. How Other Dev Roles Use This Infra

- **Dev B (Honeypot Engineer)**

  - Deploy honeypot EC2 instances into the dev VPC public subnets.
  - Send honeypot logs to the existing CloudWatch Log Groups defined by Dev A.
  - Rely on the ThreatIntel table and WAF IPSet created here.

- **Dev C (Backend & Automation)**

  - Extend Lambda functions (parser, WAF automation) and add new ones.
  - Add API Gateway resources and methods (for example, `/events`, `/threats`).
  - Use outputs from `infra/envs/dev/outputs.tf` (table names, ARNs, API IDs).

- **Dev D (Frontend / Dashboard)**

  - Consume the API Gateway invoke URL from outputs.
  - Use ThreatIntel-related endpoints (once exposed) to populate the dashboard.

- **Dev E (Security & Compliance)**

  - Build on top of the logging, WAF, and IAM structure to map controls to ISO 27001.
  - Use log retention plus S3 and CloudWatch outputs for compliance documentation.

This document should give any team member enough context to understand what the Terraform stack provides and how to safely interact with the dev/prod environments without digging through every `.tf` file.