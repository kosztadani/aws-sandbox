#!/bin/bash

set -euo pipefail

declare -g AWS_REGION=eu-central-1
declare -g AWS_S3_BUCKET="sandbox.aws.kosztadani.me"
declare -g TERRAFORM_STATE_FILE="terraform/terraform.tfstate"

aws sso login

aws s3 mb "s3://${AWS_S3_BUCKET}" || true

terraform init \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="bucket=${AWS_S3_BUCKET}" \
    -backend-config="key=${TERRAFORM_STATE_FILE}"
