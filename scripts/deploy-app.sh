#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
image_tag="${1:-v1}"
if [[ ! "$image_tag" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}$ ]]; then
  echo "Invalid Docker image tag." >&2
  exit 1
fi
resource_group="$(terraform -chdir=terraform output -raw resource_group_name)"
aks_name="$(terraform -chdir=terraform output -raw aks_name)"
acr_name="$(terraform -chdir=terraform output -raw acr_name)"
acr_server="$(terraform -chdir=terraform output -raw acr_login_server)"
image="$acr_server/webapp:$image_tag"
# The documented AKS VM size uses x86 nodes, including when building from a Mac.
az acr login --name "$acr_name"
docker build --platform linux/amd64 --tag "$image" ./app
docker push "$image"
az aks get-credentials --resource-group "$resource_group" --name "$aks_name" --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
kubectl apply -f kubernetes/namespace.yaml
kubectl set image --local -f kubernetes/deployment.yaml "webapp=$image" -o yaml | kubectl apply -f -
kubectl apply -f kubernetes/service.yaml -f kubernetes/hpa.yaml
kubectl rollout status deployment/webapp -n production --timeout=300s
kubectl get service webapp-service -n production
