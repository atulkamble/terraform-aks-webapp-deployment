# Run the AKS Web Application

1. Install Azure CLI, Terraform 1.11 or newer (below 2.0), Docker, kubectl, kubelogin, and Git. Start Docker and verify the tools with `az --version`, `terraform version`, `docker version`, `kubectl version --client`, and `kubelogin --version`.

2. Open a terminal in the repository root. Build the application locally with `docker build -t aks-webapp:v1 ./app`.

3. Run `docker run -d --name aks-webapp --read-only --tmpfs /tmp:uid=101,gid=101 -p 8080:8080 aks-webapp:v1`. Open `http://localhost:8080`, then check `curl --fail http://localhost:8080/health`. Stop the local container with `docker rm -f aks-webapp` when finished.

4. Sign in with `az login` and select your subscription with `az account set --subscription "<SUBSCRIPTION-ID>"`. Use an identity with Contributor and Role Based Access Control Administrator permissions for provisioning resources and assigning roles. Verify the subscription with `az account show`.

5. Create an Azure DevOps Azure Resource Manager service connection named `azure-production-connection` using workload identity federation. Record its Entra service principal object ID; it is different from the application/client ID. Grant this identity Contributor and Role Based Access Control Administrator at the deployment scope (subscription scope when creating the resource group).

6. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars`. Set the subscription ID, region, resource group, AKS name, globally unique ACR name, and VNet name. Set `admin_principal_ids` to your Entra user object ID and the service connection principal object ID. Find your user object ID with `az ad signed-in-user show --query id -o tsv`. Choose a region with capacity for `Standard_D2s_v5` nodes, or change `node_vm_size` in the variable file.

7. Choose a globally unique storage account name containing 3–24 lowercase letters/digits. Run `TFSTATE_STORAGE_ACCOUNT=<unique-name> bash scripts/bootstrap-state.sh`. This creates the remote state resources and writes `terraform/backend.hcl`. To use an existing backend, copy `terraform/backend.hcl.example` to `terraform/backend.hcl` and set its values instead. Grant both your user and the pipeline identity Storage Blob Data Contributor on that storage account. Allow a few minutes for new role assignments to propagate.

8. Run `terraform -chdir=terraform fmt -check -recursive`, then `terraform -chdir=terraform init -backend-config=backend.hcl`, followed by `terraform -chdir=terraform validate`.

9. Run `terraform -chdir=terraform plan -out=tfplan`. Review the resources and costs, then provision them with `terraform -chdir=terraform apply tfplan`. Keep `terraform/.terraform.lock.hcl` committed; keep local variable files, backend configuration, state, and plan files out of Git.

10. Verify the deployed names with `terraform -chdir=terraform output`. In the Azure portal, grant the service connection identity AcrPush on the created registry. Terraform grants the AKS kubelet AcrPull and grants the principals configured in step 6 AKS cluster access. Wait for those grants to propagate before deploying.

11. From the repository root, run `bash scripts/deploy-app.sh v1`. The script builds a Linux AMD64 image, pushes it to ACR, connects to AKS using your Azure CLI login, substitutes the image in the deployment, applies the Kubernetes resources, and waits for the rollout.

12. Run `kubectl get nodes -o wide`, `kubectl get pods,svc,hpa -n production`, and `kubectl rollout status deployment/webapp -n production --timeout=300s`. Wait until `kubectl get svc webapp-service -n production` shows an external IP, then open `http://<EXTERNAL-IP>` and check `http://<EXTERNAL-IP>/health`.

13. In Azure DevOps, install the Microsoft DevLabs Terraform extension to make `TerraformInstaller@1` available. Create a Library variable group named `aks-production` and authorize both pipelines to use it and the service connection.

14. Add these variables to `aks-production`, matching your Terraform/backend settings: `location`, `resourceGroup`, `aksCluster`, `acrName`, `tfstateResourceGroup`, `tfstateStorageAccount`, `tfstateContainer` (normally `tfstate`), and `tfstateKey` (normally `production.aks.tfstate`). Set `adminPrincipalIds` to a JSON array of the same Entra object IDs used in step 6. If you customized the VNet name or VM size, add `vnetName` and `nodeVmSize` to the group with the matching values.

15. Create an Azure DevOps environment named `production`. Add Approvals and Checks, select production approvers, and authorize the pipelines. Add an exclusive lock check to serialize infrastructure applies. Restrict access to the Terraform plan artifacts.

16. Create the infrastructure pipeline from `pipelines/infrastructure.yml`. Run it on `main`, review the `terraform-plan-review` artifact, and approve the production deployment. The apply stage uses the saved plan from that run. Complete infrastructure provisioning before running the application pipeline.

17. Create the application pipeline from `pipelines/application.yml`. Run it on `main` and approve deployment to `production`. It builds and tests the container, scans for fixable high/critical vulnerabilities, pushes a build-number image tag, and deploys to AKS. Update the base image and rerun if the scan blocks a release.

18. To release an update, edit `app/index.html`, commit the application changes, and push to `main`; approve the application deployment. For a manual release, run `bash scripts/deploy-app.sh v2` with a new image tag.

19. Inspect logs with `kubectl logs -n production deployment/webapp`; inspect scaling with `kubectl get hpa -n production` and `kubectl top pods -n production`. Open the AKS resource's Insights view in the Azure portal to inspect Container Insights and the provisioned Log Analytics workspace.

20. To remove the deployed platform, run `terraform -chdir=terraform plan -destroy -out=destroy.tfplan`, review the plan, then run `terraform -chdir=terraform apply destroy.tfplan`. Remove the separately bootstrapped state resource group only after you no longer need its state or version history.
