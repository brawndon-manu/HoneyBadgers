import json
import os


def lambda_handler(event, context):
    """
    Stub WAF automation Lambda.

    For now this just logs the incoming event and returns a basic JSON response.
    The real logic (reading ThreatIntel + updating WAF IPSet) will be added later.
    """
    print("Received event:", json.dumps(event))

    # Environment variables we wired via Terraform (not yet used here)
    table_name = os.getenv("THREATINTEL_TABLE")
    waf_ipset_id = os.getenv("WAF_IPSET_ID")
    waf_ipset_arn = os.getenv("WAF_IPSET_ARN")

    print("Config:", {
        "THREATINTEL_TABLE": table_name,
        "WAF_IPSET_ID": waf_ipset_id,
        "WAF_IPSET_ARN": waf_ipset_arn,
    })

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "WAF automation stub invoked",
            "table": table_name,
            "waf_ipset_id": waf_ipset_id,
            "waf_ipset_arn": waf_ipset_arn,
        }),
    }
