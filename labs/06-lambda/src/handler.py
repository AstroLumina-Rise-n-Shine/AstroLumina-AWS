import os


def handler(event, context):
    return {"statusCode": 200, "body": os.environ.get("GREETING", "hello from lambda")}
