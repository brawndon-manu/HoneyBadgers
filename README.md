# HoneyBadgers

## CPSC CSUF 454 Cloud Security

### Project Description – Honeypot Deployment Foundation

The Honeypot Deployment Foundation project establishes a secure, cloud-based honeynet environment designed to detect, capture, and analyze real-world cyberattacks in AWS. The solution integrates multiple components: infrastructure automation (VPCs, IAM, logging, Terraform), a Cowrie SSH/Telnet honeypot for attacker engagement, automated log parsing with AWS Lambda and DynamoDB for threat intelligence storage, real-time defensive actions through AWS WAF, and a React-based web dashboard for monitoring attacker activity and managing responses. Security and compliance are addressed through GuardDuty, CloudWatch alarms, and ISO 27001–aligned logging and retention policies. Together, these deliverables provide a robust and scalable platform that not only attracts attackers but also automates detection, defense, and reporting, serving as both a research tool and a practical cloud security defense system

---

# Honeypot Deployment

Secure, AWS-based honeynet with Cowrie (SSH/Telnet), automated log parsing (Lambda → DynamoDB), real-time blocking (WAF), and a React dashboard. Infra is Terraform.

## Repo layout (what lives where)

```
honeypot-foundation/
├─ infra/                 # Terraform: builds AWS pieces
│  ├─ modules/            # Reusable modules
│  │  ├─ vpc/             # VPC, subnets, routes, NAT/IGW
│  │  ├─ s3_logs/         # S3 log bucket(s), lifecycle, encryption
│  │  ├─ iam/             # Roles/policies for EC2/Lambda/API
│  │  ├─ cw/              # CloudWatch Log Groups (+ Flow Logs opt.)
│  │  ├─ waf/             # WAFv2 WebACL + IPSet
│  │  ├─ dynamodb/        # ThreatIntel table (TTL + GSI)
│  │  ├─ apigw/           # HTTP API skeleton (for /events, /threats)
│  │  ├─ lambda_parser/   # Parser Lambda (zip+env+function)
│  │  └─ lambda_waf_automation/ # WAF automation Lambda
│  └─ envs/
│     ├─ dev/             # “Glue” for dev env (instantiates modules)
│     └─ prod/            # Same for prod with different vars/state
│
├─ honeypot/              # EC2 Cowrie host bits
│  ├─ userdata/           # First-boot script (installs & starts Cowrie)
│  ├─ configs/            # cowrie.cfg, cloudwatch-agent.json, etc.
│  └─ hardening/          # egress control example
│
├─ lambdas/               # Lambda source (Python)
│  ├─ parser/             # CW Logs → parse → DynamoDB
│  └─ waf_automation/     # Update WAF IPSet (block/unblock, TTL)
│
├─ api/                   # (Optional) OpenAPI contract
│  └─ openapi.yaml
│
├─ frontend/              # React (Vite) dashboard
│  └─ src/ (App.jsx, components/, services/api.js)
│
└─ docs/                  # Policies, runbooks, IR playbook
   ├─ logging-monitoring-policy.md  # what's logged, who reviews, cadence, evidence
```

---

## Prereqs

- Terraform ≥ 1.6
- AWS CLI configured (an admin/sandbox account)
- Node ≥ 18 (for frontend)
- Python 3.11 (if you run Lambdas locally; not required for deploy)

---

## One-time setup

1. **Fill dev variables**

Open: `infra/envs/dev/terraform.tfvars` and set:

```hcl
project            = "honeypot-foundation"
region             = "us-west-2"
vpc_cidr           = "10.20.0.0/16"
public_subnets     = ["10.20.1.0/24","10.20.2.0/24"]
private_subnets    = ["10.20.101.0/24","10.20.102.0/24"]
azs                = ["us-west-2a","us-west-2b"]
log_retention_days = 90
dynamodb_table_name= "ThreatIntel"
waf_scope          = "REGIONAL"
```

2. **(Optional) Remote state**
   Edit `infra/envs/dev/backend.tf` with your state bucket/DDB lock.

---

## Deploy infra (dev)

