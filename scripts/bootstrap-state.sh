#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFSTATE_RESOURCE_GROUP="${TFSTATE_RESOURCE_GROUP:-rg-tfstate-prod}"
TFSTATE_LOCATION="${TFSTATE_LOCATION:-centralindia}"
if [[ -n "${TFSTATE_STORAGE_ACCOUNT:-}" && ! "$TFSTATE_STORAGE_ACCOUNT" =~ ^[a-z0-9]{3,24}$ ]]; then
  echo "Invalid storage account name." >&2
  exit 1
fi
if [[ -e "$project_dir/terraform/backend.hcl" ]]; then
  echo "terraform/backend.hcl already exists; use its backend rather than bootstrapping another." >&2
  exit 1
fi
az account show --output none
if [[ -z "${TFSTATE_STORAGE_ACCOUNT:-}" ]]; then
  for attempt in {1..10}; do
    # A project prefix plus 16 random hex characters fits Azure's 24-character limit.
    candidate="staks$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
    if [[ "$(az storage account check-name --name "$candidate" --query nameAvailable --output tsv)" == true ]]; then
      TFSTATE_STORAGE_ACCOUNT="$candidate"
      break
    fi
  done
  if [[ -z "${TFSTATE_STORAGE_ACCOUNT:-}" ]]; then
    echo "Could not find an available storage account name after 10 attempts." >&2
    exit 1
  fi
fi
echo "Using Terraform state storage account: $TFSTATE_STORAGE_ACCOUNT"
principal_id="${TFSTATE_PRINCIPAL_ID:-$(az ad signed-in-user show --query id --output tsv)}"
az group create --name "$TFSTATE_RESOURCE_GROUP" --location "$TFSTATE_LOCATION" --output none
az storage account create --name "$TFSTATE_STORAGE_ACCOUNT" \
  --resource-group "$TFSTATE_RESOURCE_GROUP" --location "$TFSTATE_LOCATION" \
  --sku Standard_LRS --kind StorageV2 --min-tls-version TLS1_2 \
  --allow-blob-public-access false --allow-shared-key-access false --output none
storage_id="$(az storage account show --name "$TFSTATE_STORAGE_ACCOUNT" \
  --resource-group "$TFSTATE_RESOURCE_GROUP" --query id --output tsv)"
az role assignment create --assignee-object-id "$principal_id" \
  --role "Storage Blob Data Contributor" --scope "$storage_id" --output none

# New RBAC grants can take several minutes to reach the storage data plane.
container_ready=false
for attempt in {1..30}; do
  if az storage container create --name tfstate \
    --account-name "$TFSTATE_STORAGE_ACCOUNT" --auth-mode login --output none; then
    container_ready=true
    break
  fi
  echo "Waiting for storage RBAC propagation (attempt $attempt/30)..." >&2
  sleep 10
done
if [[ "$container_ready" != true ]]; then
  echo "Container creation failed. Check storage permissions and rerun." >&2
  exit 1
fi
az storage account blob-service-properties update \
  --account-name "$TFSTATE_STORAGE_ACCOUNT" --resource-group "$TFSTATE_RESOURCE_GROUP" \
  --enable-versioning true --enable-delete-retention true --delete-retention-days 7 --output none
cat > "$project_dir/terraform/backend.hcl" <<EOF
resource_group_name  = "$TFSTATE_RESOURCE_GROUP"
storage_account_name = "$TFSTATE_STORAGE_ACCOUNT"
container_name       = "tfstate"
key                  = "production.aks.tfstate"
EOF
echo "Backend ready. Configuration written to terraform/backend.hcl."
echo "Initialize Terraform with: terraform -chdir=terraform init -backend-config=backend.hcl"
