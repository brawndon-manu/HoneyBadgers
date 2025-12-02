import json
import base64
import gzip
import os
import time 
import datetime
import boto3

ddb = boto3.resource("dynamodb")
THREATINTEL_TABLE = os.environ.get("THREATINTEL_TABLE")

def lambda_handler(event, context):
    """
    Basic parser Lambda for HoneyBadgers dev:
    - Accepts CloudWatch Logs subscription events
    - Decompresses CloudWatch Logs payload (if present)
    - Logs the raw log lines for now
    """
    try:
        awslogs = event.get("awslogs", {})
        data = awslogs.get("data")
        if not data:
            print("No awslogs.data found in event")
            return {
                "statusCode": 200,
                "body": json.dumps({"ok": True})
            }

        decompressed = gzip.decompress(base64.b64decode(data))
        payload = json.loads(decompressed.decode("utf-8"))
        print("Decoded CloudWatch payload:", payload)

        log_events =  payload.get("logEvents", [])
        print(f"Processing {len(log_events)} log events")

        table = ddb.Table(THREATINTEL_TABLE)
        now_unix = int(time.time())

        for le in log_events:
            msg = le.get("message", "")
            ts_ms = le.get("timestamp", int(time.time() * 1000))

            record = parse_log_message(msg, ts_ms)
            if not record:
                continue

            ip = record["ip"]
            ts = record["timestamp"]
            score_delta = record["score"]

            table.update_item(
                Key={"ip": ip},
                UpdateExpression="""
                    SET first_seen = if_not_exists(first_seen, :ts),
                    last_seen = :ts,
                    count = if_not_exists(count, :zero) + :one,
                    score = if_not_exists(score, :zero) + :score,
                    block_status = if_not_exists(block_status, :none),
                    ttl = :ttl
                """,
                ExpressionAttributeValues={
                    ":ts": ts,
                    ":zero": 0,
                    ":one": 1,
                    ":score": score_delta,
                    ":none": "NONE",
                    ":ttl": now_unix + 7 * 24 * 3600,
                },
            )

    except Exception as e:
        print(f"Error processing log event: {e}")
    
    return {
        "statusCode": 200,
        "body": json.dumps({"ok": True})
    }

def parse_log_message(message: str, ts_ms: int) -> dict | None:
    """
    Parse a single Cowrie log line (JSON or text) into a normalized record:
    {
        ip, event_type, timestamp, score    
    }
    Return None if it can't find an IP.
    """
    try:
        data = json.loads(message)
    except json.JSONDecodeError:
        print(f"Skipping non-JSON message: {message}")
        return None
    
    ip = data.get("src_ip") or data.get("ip")
    if not ip:
        return None
    
    event_type = data.get("eventid", "unknown")

    ts_iso = datetime.datetime.utcfromtimestamp(ts_ms / 1000).isoformat() + "Z" 

    return {
        "ip": ip,
        "event_type": event_type,
        "timestamp": ts_iso,
        "score": score_event(event_type),
    }

def score_event(event_type: str) -> int:
    """
    Simple scoring function for now.
    Can be updated to include credentials, frequency & ports
    """
    if event_type == "cowrie.login.failed":
        return 10
    if event_type == "cowrie.login.success":
        return 30
    return 3