**Where to type:** your terminal.

```bash
cd honeypot-foundation/infra/envs/dev
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

What you get: VPC, S3 log bucket, CloudWatch log groups, DynamoDB (ThreatIntel), WAF (WebACL+IPSet), API shell, IAM roles, GuardDuty, basic alarms, and both Lambda _functions_ created from your code stubs.

> Note: The EC2 honeypot instance is **not** created by these base modules. You can:
>
> - Launch it by hand (fastest) and paste the UserData, or
> - Add a tiny `ec2_honeypot` module later. For speed, do it by hand now.

---

## Launch the honeypot EC2 (quick path)

**Where to click:** AWS Console → EC2 → Launch instance

- AMI: Amazon Linux 2
- Instance profile/role: one that allows CloudWatch logs (use your IAM module’s EC2 role if you have it; otherwise create a simple one now)
- Network: put it in **public subnet** (from your VPC) + public IP
- Security group: inbound 22 & 23 (for Cowrie), and 22 for your admin IP if needed
- **User data:** paste `honeypot/userdata/cowrie-amzn2.sh` (the stub installs Cowrie + CloudWatch Agent)

After boot:

- Confirm logs flow into CW log groups `/honeypot/cowrie` and `/honeypot/system`.

---

## Wire parser subscription (when ready)

Once you see Cowrie logs in `/honeypot/cowrie`, create a **CloudWatch Logs subscription filter** to send that log group to the **parser Lambda** (your Terraform can manage this later; for MVP you can add it in the console). The stub parser just writes a sample item to DynamoDB so you can test end-to-end.

---

## Frontend (local dev)

**Where to type:**

```bash
cd honeypot-foundation/frontend
npm i
npm run dev
```

Set your API base URL in `frontend/src/services/api.js` (or use `VITE_API_URL` env and read it in `api.js`). The stubs return mock data so the UI renders without the backend.

Build for static hosting later:

```bash
npm run build
```

Outputs to `frontend/dist/` (you’ll host this via S3 + CloudFront in Terraform in a later pass).

---

## Common next steps (after stubs)

- **Parser Lambda**: decode CW subscription payload (base64+gzip), parse Cowrie JSON (`eventid`, `src_ip`, `dst_port`, `username`, `password`), upsert to DynamoDB; add partition-key design you want (we use `ip`) and a GSI on `last_seen`.
- **WAF automation**: implement `get_ip_set` → `update_ip_set` with lock token, add `/threats/block?ip=x.x.x.x` handler (API integration) and/or EventBridge schedule to auto-block top scorers.
- **API Gateway**: add two GET routes: `/threats`, `/events` (proxy to a tiny read Lambda or DynamoDB direct via Lambda).
- **Frontend**: point `services/api.js` to API URL; wire **Block** button to the `/threats/block` endpoint.
- **EC2 hardening**: apply `honeypot/hardening/egress-iptables.sh` (or VPC endpoints) to restrict outbound.
- **CloudFront/S3**: add a small module to host `frontend/dist/` with logs + OAC; (optionally) attach WAF WebACL there.

---

## Verify it works (MVP checklist)

- [ ] Hitting the honeypot’s public IP on 22/23 generates Cowrie logs in CW.
- [ ] Parser Lambda is invoked (via subscription) and rows appear in DynamoDB `ThreatIntel`.
- [ ] Frontend renders a table/feed (stub or real data).
- [ ] WAF IPSet exists; WAF Lambda can read it; manual update test succeeds.
- [ ] Alarms show OK; GuardDuty enabled.

---

## Clean up

**Where to type:**

```bash
cd honeypot-foundation/infra/envs/dev
terraform destroy
```

(Manually terminate any EC2 you launched by hand.)

---

## Docs to keep up-to-date

- `docs/logging-monitoring-policy.md` — what’s logged, who reviews, cadence, evidence.
- `docs/retention-policy.md` — 90-day hot, 1-year cold (or your targets).
- `docs/incident-response-playbook.md` — detection → WAF contain → recovery.
- `docs/runbook.md` — deploy steps, rotate keys, restore, replay logs.

---
