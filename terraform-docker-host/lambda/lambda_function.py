import boto3
import os
from datetime import datetime, timezone

INSTANCE_ID = os.environ["INSTANCE_ID"]
MAX_RUNTIME_HOURS = int(os.environ.get("MAX_RUNTIME_HOURS", "4"))


def lambda_handler(event, context):
    ec2 = boto3.client("ec2")
    instance = ec2.describe_instances(InstanceIds=[INSTANCE_ID])["Reservations"][0]["Instances"][0]
    state = instance["State"]["Name"]

    if state != "running":
        return f"Instance already {state}, no action taken"

    launch_time = instance["LaunchTime"]
    now = datetime.now(timezone.utc)
    runtime_hours = (now - launch_time).total_seconds() / 3600

    if runtime_hours >= MAX_RUNTIME_HOURS:
        ec2.stop_instances(InstanceIds=[INSTANCE_ID])
        return f"Stopped {INSTANCE_ID} after {runtime_hours:.1f} hours"
    return f"Instance running {runtime_hours:.1f}h, under {MAX_RUNTIME_HOURS}h limit"
