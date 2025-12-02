import os
import json
import logging
import ipaddress

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables configured via Terraform
THREATINTEL_TABLE = os.getenv("THREATINTEL_TABLE")
WAF_IPSET_ID = os.getenv("WAF_IPSET_ID")
WAF_IPSET_ARN = os.getenv("WAF_IPSET_ARN")
ENV = os.getenv("ENV", "dev")
PROJECT = os.getenv("PROJECT", "HoneyBadgers")

# WAFv2 scope is REGIONAL for this project
WAF_SCOPE = "REGIONAL"


def parse_ipset_name_from_arn(ipset_arn: str) -> str:
    """
    WAFv2 IPSet ARN format (REGIONAL):
      arn:aws:wafv2:region:account-id:regional/ipset/name/id

    Only need the 'name' segment for GetIPSet/UpdateIPSet.
    """
    if not ipset_arn:
        raise ValueError("WAF_IPSET_ARN environment variable is not set")

    parts = ipset_arn.split("/")
    if len(parts) < 3:
        raise ValueError(f"Unexpected WAF IPSet ARN format: {ipset_arn}")

    # .../ipset/<name>/<id>
    return parts[-2]


def normalize_ip_to_cidr(ip: str) -> str | None:
    """
    Normalize an IP or CIDR string to WAF IPv4 CIDR format.

    - If plain IPv4 (e.g., 1.2.3.4), return "1.2.3.4/32".
    - If IPv4 CIDR already (e.g., 1.2.3.0/24), return as-is (normalized).
    - Invalid entries return None.
    """
    if not ip:
        return None

    ip = ip.strip()
    try:
        # strict=False lets ipaddress accept host addresses as /32 automatically
        network = ipaddress.ip_network(ip, strict=False)
        if isinstance(network, ipaddress.IPv4Network):
            return str(network)
        else:
            # For this project we only handle IPv4
            return None
    except ValueError:
        logger.warning("Skipping invalid IP/CIDR value from ThreatIntel: %s", ip)
        return None


def scan_threatintel_ips(table_name: str) -> set[str]:
    """
    Scan the ThreatIntel DynamoDB table and return a set of normalized IPv4 CIDRs
    that should be blocked. For this first iteration, we:

      - Include every item that has an 'ip' attribute.
      - Normalize to IPv4 CIDR (x.y.z.w/32 or existing CIDR).
      - Skip invalid IPs.

    NOTE: This uses a full table scan. should be good enough for this project
    """
    if not table_name:
        raise ValueError("THREATINTEL_TABLE environment variable is not set")

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    blocked_ips: set[str] = set()
    scan_kwargs = {}
    items_read = 0

    while True:
        resp = table.scan(**scan_kwargs)
        items = resp.get("Items", [])
        items_read += len(items)

        for item in items:
            ip_value = item.get("ip")
            cidr = normalize_ip_to_cidr(ip_value)
            if cidr:
                blocked_ips.add(cidr)

        last_evaluated_key = resp.get("LastEvaluatedKey")
        if not last_evaluated_key:
            break

        scan_kwargs["ExclusiveStartKey"] = last_evaluated_key

    logger.info(
        "ThreatIntel scan complete: %d items scanned, %d unique CIDRs derived",
        items_read,
        len(blocked_ips),
    )
    return blocked_ips


def get_waf_ipset(waf_client, scope: str, ipset_id: str, ipset_arn: str) -> tuple[str, list[str], str]:
    """
    Get the current WAFv2 IPSet addresses and lock token.

    Returns:
        (ipset_name, addresses, lock_token)
    """
    if not ipset_id:
        raise ValueError("WAF_IPSET_ID environment variable is not set")

    ipset_name = parse_ipset_name_from_arn(ipset_arn)

    try:
        resp = waf_client.get_ip_set(
            Scope=scope,
            Id=ipset_id,
            Name=ipset_name,
        )
    except ClientError as e:
        logger.error("Error calling GetIPSet: %s", e, exc_info=True)
        raise

    ipset = resp.get("IPSet", {})
    addresses = ipset.get("Addresses", [])
    lock_token = resp.get("LockToken")

    logger.info(
        "Fetched WAF IPSet '%s' (%s): %d existing addresses",
        ipset_name,
        ipset_id,
        len(addresses),
    )

    return ipset_name, addresses, lock_token


