# Logging & Monitoring Policy
**Author:** Dev E - Security & Compliance
**Version:** 1.0
**Date:** 2025-11-30

---

## 1. Purpose
This policy defines how logs are collected, retained, monitored, and protected across the system. 
It aligns with ISO/IEC 27001 Annex A.12 (Operations Security).

---

## 2. Scope
Applies to all project components, which includes:
- Cowrie Honeypot EC2 instance
- Parser Lambda function
- WAF Automation Lambda
- DynamoDB tables (ThreatIntel, blocked_ips)
- API Gateway (if applicable)
- CloudWatch Logs & Metrics
- EventBridge scheduled events

---

## 3. Log Sources & Requirements

### **3.1 Cowrie Honeypot Logs**
via CloudWatch Agent:
- authentication attempts
- command execution attempts
- connection details (IP, port, protocol)
- session transcripts

**Requirement:**
All honeypot logs must stream to **CloudWatch Logs** in the `honeypot/events` log group.

### **3.2 Parser Lambda Logs**
from Lambda runtime:
- invocation events
- parsing errors
- DynamoDB write failures
- malformed CloudWatch subscription messages

Log group: `/aws/lambda/parser`

### **3.3 WAF Automation Lambda Logs**
- IPSet update attempts
- DynamoDB query results
- errrors or throttles

Log group: `/aws/lambda/waf_automation`

### **3.4 DynamoDB Metrics**
via CloudWatch Metrics:
- ReadCapacityUnits / WriteCapacityUnits
- ThrottledRequests
- ConsumedThroughput
- Errors (5xx, ConditionalCheckFailed, etc. )

### **3.5 API Gateway Logs (if enabled)**
Captures:
- request logs
- error logs
- latency metrics
- rejected IPs / blocked requests

Log group: `API-Gateway-Execution-Logs`

---

## 4. Log Retention Policy

### **4.1 Hot Storage (CloudWatch)**
- **90 days** retention for actionable logs:
    - honeypot events
    - Lambda Errors
    - API Gateway access logs
    - DynamoDB metrics

### **4.2 Cold Storage (S3)**
Logs older than 90 days must be shipped to S3 for long-term retention
- **Retention in S3:** 1 year
S3 bucket must:
- enable default encryption (AES-256 orr KMS)
- block public access
- enable lifecycle policy to delete after retention period

---

## 5. Monitoring & Alerting Strategy

### **5.1 Cowrie Activity Alerts**
- sudden spike in honeypot events
- repeated login attempts
- large increases in session connections

### **5.2 Lambda Error Alerts**
- parser lambda failing to parse messages
- waf_automation lambbda failing to update the IPSet
- lambda invocation errors > 0 within 5 minutes

### **5.3 DynamoDB Alerts**
- unexpected throttling
- read/write usage spikes
- incrreased 5xx errors

### **5.4 GuardDuty Alerts**
When enabled:
- reconnaissance events
- credential compromise attempts
- detected malicious IPs

These alerts must be reviewed within 24 hours.

---

## 6. Access Control for Logs
Only authorized project roles may access logs:
- Dev A: Infrastructure
- Dev C: Backend
- Dev E: Compliance & Monitoring

IAM policies MUST enforce:
- least privilege
- MFA for console access
- no direct S3 public access

---

## 7. Resonsibilities

### **Dev A**
- ensure CloudWatch log groups exist
- configure log retention policies
- ensure Lambda -> CloudWatch log permissions

### **Dev B**
- install CloudWatch Agent on EC2
- confirm log forwarding works

### **Dev C**
- log meaningful error messages
- handle malformed input gracefully

### **Dev E**
- maintain this policy
- verify log retention settings
- review alert definitions
- coordinate with team if suspicious activity occurs

---

## 8. Compliance requirements
This policy maps to: 
- **ISO 27001 A.12.4**: Logging and Monitoring
- **ISO 27001 A.12.1**: Operational Procedures
- **SOC2 CC7.2**: Monitoring Activities
- **AWS Well-Architectured**: Security Pillar

---

## 9. Review & Updates
This policy MUST be reviewed every 90 days or when:
- new services are added
- log sources change
- security incidents require updated controls
