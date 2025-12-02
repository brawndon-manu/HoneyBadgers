import os
import json
import boto3
import datetime

ddb = boto3.resource("dynamodb")
THREATINTEL_TABLE = os.environ["THREATINTEL_TABLE"]

def lambda_handler(event, context):
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")
    
    if path == "/threats" and method == "GET":
        return get_threats()
    if path == "/events" and method == "GET":
        return get_events()
    if path == "/threats/block" and method == "POST":
        return post_block(event)
    
    return {"statusCode": 404, "body": "Not found"}

def get_threats():
    table = ddb.Table(THREATINTEL_TABLE)
    resp = table.scan()
    items = resp.get("Items", [])

    return _ok({"items": items})

def get_events():
    return _ok({"items": []})

def post_block(event):
    body = json.loads(event.get("body") or "{}")
    ip = body.get("ip")

    if not ip:
        return {"statusCode": 400, "body": "Missing ip"}
    
    table = ddb.Table(THREATINTEL_TABLE)
    expires = (datetime.datetime.utcnow() + datetime.timedelta(hours=24)).isoformat() + "Z"

    table.update_item(
        Key={"ip": ip},
        UpdateExpression="""
            SET block_status = :b,
                block_expires = :e
        """,
        ExpressionAttributeValue={
            ":b": "BLOCKED",
            ":e": expires,
        }
    )
    
    return _ok({"status": "ok", "ip": ip, "blocked_until": expires})

def _ok(body):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str)
    }