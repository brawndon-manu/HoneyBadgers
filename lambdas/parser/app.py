import json
import base64
import gzip

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
        if data:
            decompressed = gzip.decompress(base64.b64decode(data))
            print(decompressed.decode("utf-8"))
        else:
            print("No awslogs.data found in event")
    except Exception as e:
        print(f"Error processing log event: {e}")

    return {
        "statusCode": 200,
        "body": json.dumps({"ok": True})
    }
