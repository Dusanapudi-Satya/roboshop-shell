#!/bin/bash
AMI=ami-0055977a6e828a4f4
SG_ID=sg-0fc80fbc6e913cfb1
INSTANCES=("web" "mongodb" "catalogue" "user" "cart" "redis" "mysql" "rabbitmq" "dispatch" "payment" "shipping")
ZONE_ID=Z069090936RP6OBB6IHHA
DOMAIN_NAME=satyadaws.online
for i in "${INSTANCES[@]}"
do
    #echo "instance is :  $i"
    if [ $i == mongodb ] || [ $i == mysql ] || [ $i == shipping ] 
    then
    INSTANCE_TYPE=t3.small
    else
    INSTANCE_TYPE=t3.micro
    fi
    IPADDRESS=$(aws ec2 run-instances --image-id ami-0055977a6e828a4f4 --instance-type t3.micro --security-group-ids sg-0fc80fbc6e913cfb1 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$i}]" --query "Instances[0].PrivateIpAddress" --output text)
    echo " $i : $IPADDRESS "
    # creating route53 records CLI 
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Testing creating a record set"
         ,
        "Changes": [{
        "Action"             : "CREATE"
      , "ResourceRecordSet"  : {
        "Name"              : "$i.$DOMAIN_NAME"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "$IPADDRESS"
        }]
      }
    }]
    }
    '
done