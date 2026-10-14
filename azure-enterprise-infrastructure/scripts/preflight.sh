#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../terraform"
for tool in terraform az python3; do
  command -v "$tool" >/dev/null || { echo "Install $tool before deploying." >&2; exit 1; }
done
[[ -f terraform.tfvars ]] || { echo 'Copy terraform.tfvars.example to terraform.tfvars and fill it in.' >&2; exit 1; }
az account show --output none
terraform init -input=false -lockfile=readonly
terraform fmt -check -recursive
terraform validate
terraform test
terraform plan -input=false -out=tfplan
printf '%s\n' 'Review the plan and subscription, then run: terraform apply tfplan (from terraform/).'
