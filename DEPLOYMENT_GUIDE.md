# 🚀 Financial Data Extraction Tool - AWS Deployment Guide

## 📋 Overview

This guide shows how to deploy your Financial Data Extraction Tool to AWS ECS with minimal cost configuration for learning purposes.

## 🏗️ Cloud Architecture

```
                    Internet Users
                          │
                          ▼
                   ┌─────────────┐
                   │   Internet  │
                   │   Gateway   │
                   └─────────────┘
                          │
                          ▼
              ┌─────────────────────────┐
              │      AWS VPC            │
              │  (Default VPC)          │
              │                         │
              │  ┌─────────────────┐    │
              │  │ Security Group  │    │
              │  │ Port 8501 Open  │    │
              │  └─────────────────┘    │
              │           │             │
              │           ▼             │
              │  ┌─────────────────┐    │
              │  │   ECS Fargate   │    │
              │  │   Container     │    │
              │  │                 │    │
              │  │ ┌─────────────┐ │    │
              │  │ │ Streamlit   │ │    │
              │  │ │ App         │ │    │
              │  │ │ Port 8501   │ │    │
              │  │ └─────────────┘ │    │
              │  └─────────────────┘    │
              └─────────────────────────┘
                          │
                          ▼
              ┌─────────────────────────┐
              │    AWS Services         │
              │                         │
              │ ┌─────────┐ ┌─────────┐ │
              │ │   ECR   │ │CloudWatch│ │
              │ │Registry │ │  Logs    │ │
              │ └─────────┘ └─────────┘ │
              └─────────────────────────┘
```

## 🔧 Components Explained

### **1. Internet Gateway**
- Provides internet access to your VPC
- Allows users to reach your application

### **2. VPC (Virtual Private Cloud)**
- Isolated network environment
- Uses AWS default VPC for simplicity

### **3. Security Group**
- Acts as a virtual firewall
- Opens port 8501 for Streamlit access
- Restricts other ports for security

### **4. ECS Fargate Container**
- **Serverless container** hosting your app
- **0.25 vCPU, 0.5 GB RAM** (cost-optimized)
- **Auto-scaling** capabilities (set to 1 instance)

### **5. ECR (Elastic Container Registry)**
- Stores your Docker image
- Private repository for your application

### **6. CloudWatch Logs**
- Collects application logs
- Helps with debugging and monitoring

## 📊 Resource Specifications

| Component | Configuration | Purpose |
|-----------|---------------|---------|
| **ECS Cluster** | 1 Fargate task | Container orchestration |
| **CPU** | 0.25 vCPU | Minimal compute for cost savings |
| **Memory** | 0.5 GB RAM | Sufficient for Streamlit app |
| **Storage** | Ephemeral | No persistent storage needed |
| **Network** | Public IP | Internet accessibility |
| **Port** | 8501 | Streamlit default port |

## 🚀 Deployment Steps

### **Prerequisites**
- AWS CLI configured
- Docker installed
- OpenAI and Groq API keys

### **Step 1: Deploy**
```bash
# Set your API keys
export OPENAI_API_KEY="your-openai-key"
export GROQ_API_KEY="your-groq-key"

# Deploy to AWS
./deploy.sh
```

### **Step 2: Access Your App**
After deployment (5-10 minutes), you'll get:
```
🎉 Your app is now running at: http://YOUR-PUBLIC-IP:8501
```

### **Step 3: Test the Application**
1. Open the provided URL
2. Upload a financial document
3. Select AI model (OpenAI/Groq)
4. Extract and download data

## 💰 Cost Breakdown

| Service | Monthly Cost |
|---------|--------------|
| **Fargate vCPU** | ~$3.65 |
| **Fargate Memory** | ~$1.83 |
| **ECR Storage** | ~$0.05 |
| **CloudWatch Logs** | ~$0.50 |
| **Data Transfer** | ~$0.10 |
| **Total** | **~$6.13/month** |

## 🔒 Security Features

- **VPC Isolation**: App runs in isolated network
- **Security Groups**: Firewall rules control access
- **IAM Roles**: Minimal permissions for ECS tasks
- **Private Registry**: Docker images stored securely

## 📈 Monitoring & Logs

### **ECS Console**
Monitor your deployment:
```
https://console.aws.amazon.com/ecs/home?region=us-east-1
```

### **CloudWatch Logs**
View application logs:
```
https://console.aws.amazon.com/cloudwatch/home?region=us-east-1
```

### **Key Metrics to Watch**
- **CPU Utilization**: Should be < 80%
- **Memory Utilization**: Should be < 80%
- **Task Health**: Should show "RUNNING"
- **Application Logs**: Check for errors

## 🧹 Cleanup

When done learning:
```bash
./cleanup.sh
```

This removes all resources and stops billing.

## 🎯 Learning Outcomes

By completing this deployment, you've learned:

### **AWS Services**
- ✅ **ECS Fargate**: Serverless container orchestration
- ✅ **ECR**: Container image registry
- ✅ **VPC**: Virtual networking
- ✅ **Security Groups**: Network security
- ✅ **CloudWatch**: Monitoring and logging

### **DevOps Practices**
- ✅ **Containerization**: Docker for application packaging
- ✅ **Infrastructure as Code**: Automated deployment scripts
- ✅ **Cost Optimization**: Minimal resource allocation
- ✅ **Security**: Network isolation and access control
- ✅ **Monitoring**: Application observability

### **Cloud Architecture**
- ✅ **Serverless Computing**: No server management
- ✅ **Microservices**: Containerized application design
- ✅ **Scalability**: Auto-scaling capabilities
- ✅ **High Availability**: AWS managed infrastructure

## 🔗 Useful Commands

```bash
# Deploy application
./deploy.sh

# Check deployment status
aws ecs describe-services --cluster financial-data-extraction-cluster \
  --services financial-data-extraction-service --region us-east-1

# View logs
aws logs tail /ecs/financial-data-extraction --follow --region us-east-1

# Scale up/down
aws ecs update-service --cluster financial-data-extraction-cluster \
  --service financial-data-extraction-service --desired-count 2

# Clean up everything
./cleanup.sh
```

## 📞 Troubleshooting

### **App Not Accessible**
1. Check ECS service status
2. Verify security group rules
3. Confirm task is running

### **High Costs**
1. Check if multiple tasks are running
2. Verify resource allocation
3. Use cleanup script when not needed

### **Application Errors**
1. Check CloudWatch logs
2. Verify API keys are set
3. Confirm Docker image built correctly

---

**🎉 Congratulations! You've successfully deployed a production-ready application on AWS with enterprise-grade architecture at minimal cost!**
