#!/bin/bash

REGION='us-west-2'

VPC_ID=$(aws --region $REGION cloudformation describe-stacks \
  --stack-name hard-k8s-network \
  --query 'Stacks[0].Outputs[?ExportName==`hard-k8s-vpc`].OutputValue' --output text)

aws --region $REGION ec2 describe-instances \
  --filters Name=vpc-id,Values=$VPC_ID \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],InstanceId,Placement.AvailabilityZone,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output text | sort
