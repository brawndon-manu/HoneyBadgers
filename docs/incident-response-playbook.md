# Incident Response Playbook
**Author:** Dev E - Security & Compliance
**Version:** 1.0 (ISO-aligned)
**Date:** 2025-12-01

---

## 1. Purpose
This playbook defines standardized, ISO 27001–aligned procedures for detecting, assessing, and responding to security and operational incidents across the system.

Ensures:
- consistent handling of events
- quick containment of threats
- minimal system disruption
- clear documentation for audits and compliance

### This playbook defines the required response steps when:
1. The Cowrie honeypot is compromised or behaves unexpectedly.
2. Malicious IP activity is detected through logs, GuardDuty, or DynamoDB threat scoring.
3. AWS Parser Lambda fails to update to the DynamoDB ThreatIntel table.
3. AWS WAF automation fails to block known attacker IPs.

---

## 2. Scope
This playbook applies to all components involved in threat detection and automation:
- Cowrie Honeypot EC2
- Parser Lambda
- WAF Automation Lambda
- CloudWatch Logs & Alarms
- GuardDuty
- DynamoDB ThreatIntel Table
- WAF IPSet 
- API Gateway (if active)

---

## 3. Roles & Responsibility

### **Dev A - Infrastructure / DevOps**
- Contains network threats (SG, IAM, WAF)
- CloudWatch alarms troubleshooting

### **Dev B - Honeypot Engineer (Cowrie EC2)**
- Investigates EC2 behavior
- Rebuilds or repairs honeypot system

### **Dev C - Backend & Automation (Lambdas)**
- Fixes: 
    - parser failures
    - WAF automation issues
- Verifies integrations

### **Dev E - Security & Compliance**
- Review alerts and logs
- Confirms incident severity
- Documents all incidents
- Coordinates with other developers (Dev A/B/C)

---

# 4. Incident Types & Response Procedures

---

## **4.1 Honeypot Compromise or Abnormal EC2 Behavior**
*(Most severe incident type - attacker may have tampered with the honeypot environment)*

### **Detection**
- No logs in `/honeypot/events` for > 5 minutes 
- **CloudWatch alarm:** "Cowrie Ingestion Failure"
- **GuardDuty** findings:
    - SSH brute force: "UnauthorizedAccess:EC2/SSHBruteForce"
    - priviledge escalation: "Recon:PortScan"
    - crypto mining indicators: "CryptoCurrency:EC2"
- High outbound traffic from EC2

### **Assessment**
- Determine if honeypot is:
    - unresponsive
    - altered
    - producing corrupted logs
- Check if attacker gained shell access
- Evaluate whether compromise could affect automation pipeline

### **Action**
**Dev A** isolates EC2:
- Remove all outbound egress rules
    - Restrict inbound to *Dev B admin IP only*
    - (Opt) Detach instance from public subnet
- Disable SSH from the public
- Take EC2 snapshot (if evidence needed)
**Dev B** inspects instance:
- Restart:
    - Cowrie
    - CloudWatch Agent
- Identify rogue processes
    - Remove unauthorized binaries/files (if discovered)
    - Reinstall Cowrie (if needed)
- Check system logs

- Restore proper inbound/outbound rules

**If severe:** prepare for full redeployment using userdata script

### **Resolution**
- EC2 functioning normally
- Logs consistently flowing back -> CloudWatch
- Parser Lambda receiving normal events
- No unexpected outbound connections

### **Lessons Learned**
- Update hardening scripts
- Improve SG restrictions and IAM policies
- Add new alarms if detection was late
- Document findings in runbook incident log: `/docs/runbook.md`

---

## **4.2 Malicious IP Detected (Threat Intelligence Event)**
*(Normal but high-priority event - attacker actively interacting with honeypot system)*

### **Detection**
- Repeated Cowrie login attempts
- Parse Lambda shows high-frequency events from same IP
- DynamoDB "ThreatIntel" table score > threshold
- GuardDuty "Recon" or "Malicious IP" finding
- **CloudWatch alarm:** unusual honeypot activity

### **Assessment**
- Determine the severity:
    - sustained brute force
    - high-volume automated scanning
    - credential stuffing attempts
- Confirm IP is external attacker, not internal testing

### **Action**
- Trigger WAF automation Lambda *or* manually add IP to WAF IPSet
- Validate correct CIDR formatting
- Update IP metadata in DynamoDB

### **Resolution**
- IP successfully blocked
- No further attempts recorded from that source
- ThreatIntel table updated with block status
- Frontend dashboard reflects blocked IP

### **Lessons Learned**
- Adjust score thresholds if needed
- Identify new attacker patterns

---

## **4.3 Parser Lambda Failure (Operational Incident)**
*(A pipeline failure - threat intelligence stops updating)*

### **Detection**
- **CloudWatch alarm:** "Parser Lambda Errors > 0"
- No new items in DynamoDB ThreatIntel table
- Logs show:
    - base64 decode errors
    - gzip errors
    - missing IAM permissions
    - malformed Cowrie JSON

## **Assessment**
Determine whether failure is:
- temporary (bad log event)
- code issue
- IAM misconfiguration
- CloudWatch subscription issue

Check impact:
- Is data delayed?
- Is automation blocked?

### **Action**
**Dev C** examines logs
- Fixes:
    - JSON parsing logic
    - base64/gzip decoding
    - DynamoDB PutItem permissions
- Repair or recreate CloudWatch -> Lambda subscription filter

### **Resolution**
- Parser Lambda executes without errors
- DynamoDB shows new threat entries
- WAF automation receives correct data again

### **Lessons Learned**
- Improve error handling in Lambda
- Add additional CloudWatch alarms if failure went unnoticed

---

## **4.4 WAF Automation Failure (Operational Incident)**
*(System fails to automatically block high-risk IPs)*

### **Detection**
- **CloudWatch alarm:** "WAF Automation Lambda Errors > 0"
- IP remains unblocked despite high threat score
- Repeated GuardDuty finding from same attacker
- Lambda logs show:
    - UpdateIPSet permission errors
    - lock token errors
    - incorrect IP value formatting

### **Assessment**
- Determine if automation failed due to:
    - IAM policy misconfiguration
    - invalid IPSet ARN
    - parsing error
    - missing lock token
- Check if manual blocking is needed

### **Action**
- **Dev C** fixes automation Lambda logic
    - correct IPSet ARN in env variables
    - lock token is handled properly
- **Dev A** updates IAM role permissions
- Manually block the IP in WAF if attacker still active
- Re-run WAF automation with corrected config

### **Resolution**
- IPSet updates successfully
- Automation Lambda runs without errors
- Threat is mitigated

### **Lessons Learned**
- Enhance validation for IP formats
- Add test harness for WAF automation
- Improve IAM least-privilege review

---

# 5. Evidence Collection
For any incident, collect evdence required for audits or post-incident review:
- CloudWatch logs (export JSON)
- GuardDuty findings
- DynamoDB entries for affected IPs
- WAF IPSet change logs
- EC2 logs (if honeypot affected)

Store under: `docs/evidence/<date>/`

---

# 6. Review Cycle
This playbook must be reviewed:
- every 90 days
- after any major incident
- when new components or IAM policies are added
- when threat patterns change
