# CloudWatch Alarms - Definitions & Requrements
**Author:** Dev E - Security & Compliance
**Version:** 1.0
**Date:** 2025-12-03

---

## 1. Purpose
This document defines the CloudWatch alarms required to monitor the system.
These alarms support ISO 27001 monitoring objectives by enabling early detection of failures or abnormal activity.

Specifies:
- What must be monitored
- Why it matters
- How incidents should be handled

Implemenation of these alarms (via console or Terraform) is the responsibility of **Dev A - Infrastructure**.

---

## 2. Scope
Alarm definitions apply to:
- Cowrie Honeypot log ingestion (EC2 -> CloudWatch Logs)
- Parser Lambda
- WAF Automation Lambda
- DynamoDB ThreatIntel

They integrate with:
- Incident Response Playbook
- Logging & Monitoring Policy
- Retention Policy
- Runbook

---

## 3. Alarm Summary

| ID | Alarm Name                   | Target                | Purpose                                 | Severity |
|----|------------------------------|-----------------------|-----------------------------------------|----------|
| A1 | CowrieEventSpike.            | Cowrie log group      | Detect suddent spike in honeypot events | High     |
| A2 | ParserLambdaErrorsHigh.      | Parser Lambda         | Detect parsing/ingestion failures       | High     |
| A3 | WafAutomationErrorsHigh.     | WAF automation Lambda | Detect failures updating WAF IPSet      | High     |
| A4 | DynamoDbThreatIntelUsageAnom | DynamoDB ThreatIntel  | Detect unusual read/write usage         | Medium   |

---

## 4. Alarm Specifications

---

### **4.1 A1: CowrieEventSpike**
**Objective:** Detect aggressive brute-force attacks or automated scanning against the honeypot.

- **Resource:** CloudWatch Log Group -> `/honeypot/events`
- **Metric:**
    - Use a CloudWatch Logs metric filter to count events:
        - Filter pattern: `{ $.eventid = "*" }` (or specific Cowrie event fields)
    - Namespace: `Honeypot/Cowrie`
    - Name: `CowrieEventCount`
- **Suggested Threshold:** `CowrieEventCount > 500` over a 5-minute period
- **Severity:** High
- **Notification (SNS Topic):** `honeypot-alerts`
- **Response Reference:**
    - **Incident Response Playbook:** Malicious IP Detected
    - **Runbook:** Check GuardDuty

---

### **4.2 A2: ParserLambdaErrorsHigh**
**Objective:** Detect failures in the log ingestion pipeline (CloudWatch -> Parser Lambda -> DynamoDB)

- **Resource:** Lambda function `parser`
- **Metric:** 
    - Namespace: `AWS/Lambda`
    - Name: `Errors`
- **Suggested Threshold:** `Errors >= 1` over a 1-minute period
- **Severity:** High
- **Notification (SNS Topic):** `honeypot-alerts` 
- **Response Reference:**
    - **Incident Response Playbook:** Parser Lambda Failure
    - **Runbook:** Verify Parser Lambda 

**Note:** This alarm ensures parsing failures are detected quickly so ThreatIntel data does not silently stop updating.

---

### **4.3 A3: WafAutomationErrorsHigh**
**Objective:** Detect failures in the WAF automation Lambda that is responsible for updating the blocked IP list.

- **Resource:** Lambda function `waf_automation`
- **Metric:**
    - Namespace: `AWS/Lambda`
    - Name: `Errors`
- **Suggested Threshold:** `Errors >= 1` over a 5-minute period
- **Severity:** High
- **Notification (SNS Topic):** `honeypot-alerts` 
- **Response Reference:**
    - **Incident Response Playbook:** WAF Automation Failure
    - **Runbook:** Verify WAF Automation

**Note:** A persistent error here means malicious IPs might not be added to the WAF IPSet, reducing protection.

---

### **4.4 A4: DynamoDbThreatIntelUsageAnom**
**Objective:** Detect unusual DynamoDB usage that may indicate abuse, misconfiguration, or unexpected query patterns.

- **Resource:** DynamoDB table `ThreatIntel`
- **Metric:**
    - Namespace: `AWS/DynamoDB`
    - Names:
        - `ConsumedReadCapacityUnits`
        - `ConsumedWriteCapacityUnits`
        - `ThrottleRequests`
- **Suggested Threshold:** over a 5-minute period
    - Read & write:  > 3x normal baseline
    - Throttle: `ThrottleRequests > 0`
- **Severity:** Medium
- **Notification (SNS Topic):** `honeypot-ops` 
- **Response Reference:**
    - **Incident Response Playbook:** used as supporting evidence for larger incidents
    - **Runbook:** Check DynamoDB ThreatIntel

---

## 5. Roles & Resonsibilities
### **Dev E - Security & Compliance:**
- Defines alarm requirements
- Ensures thresholds match IR and monitoring policies
- Reviews alarm definitions every 90 days

### **Dev A - Infrastructure**
- Implements alarms in CloudWatch
- Creates metric filters for Cowrie log events
- Configures SNS notifications
- Validates alarms after deployment

### **Dev B - Honeypot Engineer**
- Confirms log volume patterns
- Helps validate Cowrie metric filter accuracy

### **Dev C - Automation**
- Helps tune thresholds for Lambdas
- Provides functional insights if alarms trigger

---

## 6. Review & Tuning
Alarm definitions must be reviewed:
- after any major incident (e.g., honeypot compromise, large attack)
- after honeypot deployment changes
- whenever log volume or Lambda behavior changes
- every 90 days via Logging & Monitoring Policy

Thresholds should be tuned over time based on observed traffic and findings.

---