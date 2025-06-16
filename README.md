# Home Assignment

This project provisions a microservices architecture on AWS using Terraform. It deploys a scalable infrastructure to support two microservices: a frontend service and a queue worker service. The infrastructure includes:

- **VPC**: A Virtual Private Cloud with public and private subnets.
- **ALB**: An Application Load Balancer exposing the frontend service.
- **ECS**: An Elastic Container Service cluster running `frontend-service` and `queue-worker-service` on Fargate.
- **SQS**: A Simple Queue Service queue for message passing between services.
- **S3**: Buckets for Terraform state management and application data storage.
![ee606380-e6c6-4ccb-9e1d-933388af0082](https://github.com/user-attachments/assets/9c0d084c-5527-4c2e-99e1-95ccf070d2de)

![4a8bc249-b86b-4840-86cc-9b05fb4bef70](https://github.com/user-attachments/assets/71b27eed-c9e3-40c3-9156-d11e88c9c5fc)


The `frontend-service` is a Flask application that accepts POST requests, validates them, and sends messages to an SQS queue. The `queue-worker-service` is a Python application that polls the SQS queue, processes messages, and uploads them to an S3 bucket.

## Prerequisites

To set up and use this project, ensure you have the following:

- **AWS Account**: With permissions to create VPC, ECS, SQS, S3, ALB, and IAM resources.
- **Terraform**: Installed (version 1.12.2 or compatible).
- **AWS CLI**: Installed and configured with credentials (`aws configure`).
- **Docker**: Installed for building microservice images.
- **Git**: For cloning the repository and managing code.

## Infrastructure Setup

Follow these steps to deploy the infrastructure manually.

### 1. Set Up Terraform State Bucket

The project uses an S3 bucket to store Terraform state. Run the provided script to create this bucket and apply the root Terraform configuration:

```bash
./create-state-init-bucket.sh
```

This script:
- Checks if the bucket `terraform-state-bucket-eliran` exists in `eu-central-1`.
- Creates it if it doesn’t, enabling versioning and blocking public access.
- Initializes Terraform and applies the root configuration to set up the state bucket and an application data bucket (`data-bucket-eliran-prod`).

### 2. Deploy Production Environment

Navigate to the `environments/prod` directory to deploy the full infrastructure:

```bash
cd environments/prod
terraform init
terraform apply -auto-approve
```

This step:
- Configures the Terraform backend to use the state bucket created in step 1.
- Deploys the VPC, ALB, ECS cluster, SQS queue, and related resources using the variables in `terraform.tfvars`.

## Microservices Deployment

The project includes two microservices:
- **`frontend-service`**: A Flask app exposed via the ALB on port 5000.
- **`queue-worker-service`**: A worker that processes SQS messages and uploads them to S3, running on port 5001.

### Manual Deployment

To deploy the microservices manually:

1. **Build Docker Images**:
   For each service, navigate to its directory and build the image:
   ```bash
   cd microservices/frontend-service
   docker build -t 048999592382.dkr.ecr.eu-central-1.amazonaws.com/frontend-service:latest .
   cd ../queue-worker-service
   docker build -t 048999592382.dkr.ecr.eu-central-1.amazonaws.com/sqs-puller-service:latest .
   ```

2. **Push Images to ECR**:
   Authenticate Docker with ECR:
   ```bash
   aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 048999592382.dkr.ecr.eu-central-1.amazonaws.com
   ```
   Then push the images:
   ```bash
   docker push 048999592382.dkr.ecr.eu-central-1.amazonaws.com/frontend-service:latest
   docker push 048999592382.dkr.ecr.eu-central-1.amazonaws.com/sqs-puller-service:latest
   ```

3. **Update Terraform Variables**:
   Edit `environments/prod/terraform.tfvars` to update the image tags:
   ```
   frontend_image_tag = "latest"
   queue_worker_image_tag = "latest"
   ```

4. **Apply Terraform**:
   ```bash
   cd environments/prod
   terraform apply -auto-approve
   ```
   This updates the ECS task definitions with the new image tags.

### Automated Deployment (CI/CD)

The project includes GitHub Actions workflows (not provided in the query but referenced in the structure) for automated deployment. These workflows would:
- Build and push Docker images to ECR.
- Update `terraform.tfvars` with new image tags.
- Apply Terraform to redeploy the ECS services.

To enable CI/CD, ensure your GitHub repository has AWS credentials configured as secrets.

## Usage

Once deployed, interact with the frontend service via the ALB DNS name (output as `alb_dns_name` after `terraform apply`).

### Sending Requests

Send a POST request to the frontend service:

```bash
curl -X POST http://<alb-dns-name>/ \
  -H "Content-Type: application/json" \
  -d '{"token": "<your-token>", "data": {"email_timestream": "2023-01-01T00:00:00Z", "key": "value"}}'
```

- Replace `<alb-dns-name>` with the ALB’s DNS name.
- Replace `<your-token>` with the token stored in AWS SSM Parameter Store at `/app/frontend/token`.

The frontend service:
- Validates the token and `email_timestream` format.
- Sends the `data` payload to the SQS queue if valid.

The queue worker service then processes the message and uploads it to the `data-bucket-eliran-prod` S3 bucket with a timestamped filename.

### Health Check

Check the frontend service status with a GET request:
```bash
curl http://<alb-dns-name>/
```
Returns `{"status": "healthy"}` if running correctly.

## Troubleshooting

- **ECS Service Issues**:
  Check service events:
  ```bash
  aws ecs describe-services --cluster devops-prod-cluster --services frontend-service queue-worker-service --region eu-central-1
  ```

- **Container Logs**:
  View logs for debugging:
  ```bash
  aws logs tail /ecs/frontend-service --region eu-central-1 --since 10m
  aws logs tail /ecs/queue-worker-service --region eu-central-1 --since 10m
  ```

- **ALB Health**:
  Verify target group health:
  ```bash
  aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region eu-central-1
  ```
  Replace `<target-group-arn>` with the value from `terraform output target_group_arn`.

## Directory Structure

This project is organized to separate infrastructure, microservices, and reusable Terraform modules. Below is a detailed breakdown of the directories and files, with specific information about each component’s purpose and functionality:

```
.
├── backend.tf                     # Configures S3 backend for Terraform state storage
├── create-state-init-bucket.sh    # Script to create S3 state bucket and bootstrap Terraform
├── environments/                  # Environment-specific Terraform configurations
│   └── prod/                      # Production environment setup
│       ├── backend.tf             # S3 backend for production Terraform state
│       ├── main.tf                # Orchestrates VPC, ALB, ECS, SQS for production
│       ├── output.tf              # Outputs ALB DNS, ECS cluster ID, SQS URL
│       ├── terraform.tfvars       # Production variables (e.g., VPC CIDR, image tags)
│       └── variables.tf           # Declares variables for production config
├── main.tf                        # Root Terraform config for S3 state and app buckets
├── microservices/                 # Microservices source code and build configs
│   ├── frontend-service/          # Flask API service (Port 5000)
│   │   ├── app.py                 # Handles HTTP requests, sends data to SQS
│   │   ├── Dockerfile             # Container config for frontend (Python 3.9-slim)
│   │   └── requirements.txt       # Dependencies: flask==2.3.3, boto3==1.34.0
│   └── queue-worker-service/      # SQS message processor (Port 5001)
│       ├── app.py                 # Polls SQS queue, uploads messages to S3
│       ├── Dockerfile             # Container config for worker (Python 3.9-slim)
│       └── requirements.txt       # Dependencies: boto3==1.18.0
├── modules/                       # Reusable Terraform modules
│   ├── compute/                   # Compute resources
│   │   └── ecs/                   # ECS cluster and services configuration
│   │       ├── main.tf            # Defines ECS cluster, tasks, services, IAM roles
│   │       ├── outputs.tf         # Outputs cluster ID, service names, SG ID
│   │       └── variables.tf       # Inputs: cluster name, image tags, VPC ID
│   ├── infrastructure/            # Infrastructure components (S3, SQS)
│   │   ├── s3_app/                # Application data S3 bucket
│   │   │   ├── main.tf            # Creates S3 bucket for app data
│   │   │   ├── outputs.tf         # Outputs bucket ARN
│   │   │   └── variables.tf       # Input: bucket name
│   │   ├── s3_state/              # Terraform state S3 bucket
│   │   │   ├── main.tf            # Creates S3 bucket with versioning, encryption
│   │   │   ├── outputs.tf         # Outputs bucket name
│   │   │   └── variables.tf       # Input: bucket name
│   │   └── sqs/                   # SQS queue for message passing
│   │       ├── main.tf            # Creates SQS queue
│   │       ├── outputs.tf         # Outputs queue URL
│   │       └── variables.tf       # Input: queue name
│   └── networking/                # Networking resources
│       ├── alb/                   # Application Load Balancer setup
│       │   ├── main.tf            # Defines ALB, target group, listener (Port 80)
│       │   ├── outputs.tf         # Outputs ALB DNS, target group ARN, SG ID
│       │   └── variables.tf       # Inputs: VPC ID, subnets, ALB name
│       └── vpc/                   # Virtual Private Cloud configuration
│           ├── main.tf            # Creates VPC, subnets, NAT, IGW, route tables
│           ├── outputs.tf         # Outputs VPC ID, public/private subnet IDs
│           └── variables.tf       # Inputs: VPC CIDR, subnet CIDRs, region
├── outputs.tf                     # Outputs root-level S3 bucket names and ARNs
├── README.md                      # Project documentation and setup guide
├── terraform.tfvars               # Root-level variables (e.g., S3 bucket names)
└── variables.tf                   # Declares root-level input variables
```

### Additional Notes
- **Terraform Modules**: The `modules/` directory follows a modular design, enabling reuse across environments. Each module includes `main.tf` for resources, `outputs.tf` for outputs, and `variables.tf` for inputs.
- **Microservices**: The `frontend-service` and `queue-worker-service` are containerized using Docker, with images stored in AWS ECR repositories (`frontend-service` and `sqs-puller-service`).
- **CI/CD**: While not shown in the tree, `.github/workflows/` may contain GitHub Actions workflows for automating microservice deployment (e.g., building/pushing Docker images, updating Terraform).
- **State Management**: Terraform state is stored in an S3 bucket (`terraform-state-bucket-eliran`), with separate keys for root (`global/terraform.tfstate`) and production (`prod/terraform.tfstate`).
- **Security**: The `.gitignore` file (not listed in the tree) excludes sensitive files (e.g., `*.tfstate`, `.terraform/`) from version control.

This structure supports a scalable microservices architecture, with infrastructure managed by Terraform and applications deployed as Docker containers on ECS Fargate.
