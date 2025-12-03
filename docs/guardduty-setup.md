# GuardDuty Setup & Verification
**Author:** Dev E - Security & Compliance
**Version:** 1.0
**Date:** 2025-12-02

---

## 1. Purpose
This document verifies that Amazon GuardDuty has been successfully enabled for continuous threat detection within the system environment. GuardDity provides anomaly detection, malicious activity monitoring, and AWS account threat visibility.

---

## 2. Region & Environment
GuardDuty was enabled in the following environment:
- **Account:** myurt.dev
- **Environment:** dev
- **Region:** us-west-2

---

## 3. Enablement status
GuardDuty **successfully enabled** in the dev environment.

### Evidence (screenshots):
1. **GuardDuty Dashboard (Enabled State)**
    - Shows service activation and detector ID
2. **Findings Page**
    - Displays current findings
    - If empty, indicates no threats detected yet
    - Confirms service is active

> Screenshots attached in the repository folder: `docs/screenshots/guardduty/`

---

## 4. Detector Configuration Summary
GuardDuty automatically created a detector with the following settings:
- Monitoring: Enabled
- Data sources: 
    - VPC Flow Logs
    - CloudTrail Events
    - DNS logs
- Multi-account: not required for this project
- No custom threat lists required (optional)

---

## 5. Relationship to Project Components

GuardDuty findings directly support:

### **Honeypot Threat Detection**
- Identifies repeated attacker behavior
- Detects malicious IPs interacting with Cowrie
- Flags recon, SSH brute force, credential stuffing

### **Incident Response**
- Used in the IR Playbook for threat identification
- Helps determine severity of malicious IP events
- Supports post-incident review evidence

---

## 6. Review Cadence (ISO 27001 A.12 Alignment)
GuardDuty must be reviewed:
- **Daily:** Check for new findings
- **Weekly:** Review severity and patterns
- **After any honeypot incident**
- **Every 90 days:** Validate configuration and region settings

All findings above "Low" severity must be documented in the IR incident log.

---

## 7. Notes
- GuardDuty findings will increase once Cowrie is deployed & publicly accessible.
- High or repeated malicious IP detetions should trigger WAF automation review.
- If GuardDuty fails or is disabled, **Dev A** must restore sevice immediately.

---

## 8. Conclusion
GuardDuty is fully active and inttegrated as a core threat-detection component of the Honeypot System.
Screenshots included serve as verification for project requirements and compliance documentation.