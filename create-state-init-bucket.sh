#!/bin/bash

set -e

BUCKET_NAME="terraform-state-bucket-eliran"
REGION="eu-central-1"
MAX_RETRIES=5
RETRY_DELAY=5

# Check if bucket exists
if aws s3 ls "s3://$BUCKET_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "Bucket $BUCKET_NAME exists. Importing into Terraform state if needed..."
  terraform init || true
  terraform import module.s3_state_prod.aws_s3_bucket.state_bucket "$BUCKET_NAME" 2>/dev/null || echo "Bucket already imported or state up-to-date."
else
  echo "Bucket $BUCKET_NAME does not exist. Creating it..."
  aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
  aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
  aws s3api put-public-access-block --bucket "$BUCKET_NAME" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  # Wait for bucket to be available
  echo "Waiting for bucket $BUCKET_NAME to be available..."
  for ((i=1; i<=MAX_RETRIES; i++)); do
    if aws s3 ls "s3://$BUCKET_NAME" --region "$REGION" >/dev/null 2>&1; then
      echo "Bucket $BUCKET_NAME is available."
      break
    else
      echo "Attempt $i/$MAX_RETRIES: Bucket not available yet. Retrying in $RETRY_DELAY seconds..."
      sleep $RETRY_DELAY
    fi
    if [ $i -eq $MAX_RETRIES ]; then
      echo "Error: Bucket $BUCKET_NAME still not available after $MAX_RETRIES attempts."
      exit 1
    fi
  done
fi

# Initialize with S3 backend
terraform init

# Apply configuration
terraform apply -auto-approve

echo "Bootstrap complete. State stored in s3://$BUCKET_NAME/global/terraform.tfstate"