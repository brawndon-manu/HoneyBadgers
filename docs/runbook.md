# Operations Runbook (ISO 2001-Aligned)
**Author:** Dev E - Security & Compliance
**Version:** 1.0
**Date:** 2025-12-02

---

## 1. Purpose
This runbook provides standardized, ISO 27001-aligned operational procedures for maintaining, verifying, and restoring normal function access across the system.

Supports:
- routine monitoring
- operational reliability
- system health checks
- quick recovery from failures
- consistent documentation

---

## 2. Scope 
Covers operational tasks for:
- Cowrie Honeypot EC2
- CloudWatch Logs & Metrics
- Parser Lambda
- WAF Automation Lambda
- DynamoDB ThreatIntel
- GuardDuty
- API Gateway (if enabled)

---

## 3. Roles

### **Dev E - Security & Compliance (Primary Owner)**
- Performs daily/weekly checks
- Documents operational issues
- Coordinates remediation with team

### **Dev A - Infrastructure / DevOps**
- Fixes IAM, network, logging infrastructure
- Ensures WAF and CloudWatch stability

### **Dev B - Honeypot Engineer**
- Maintains honeypot instance
- Fixes Cowrie, CloudWatch agent, EC2 issues

### **Dev C - Backend & Automation (Lambdas)**
- Repairs parser and WAF automation Lambdas
- Ensures proper data flow in DynamoDB

### **Dev D - Frontend**
- Verifies UI updates after backend recovery
- Ensures dashboards reflect correct system state

---

## 4. Routine Operational Procedures

---

### **4.1 Daily Monitoring Procedure (Detection)**
- [ ] Check CloudWatch log group `/honeypot/events` for new entries
- [ ] Verify Parser Lambda shows:
    - successful invocations
    - zero recent errors
- [ ] Review GuardDuty findings
- [ ] Verify DynamoDB ThreatIntel shows new threat records
- [ ] Confirm WAF IPSet is updating (if automation enabled)

---

### **4.2 Weekly System Health Review (Assessment)**
- [ ] Review all CloudWatch alarms for:
    - EC2
    - Lambdas
    - DynamoDB
    - WAF
- [ ] Inspect S3 log archive for correct lifestyle storage
- [ ] Validate IAM policies haven't drifted
- [ ] Spot-check API (if active)
- [ ] Export one sample set of logs for correctness

---

## 5. Operational Tasks (Action)

---

### **5.1 Verify Honeypot Logging**
1. Navigate: CloudWatch -> Log Groups
2. Open `/honeypot/events`
3. Confirm:
    - consistent incoming events
    - no parsing errors
    - timestamps updating normally

---

### **5.2 Verify Parser Lambda**
1. Navigate: CloudWatch -> Metrics -> Lambda Parser
2. Confirm: 
    - invocations > 0
    - errors = 0
3. CloudWatch Logs -> verify no decode/JSON errors
4. DynamoDB ThreatIntel -> confirm new entries

---

### **5.3 Verify WAF Automation**
1. Navigate: Lambda -> `waf_automation` -> Recent logs
2. Check:
    - successful IPSet updates
    - no lock token errors
3. WAF -> IPSet:
    - verify malicious IPs appear
4. If automation stalled -> run Lambda manually

---

### **5.4 Check DynamoDB ThreatIntel**
1. Navigate: DynamoDB -> ThreatIntel
2. Check:
    - new IPs
    - updated `last_seen`
    - correct TTL
    - valid attack data

---

### **5.5 Check GuardDuty**
1. Navigate: GuardDuty -> Findings
2. Review:
    - Recon / Port scanning
    - SSH brute force
    - Malicious IP caller
3. Document anything above "Low" severity

---

## 6. Recovery Procedures (Resolution)

---

### **6.1 Restore Honeypot EC2**
- Restart services:
    ```
    sudo systemctl restart cowrie
    sudo systemctl restart amazon-cloudwatch-agent
    ```
- Validate log flow
- If broken -> terminate and redeploy using userdata script

---

### **6.2 Restore Parser Lambda**
- Fix code or permissions
- Recreate CloudWatch supscription filter
- Test with sample log event
- Confirm DynamoDB updates resume

---

### **6.3 Restore WAF Automation Lambda**
- Fix lock token/IPSet update logic
- Correct IAM permissions
- Manually block IPs if needed
- Validate automatic updates resume

---

## 7. Recordkeeping (Lessons Learned)
After each operational failure or anomoly,
- Document the following in the runbook incident log:
    ```
    ### Incident: <ID>
    **Date:**
    **Category:** (Honeypot / Parser / Automation / WAF / Infra)
    **Summary:**
    **Root Cause:**
    **Actions Taken:**
    **Resolution Time:**
    **Prevention / Follow-Up:**
    ```

Store evidence in: `docs/evidence/<date>/`

---

## 8. Review Cycle
This runbook must be reviewed:
- every 90 days
- after any significant operational incident
- when infrastructure or Lambdas change
- when project components are added or removed

---