#!/usr/bin/env bash
set -euo pipefail

: "${AZURESUBSCRIPTION_SERVICE_CONNECTION_ID:?Run this script in an AzureCLI@2 task.}"
: "${ARM_OIDC_REQUEST_TOKEN:?Map System.AccessToken into ARM_OIDC_REQUEST_TOKEN.}"
: "${TFSTATE_RESOURCE_GROUP:?}"
: "${TFSTATE_STORAGE_ACCOUNT:?}"
: "${TFSTATE_CONTAINER:?}"
: "${TFSTATE_KEY:?}"
export ARM_CLIENT_ID="${servicePrincipalId:?Enable addSpnToEnvironment in AzureCLI@2.}"
export ARM_TENANT_ID="${tenantId:?}"
export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
# Token refresh keeps long AKS applies and delayed approvals from using an expired ID token.
# https://devblogs.microsoft.com/devops/introducing-azure-devops-id-token-refresh-and-terraform-task-version-5/
export ARM_OIDC_AZURE_SERVICE_CONNECTION_ID="$AZURESUBSCRIPTION_SERVICE_CONNECTION_ID"
export ARM_USE_OIDC=true
export ARM_USE_CLI=false
export ARM_USE_AZUREAD=true
export TF_VAR_subscription_id="$ARM_SUBSCRIPTION_ID"
export TF_IN_AUTOMATION=true
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir/terraform"
terraform init -input=false -lockfile=readonly \
  -backend-config="resource_group_name=$TFSTATE_RESOURCE_GROUP" \
  -backend-config="storage_account_name=$TFSTATE_STORAGE_ACCOUNT" \
  -backend-config="container_name=$TFSTATE_CONTAINER" \
  -backend-config="key=$TFSTATE_KEY"
case "${1:-}" in
  plan)
    terraform plan -input=false -lock-timeout=5m -out=tfplan
    terraform show -no-color tfplan > plan.txt
    ;;
  apply)
    : "${PLAN_PATH:?Point PLAN_PATH to the downloaded approved plan.}"
    terraform apply -input=false -lock-timeout=5m "$PLAN_PATH"
    ;;
  *) echo "Usage: bash scripts/terraform-ci.sh plan|apply" >&2; exit 1 ;;
esac
