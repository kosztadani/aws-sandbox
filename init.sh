#!/usr/bin/env bash

set -Eeuo pipefail

declare -g working_directory="$(dirname "$(readlink -f "${0}")")"
declare -g aws_region=eu-central-1
declare -g terraform_state_file="terraform/terraform.tfstate"
declare -g terraform_vars_file="${working_directory}/local.auto.tfvars"
declare -g aws_s3_bucket="" # filled when creating it

function main() {
    initialize_script
    check_if_already_initialized
    aws_login
    create_bucket
    initialize_terraform
}

function initialize_script() {
    trap handle_error ERR
}

function handle_error() {
    >&2 echo "ERROR while running init.sh"
    >&2 echo "Trying to clean up..."
    if [[ ${aws_s3_bucket} != "" ]]; then
        >&2 echo "S3 bucket already created: ${aws_s3_bucket}."
        >&2 echo "Trying to delete it."
        aws s3 rb "s3://${aws_s3_bucket}"
        >&2 echo "Deleted bucket."
    fi
    rm -f "${terraform_vars_file}"
    >&2 echo "Cleanup complete."
    exit 2
}

function check_if_already_initialized() {
    if [[ -e "${terraform_vars_file}" ]]; then
        >&2 echo "Already initialized."
        >&2 echo ""
        >&2 echo "If you want to store your terraform state in a new bucket, delete:"
        >&2 echo "- local.auto.tfvars"
        >&2 echo "- terraform/terraform.tfstate"
        exit 1
    fi
}

function aws_login() {
    aws sso login
}

function create_bucket() {
    aws_s3_bucket="aws-sandbox-$(uuidgen)"
    aws s3 mb "s3://${aws_s3_bucket}"
    printf "s3_bucket = \"%s\"\n" "${aws_s3_bucket}" >"${terraform_vars_file}"
}

function initialize_terraform() {
    terraform init \
        -backend-config="region=${aws_region}" \
        -backend-config="bucket=${aws_s3_bucket}" \
        -backend-config="key=${terraform_state_file}"
}

main
