import json
import time


def lambda_function(event, context):
    for i in range(10):
        print(f"current run - {i}")
        time.sleep(1)