def update_waf_ipset(
    waf_client,
    scope: str,
    ipset_id: str,
    ipset_arn: str,
    desired_cidrs: set[str],
) -> dict:
    """
    Merge desired CIDRs from ThreatIntel with existing WAF IPSet addresses
    and call UpdateIPSet if there are changes.

    We choose a simple strategy for this first iteration:

      - Union of existing addresses and desired_cidrs.
      - If no change, we skip the UpdateIPSet call.

    Returns a summary dict with counts and whether an update occurred.
    """
    ipset_name, existing_addresses, lock_token = get_waf_ipset(
        waf_client=waf_client,
        scope=scope,
        ipset_id=ipset_id,
        ipset_arn=ipset_arn,
    )

    existing_set = set(existing_addresses)
    merged_set = existing_set.union(desired_cidrs)

    # WAF requires a sorted list of CIDRs
    new_addresses = sorted(merged_set)

    if new_addresses == existing_addresses:
        logger.info(
            "No WAF IPSet update needed: existing=%d, desired=%d, merged=%d (no change)",
            len(existing_addresses),
            len(desired_cidrs),
            len(new_addresses),
        )
        return {
            "updated": False,
            "existing_ipset_count": len(existing_addresses),
            "desired_cidrs_count": len(desired_cidrs),
            "final_ipset_count": len(new_addresses),
            "ipset_name": ipset_name,
        }

    try:
        waf_client.update_ip_set(
            Scope=scope,
            Id=ipset_id,
            Name=ipset_name,
            LockToken=lock_token,
            Addresses=new_addresses,
        )
    except ClientError as e:
        logger.error("Error calling UpdateIPSet: %s", e, exc_info=True)
        raise

    logger.info(
        "Updated WAF IPSet '%s' (%s): existing=%d, desired=%d, final=%d",
        ipset_name,
        ipset_id,
        len(existing_addresses),
        len(desired_cidrs),
        len(new_addresses),
    )

    return {
        "updated": True,
        "existing_ipset_count": len(existing_addresses),
        "desired_cidrs_count": len(desired_cidrs),
        "final_ipset_count": len(new_addresses),
        "ipset_name": ipset_name,
    }


def lambda_handler(event, context):
    """
    Scheduled WAF automation entrypoint.

    Steps:
      1. Scan DynamoDB ThreatIntel table for attacker IPs.
      2. Normalize to IPv4 CIDR format.
      3. Fetch existing WAFv2 IPSet addresses.
      4. Merge and update the IPSet if there are changes.
      5. Log a JSON summary and return it.
    """
    logger.info(
        "WAF automation Lambda triggered for project=%s env=%s; event=%s",
        PROJECT,
        ENV,
        json.dumps(event),
    )

    if not THREATINTEL_TABLE or not WAF_IPSET_ID or not WAF_IPSET_ARN:
        msg = "One or more required environment variables are missing (THREATINTEL_TABLE, WAF_IPSET_ID, WAF_IPSET_ARN)"
        logger.error(msg)
        return {
            "statusCode": 500,
            "body": json.dumps({"status": "error", "message": msg}),
        }

    waf_client = boto3.client("wafv2")

    try:
        # 1–2: Read and normalize IPs from ThreatIntel
        desired_cidrs = scan_threatintel_ips(THREATINTEL_TABLE)

        if not desired_cidrs:
            # Safety behavior: if ThreatIntel is empty, do NOT clear the IPSet.
            logger.info(
                "ThreatIntel table returned no valid IPs; skipping WAF IPSet update to avoid clearing existing blocks."
            )
            summary = {
                "updated": False,
                "existing_ipset_count": None,  # not fetched in this branch
                "desired_cidrs_count": 0,
                "final_ipset_count": None,
                "ipset_name": None,
            }
        else:
            # 3–4: Merge and update WAF IPSet
            summary = update_waf_ipset(
                waf_client=waf_client,
                scope=WAF_SCOPE,
                ipset_id=WAF_IPSET_ID,
                ipset_arn=WAF_IPSET_ARN,
                desired_cidrs=desired_cidrs,
            )

        result = {
            "status": "ok",
            "project": PROJECT,
            "env": ENV,
            "summary": summary,
        }
        logger.info("WAF automation Lambda completed: %s", json.dumps(result))
        return {
            "statusCode": 200,
            "body": json.dumps(result),
        }

    except Exception as e:
        logger.error("Unhandled exception in WAF automation Lambda: %s", e, exc_info=True)
        return {
            "statusCode": 500,
            "body": json.dumps(
                {
                    "status": "error",
                    "message": str(e),
                    "project": PROJECT,
                    "env": ENV,
                }
            ),
        }
