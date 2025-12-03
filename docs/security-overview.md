# HoneyBadgers Security & Compliance Overview (Dev E)

---

## 1. Purpose & Scope
This document summarizes the Security & Compliance components of the HoneyBadgers honeypot environment.

**Objective:** Define the monitoring, logging, retention, threat detection, and incident response controls required to maintain a secure, ISO-aligned deployment across AWS.

Dev E focuses on:
- Logging and monitoring requirements (CloudWatch, DynamoDB, GuardDuty)
- Retention and lifecycle management (CloudWatch -> S3)
- Incident response processes for all attack and failure scenarios
- Operational runbooks for daily/weekly/monthly reviews
- CloudWatch alarm definitions 
- GuardDuty enablement and evidence documentation
- ISO 27001-style compliance alignment for the security portions of the project

These controls support the overall objective: capturing attacker activity safely while ensuring the platform remains monitored, recoverable, and compliant.

---

## 2. GuardDuty Configuration & Threat Protection

### 2.1 GuardDuty Setup
GuardDuty is enabled in the **dev environment (us-west-2)** and configured to monitor:
- VPC Flow Logs
- CloudTrail API activity
- DNS logs
- EC2 behavior anomolies
- Malicious IP interactions

Screenshots of the detector and findings page are stored in: `docs/screenshots/guardduty/`
- Documented in `docs/guardduty-setup.md`

### 2.2 How GuardDuty Supports the Platform
GuardDuty assists with:
- Detecting malicious IP callers
- SSH brute-force attempts
- Recon activity
- Unusual credential or API usage
- Providing evidence for IR procedures

GuardDuty findings directly feed into the Incident Response Playbook and daily system checks. 

---

## 3. Logging & Monitoring Requirements (IS0 27001 A.12 Alignment)
Defined in `logging-monitoring-policy.md` 

---

Policies specify required log sources:
- Honeypot event logs (`/honeypot/events`)
- Lambda logs (parser, WAF automation)
- VPC Flow logs
- DynamoDb access patterns
- WAF IPSet updates
- API Gateway execution logs (if applicable)
- GuardDuty findings

The policy establishes:
- Daily/weekly review cadence
- Access controls
- Monitoring ownership
- Evidence collection locations
- Required CloudWatch retention settings
- Log group naming consistency

---

## 4. Log Retention & Lifecycle Management
Defined in `retention-policy.md`

---

- **CloudWatch Logs:** retained for 90 days
- **S3 Cold Storage:** retained for 1 year (via lifecycle transition)
- **Versioning:** enabled for log integrity
- **Encryption:** SSE-S3 or SSE-KMS depending on service

Retention settings support ISO-compliant evidence storage while controlling cost.

---

## 5. Incident Response Playbook (ISO-style)
Documented in `incident-response-playbook.md`

---

ISO-style flow (Detection -> Assessment -> Action -> Resolution -> Lessons Learned) applied to:

### 5.1 Honeypot Compromise
EC2 anomaly, service failure, or outbound traffic spike.

### 5.2 Malicious IP Detection
High-volume attack traffic, repeated brute-force attempts, GuardDuty recon

### 5.3 Parser Lambda Failure
CloudWatch -> Lambda -> DynamoDB ingestion failure.

### 5.4 WAF Automation Failure
Blocked IPs not updating lock token issues, IAM permission failures.

---

Each procedure links to:
- Evidence to collect
- Team roles
- Required actions per scenario
- Post-incident documentation flow

---

## 6. Operations Runbook
Defined in `runbook.md`

---

Covers:
- Daily system checks (Cowrie logs, GuardDuty, Lambda metrics)
- Weekly audits (alarms, retention, S3 lifecycle)
- Recovery procedures:
    - Redeploying honeypot EC2
    - Repairing parser Lambda
    - FIxing WAF automation
- Evidence handling
- 90-day review cycle

This runbook ensures the system remains operational and that failures are handled consistently.

---

## 7. Alarm Definitions
- Documented in `cloudwatch-alarm.md`

Required alarms:
- **A1 - CowrieEventSpike:** Detect attacker spikes in honeypot activity via custom metric filter
- **A2 - ParserLambdaErrorsHigh:** Detect ingestion/parsing failure
- **A3 - WafAutomationErrorsHigh:** Detect WAF IPSet update failures
- **A4 - DynamoDbThreatIntelUsageAnom:** Detect abnormal read/write patterns for throttling

Alarms notify via `honeypot-alerts` or `honeypot-ops` for A4.

---

## 8. Compliance Alignment & Review
Security controls align with ISO 27001:
- A.12 (Logging & Monitoring)
- A.16 (Incident Response)
- A.8 (Asset Management - Evidence & Log Retention)

Review cycles:
- Daily -> operational checks
- Weekly -> alarm + log inspection
- Quarterly (90 days) -> policy review and improvements
- After incidents -> automatic IR and runbook updates

This ensures the security posture eveolves with system changes and attack patterns.

---

## 9. Summary
Dev E responsibilities are fully completed:
- GuardDuty enabled
- Logging policy
- Retention policy
- Incident Response Playbook
- Operations Runbook
- CloudWatch alarm definitions
- Security documentation suite aligned with ISO controls

These deliverables complete the 'Security & Compliance' foundation for the HoneyBadgers environment and support the work done by Dev A, B, C, and D.

---

