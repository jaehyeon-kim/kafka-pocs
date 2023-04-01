import json


def lambda_function(event, context):
    return json.dumps({"Hello": "World!"})
