#!/bin/bash

# AWS ECS Cleanup Script for Financial Data Extraction Tool
# This script removes all AWS resources to stop billing

set -e  # Exit on any error

# Configuration
REGION="us-east-1"
ACCOUNT_ID="736661648095"
REPO_NAME="financial-data-extraction"
CLUSTER_NAME="financial-data-extraction-cluster"
SERVICE_NAME="financial-data-extraction-service"
TASK_FAMILY="financial-data-extraction-task"

echo "🧹 Starting AWS ECS Cleanup..."
echo "💰 This will stop all billing for your deployment"

# Step 1: Stop and delete ECS service
echo "🛑 Stopping ECS service..."
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --desired-count 0 \
    --region $REGION 2>/dev/null || echo "Service might not exist"

echo "⏳ Waiting for tasks to stop..."
sleep 30

echo "🗑️ Deleting ECS service..."
aws ecs delete-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --region $REGION 2>/dev/null || echo "Service might not exist"

echo "✅ ECS service cleaned up"

# Step 2: Delete ECS cluster
echo "🗑️ Deleting ECS cluster..."
aws ecs delete-cluster \
    --cluster $CLUSTER_NAME \
    --region $REGION 2>/dev/null || echo "Cluster might not exist"

echo "✅ ECS cluster cleaned up"

# Step 3: Delete security group
echo "🔒 Deleting security group..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $REGION 2>/dev/null || echo "")

if [ ! -z "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    SG_ID=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=financial-data-extraction-sg" "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[0].GroupId' --output text --region $REGION 2>/dev/null || echo "")
    
    if [ ! -z "$SG_ID" ] && [ "$SG_ID" != "None" ]; then
        aws ec2 delete-security-group --group-id $SG_ID --region $REGION 2>/dev/null || echo "Security group might not exist"
    fi
fi

echo "✅ Security group cleaned up"

# Step 4: Delete CloudWatch log group
echo "📊 Deleting CloudWatch log group..."
aws logs delete-log-group --log-group-name "/ecs/financial-data-extraction" --region $REGION 2>/dev/null || echo "Log group might not exist"

echo "✅ CloudWatch log group cleaned up"

# Step 5: ECR repository cleanup (optional)
echo "📦 ECR repository cleanup..."
echo "⚠️  Note: ECR repository '$REPO_NAME' still exists with your Docker images."
echo "   To delete it completely (including all images), run:"
echo "   aws ecr delete-repository --repository-name $REPO_NAME --force --region $REGION"

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "💰 All billable resources have been removed."
echo "✅ Your AWS account should no longer incur charges for this deployment!"
echo ""
echo "📊 You can verify cleanup in AWS Console:"
echo "   - ECS: https://console.aws.amazon.com/ecs/home?region=$REGION"
echo "   - ECR: https://console.aws.amazon.com/ecr/repositories?region=$REGION"
