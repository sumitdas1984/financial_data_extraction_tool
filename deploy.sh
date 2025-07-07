#!/bin/bash

# AWS ECS Deployment Script for Financial Data Extraction Tool
# Cost-optimized configuration for learning purposes

set -e  # Exit on any error

# Configuration
REGION="us-east-1"
ACCOUNT_ID="736661648095"
REPO_NAME="financial-data-extraction"
CLUSTER_NAME="financial-data-extraction-cluster"
SERVICE_NAME="financial-data-extraction-service"
TASK_FAMILY="financial-data-extraction-task"
IMAGE_TAG="latest"

echo "🚀 Starting Cost-Optimized AWS ECS Deployment..."
echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo "💰 Configuration: 0.25 vCPU, 0.5 GB RAM (~$5-8/month)"

# Check if API keys are set
if [ -z "$OPENAI_API_KEY" ] || [ -z "$GROQ_API_KEY" ]; then
    echo "❌ Error: Please set your API keys first:"
    echo "export OPENAI_API_KEY='your-openai-key'"
    echo "export GROQ_API_KEY='your-groq-key'"
    exit 1
fi

echo "✅ API keys are set"

# Step 1: Create ECR repository if it doesn't exist
echo "📦 Creating ECR repository..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION 2>/dev/null || \
aws ecr create-repository --repository-name $REPO_NAME --region $REGION

echo "✅ ECR repository ready"

# Step 2: Authenticate Docker with ECR
echo "🔐 Authenticating Docker with ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Step 3: Build Docker image
echo "🔨 Building Docker image..."
docker build -f Dockerfile.prod -t $REPO_NAME:$IMAGE_TAG .

echo "✅ Docker image built"

# Step 4: Tag and push image to ECR
echo "📤 Pushing image to ECR..."
ECR_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"
docker tag $REPO_NAME:$IMAGE_TAG $ECR_URI
docker push $ECR_URI

echo "✅ Image pushed to ECR"

# Step 5: Create ECS cluster
echo "🏗️ Creating ECS cluster..."
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $REGION 2>/dev/null || echo "Cluster might already exist"

# Wait for cluster to be active
echo "⏳ Waiting for cluster to be active..."
sleep 10

echo "✅ ECS cluster ready"

# Step 6: Create CloudWatch log group
echo "📊 Creating CloudWatch log group..."
aws logs create-log-group --log-group-name "/ecs/financial-data-extraction" --region $REGION 2>/dev/null || echo "Log group might already exist"

echo "✅ CloudWatch log group ready"

# Step 7: Create task definition
echo "📋 Creating task definition..."
cat > task-definition-temp.json << EOF
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::$ACCOUNT_ID:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "financial-data-extraction-container",
      "image": "$ECR_URI",
      "portMappings": [
        {
          "containerPort": 8501,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "environment": [
        {
          "name": "OPENAI_API_KEY",
          "value": "$OPENAI_API_KEY"
        },
        {
          "name": "GROQ_API_KEY",
          "value": "$GROQ_API_KEY"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/financial-data-extraction",
          "awslogs-region": "$REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://task-definition-temp.json --region $REGION
rm task-definition-temp.json

echo "✅ Task definition registered"

# Step 8: Get VPC and subnet information
echo "🌐 Getting VPC information..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text --region $REGION)
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text --region $REGION)
SUBNET_ARRAY=$(echo $SUBNET_IDS | tr ' ' ',')

echo "✅ Using VPC: $VPC_ID"

# Step 9: Create security group
echo "🔒 Creating security group..."
SG_ID=$(aws ec2 create-security-group \
    --group-name financial-data-extraction-sg \
    --description "Security group for financial data extraction ECS service" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' --output text 2>/dev/null || \
    aws ec2 describe-security-groups \
    --filters "Name=group-name,Values=financial-data-extraction-sg" "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[0].GroupId' --output text --region $REGION)

# Add inbound rule for port 8501
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 8501 \
    --cidr 0.0.0.0/0 \
    --region $REGION 2>/dev/null || echo "Security group rule already exists"

echo "✅ Security group ready: $SG_ID"

# Step 10: Create ECS service
echo "🚀 Creating ECS service..."
aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ARRAY],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
    --region $REGION 2>/dev/null || echo "Service might already exist, updating..."

# If service exists, update it
aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --desired-count 1 \
    --region $REGION 2>/dev/null || echo "Service created successfully"

echo "✅ ECS service deployed"

# Step 11: Wait for service to start
echo "⏳ Waiting for service to start (this may take 3-5 minutes)..."
sleep 60

# Get public IP
echo "🔍 Getting public IP address..."
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --region $REGION --query 'taskArns[0]' --output text)

if [ "$TASK_ARN" != "None" ] && [ "$TASK_ARN" != "" ]; then
    ENI_ID=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --region $REGION --query 'tasks[0].attachments[0].details[?name==`networkInterfaceId`].value' --output text)
    PUBLIC_IP=$(aws ec2 describe-network-interfaces --network-interface-ids $ENI_ID --region $REGION --query 'NetworkInterfaces[0].Association.PublicIp' --output text)
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "📱 Your app is now running at: http://$PUBLIC_IP:8501"
    echo ""
    echo "💰 Monthly cost estimate: ~$5-8 USD"
    echo "🧹 To clean up resources: ./cleanup.sh"
else
    echo "❌ Could not retrieve public IP. Checking status..."
    echo "Run: ./debug-ecs.sh for detailed diagnostics"
fi

echo ""
echo "✅ Deployment script completed!"
