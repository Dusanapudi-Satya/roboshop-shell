#!/bin/bash
AMI=ami-0055977a6e828a4f4
SG_ID=sg-0fc80fbc6e913cfb1
INSTANCES=("web" "mongodb" "catalogue" "user" "cart" "redis" "mysql" "rabbitmq" "dispatch" "payment" "shipping")
ZONE_ID=Z069090936RP6OBB6IHHA
DOMAIN_NAME=satyadaws.online

for i in "${INSTANCES[@]}"
do
    if [ "$i" == "mongodb" ] || [ "$i" == "mysql" ] || [ "$i" == "shipping" ] 
    then
        INSTANCE_TYPE=t3.small
    else
        INSTANCE_TYPE=t3.micro
    fi

    # 1. Check if a running or pending instance with this Name tag already exists
    IPADDRESS=$(aws ec2 describe-instances \
        --filters "Name=tag:Name,Values=$i" "Name=instance-state-name,Values=pending,running" \
        --query "Reservations[0].Instances[0].PrivateIpAddress" \
        --output text)

    # 2. Only launch a new instance if none was found ("None" or empty)
    if [ -z "$IPADDRESS" ] || [ "$IPADDRESS" == "None" ]; then
        echo "Launching new instance for $i..."
        IPADDRESS=$(aws ec2 run-instances \
            --image-id "$AMI" \
            --instance-type "$INSTANCE_TYPE" \
            --security-group-ids "$SG_ID" \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" \
            --query "Instances[0].PrivateIpAddress" \
            --output text)
    else
        echo "Instance $i already exists with IP: $IPADDRESS"
    fi

    # 3. Create or update the Route 53 DNS record
    # UPSERT, if record exists it will edit otherwise it will create (CREATE only creates a record)
    if [ -n "$IPADDRESS" ] && [ "$IPADDRESS" != "None" ]; then
        aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch '{
            "Comment": "Creating or updating record set",
            "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'"$i.$DOMAIN_NAME"'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{
                        "Value": "'"$IPADDRESS"'"
                    }]
                }
            }]
        }'
    else
        echo "Failed to get IP for $i, skipping Route 53."
    fi
done