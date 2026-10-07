# Production-Grade Azure AKS Web Application Deployment using Terraform & Azure Pipelines

## 1. Project Information

| Field | Details |
|---|---|
| Project Title | Production-Grade Azure AKS Web Application Deployment using Terraform & Azure Pipelines |
| Repository Name | `terraform-aks-webapp-deployment` |
| Project Category | Cloud / DevOps / Kubernetes / Infrastructure as Code |
| Cloud Platform | Microsoft Azure |
| Role | Cloud / DevOps Solutions Architect |
| Infrastructure as Code | Terraform |
| Containerization | Docker |
| Container Registry | Azure Container Registry (ACR) |
| Container Orchestration | Azure Kubernetes Service (AKS) |
| CI/CD | Azure Pipelines |
| Source Control | Git / Azure Repos / GitHub |
| Networking | Azure VNet, Subnet, Load Balancer / Ingress |
| Security | Managed Identity, RBAC, Workload Identity, Key Vault |
| Monitoring | Azure Monitor / Log Analytics |
| Scaling | AKS Cluster Autoscaler + Kubernetes HPA |
| Deployment Strategy | Rolling Update |
| Environment | Production |

---

# 2. Project Objective

Design and implement a production-oriented Azure Kubernetes platform that automates:

- Azure infrastructure provisioning using Terraform
- AKS cluster creation and configuration
- Azure Container Registry provisioning
- Docker image creation
- Container image publishing to ACR
- Kubernetes application deployment
- Infrastructure CI/CD
- Application CI/CD
- Production approvals
- Application scaling
- Monitoring and security

The final workflow is:

```text
Developer
   ↓
Git Repository
   ↓
Azure Pipelines
   ↓
Terraform
   ↓
Azure Infrastructure
   ↓
Docker Build
   ↓
ACR
   ↓
AKS
   ↓
Kubernetes
   ↓
Web Application
```

---

# 3. Project Description

This project demonstrates the design and implementation of a production-grade containerized web application platform on Microsoft Azure.

Terraform is used to provision Azure infrastructure including:

- Resource Group
- Virtual Network
- AKS Subnet
- Azure Container Registry
- Azure Kubernetes Service
- System Node Pool
- Application Node Pool
- Managed Identity
- AKS-to-ACR permissions

Azure Pipelines provides CI/CD automation for both infrastructure and applications.

The infrastructure pipeline performs:

```text
terraform fmt
      ↓
terraform validate
      ↓
terraform plan
      ↓
Save Plan
      ↓
Production Approval
      ↓
terraform apply
```

The application pipeline performs:

```text
Source Code
     ↓
Docker Build
     ↓
Image Tag
     ↓
Push → ACR
     ↓
Deploy → AKS
     ↓
Rolling Update
     ↓
Production Web Application
```

---

# 4. Business / Technical Requirements

The platform should provide:

- Automated infrastructure provisioning
- Repeatable deployments
- Infrastructure version control
- Containerized application delivery
- Highly available Kubernetes workloads
- Application scaling
- Infrastructure scaling
- Secure Azure authentication
- Centralized container registry
- Health monitoring
- Controlled production deployments
- Rolling application updates
- Separation between system and application workloads

---

# 5. Technology Stack

| Layer | Technology |
|---|---|
| Cloud | Microsoft Azure |
| IaC | Terraform |
| Containers | Docker |
| Registry | Azure Container Registry |
| Kubernetes | Azure Kubernetes Service |
| CI/CD | Azure Pipelines |
| Source Control | Git |
| Networking | Azure VNet |
| Application Exposure | Azure Load Balancer / Ingress |
| Authentication | Microsoft Entra ID / Managed Identity |
| Secrets | Azure Key Vault |
| Monitoring | Azure Monitor |
| Logging | Log Analytics |
| Scaling | Cluster Autoscaler + HPA |

---

# 6. High-Level Architecture

```text
                         INTERNET
                            │
                            ▼
                      DNS / Public IP
                            │
                            ▼
                  Load Balancer / Ingress
                            │
                            ▼
             ┌──────── Azure VNet ────────┐
             │                            │
             │        AKS Subnet          │
             │                            │
             │   ┌────────────────────┐   │
             │   │    AKS Cluster     │   │
             │   │                    │   │
             │   │ System Node Pool   │   │
             │   │                    │   │
             │   │ User Node Pool     │   │
             │   │       │            │   │
             │   │       ▼            │   │
             │   │   Web App Pods     │   │
             │   │   ┌──┬──┬──┐      │   │
             │   │   │P1│P2│P3│      │   │
             │   │   └──┴──┴──┘      │   │
             │   └────────────────────┘   │
             │                            │
             └────────────────────────────┘
                            ▲
                            │
                         Pull Image
                            │
                       ┌────┴────┐
                       │   ACR   │
                       └────▲────┘
                            │
                       Push Image
                            │
                    Azure Pipelines
                            ▲
                            │
                       Git Repository
```

---

# 7. CI/CD Architecture

```text
                     Git Repository
                          │
                ┌─────────┴─────────┐
                │                   │
                ▼                   ▼

       Infrastructure CI/CD     Application CI/CD

          Terraform                 Docker
             │                        │
             ▼                        ▼
             FMT                    Build
             │                        │
             ▼                        ▼
          Validate                 Scan
             │                        │
             ▼                        ▼
            Plan                 Push ACR
             │                        │
             ▼                        ▼
       Save Plan Artifact            AKS
             │                        │
             ▼                        ▼
          Approval                 Deploy
             │                        │
             ▼                        ▼
           Apply                Rolling Update
```

---

# 8. Repository Structure

```text
terraform-aks-webapp-deployment/
│
├── app/
│   ├── index.html
│   ├── Dockerfile
│   └── nginx.conf
│
├── terraform/
│   ├── versions.tf
│   ├── providers.tf
│   ├── backend.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── kubernetes/
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── hpa.yaml
│
├── pipelines/
│   ├── infrastructure.yml
│   └── application.yml
│
├── .gitignore
└── README.md
```

---

# 9. Prerequisites

Required tools:

```bash
az --version
terraform --version
docker --version
kubectl version --client
git --version
```

Authenticate with Azure:

```bash
az login

az account show

az account set \
  --subscription "<SUBSCRIPTION-ID>"
```

---

# 10. Terraform Remote Backend

Create the Terraform state Resource Group:

```bash
az group create \
  --name rg-tfstate-prod \
  --location centralindia
```

Create a globally unique Storage Account:

```bash
STORAGE_ACCOUNT="tfstate$RANDOM$RANDOM"

az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-tfstate-prod \
  --location centralindia \
  --sku Standard_LRS \
  --kind StorageV2
```

Create container:

```bash
az storage container create \
  --name tfstate \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login
```

Terraform state architecture:

```text
Terraform
    │
    ▼
Azure Storage Account
    │
    ▼
tfstate Container
    │
    ▼
production.aks.tfstate
```

---

# 11. Terraform Provider Configuration

## `terraform/versions.tf`

```hcl
terraform {

  required_version = ">= 1.6.0"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

  }
}
```

## `terraform/providers.tf`

```hcl
provider "azurerm" {

  features {}

  subscription_id = var.subscription_id

}
```

---

# 12. Terraform Backend

## `terraform/backend.tf`

```hcl
terraform {

  backend "azurerm" {

    resource_group_name  = "rg-tfstate-prod"

    storage_account_name = "REPLACE_STORAGE_ACCOUNT"

    container_name = "tfstate"

    key = "production.aks.tfstate"

    use_azuread_auth = true

  }

}
```

---

# 13. Terraform Variables

## `terraform/variables.tf`

```hcl
variable "subscription_id" {
  type = string
}

variable "location" {

  type = string

  default = "Central India"

}

variable "resource_group_name" {

  type = string

  default = "rg-aks-production"

}

variable "aks_name" {

  type = string

  default = "aks-production"

}

variable "acr_name" {

  type = string

}

variable "vnet_name" {

  type = string

  default = "vnet-aks-production"

}
```

---

# 14. Terraform Values

## `terraform/terraform.tfvars`

```hcl
subscription_id = "YOUR-SUBSCRIPTION-ID"

location = "Central India"

resource_group_name = "rg-aks-production"

aks_name = "aks-production"

acr_name = "YOUR-UNIQUE-ACR"

vnet_name = "vnet-aks-production"
```

Do not commit production secrets or sensitive Terraform variable files.

---

# 15. Azure Resource Group

```hcl
resource "azurerm_resource_group" "main" {

  name = var.resource_group_name

  location = var.location

  tags = {

    Environment = "Production"

    ManagedBy = "Terraform"

    Project = "AKS-WebApp"

  }

}
```

---

# 16. Azure Virtual Network

```hcl
resource "azurerm_virtual_network" "main" {

  name = var.vnet_name

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name

  address_space = [

    "10.0.0.0/16"

  ]

}
```

---

# 17. AKS Subnet

```hcl
resource "azurerm_subnet" "aks" {

  name = "snet-aks"

  resource_group_name = azurerm_resource_group.main.name

  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = [

    "10.0.1.0/24"

  ]

}
```

---

# 18. Azure Container Registry

```hcl
resource "azurerm_container_registry" "acr" {

  name = var.acr_name

  resource_group_name = azurerm_resource_group.main.name

  location = azurerm_resource_group.main.location

  sku = "Premium"

  admin_enabled = false

}
```

---

# 19. AKS Cluster

```hcl
resource "azurerm_kubernetes_cluster" "aks" {

  name = var.aks_name

  location = azurerm_resource_group.main.location

  resource_group_name = azurerm_resource_group.main.name

  dns_prefix = var.aks_name

  role_based_access_control_enabled = true

  oidc_issuer_enabled = true

  workload_identity_enabled = true

  default_node_pool {

    name = "system"

    vm_size = "Standard_D2s_v5"

    vnet_subnet_id = azurerm_subnet.aks.id

    auto_scaling_enabled = true

    min_count = 1

    max_count = 3

    node_count = 1

    only_critical_addons_enabled = true

  }

  identity {

    type = "SystemAssigned"

  }

  network_profile {

    network_plugin = "azure"

    network_plugin_mode = "overlay"

    load_balancer_sku = "standard"

    service_cidr = "10.10.0.0/16"

    dns_service_ip = "10.10.0.10"

  }

}
```

---

# 20. Application Node Pool

```hcl
resource "azurerm_kubernetes_cluster_node_pool" "apps" {

  name = "apps"

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id

  vm_size = "Standard_D2s_v5"

  vnet_subnet_id = azurerm_subnet.aks.id

  mode = "User"

  auto_scaling_enabled = true

  min_count = 2

  max_count = 5

  node_count = 2

  node_labels = {

    workload = "application"

  }

}
```

Node architecture:

```text
AKS
 │
 ├── System Pool
 │      └── Kubernetes System Components
 │
 └── Apps Pool
        │
        ├── WebApp Pod
        ├── WebApp Pod
        └── WebApp Pod
```

---

# 21. AKS Access to ACR

```hcl
resource "azurerm_role_assignment" "aks_acr" {

  scope = azurerm_container_registry.acr.id

  role_definition_name = "AcrPull"

  principal_id = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

}
```

---

# 22. Terraform Outputs

```hcl
output "resource_group_name" {

  value = azurerm_resource_group.main.name

}

output "aks_name" {

  value = azurerm_kubernetes_cluster.aks.name

}

output "acr_login_server" {

  value = azurerm_container_registry.acr.login_server

}

output "aks_oidc_issuer_url" {

  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url

}
```

---

# 23. Terraform Deployment

```bash
cd terraform
```

Format:

```bash
terraform fmt -recursive
```

Initialize:

```bash
terraform init
```

Validate:

```bash
terraform validate
```

Plan:

```bash
terraform plan -out=tfplan
```

Apply:

```bash
terraform apply tfplan
```

---

# 24. Verify Infrastructure

```bash
az group show \
  --name rg-aks-production
```

Check AKS:

```bash
az aks list -o table
```

Check ACR:

```bash
az acr list -o table
```

---

# 25. Connect to AKS

```bash
az aks get-credentials \
  --resource-group rg-aks-production \
  --name aks-production \
  --overwrite-existing
```

Check:

```bash
kubectl get nodes
```

---

# 26. Web Application

## `app/index.html`

```html
<!DOCTYPE html>

<html>

<head>

<title>Production AKS Web App</title>

<style>

body {

    font-family: Arial;

    text-align: center;

    margin-top: 100px;

}

h1 {

    color: #0078d4;

}

</style>

</head>

<body>

<h1>Production AKS Deployment</h1>

<h2>Terraform + Docker + ACR + AKS</h2>

<p>Deployed using Azure Pipelines</p>

</body>

</html>
```

---

# 27. NGINX Configuration

## `app/nginx.conf`

```nginx
server {

    listen 80;

    server_name _;

    location / {

        root /usr/share/nginx/html;

        index index.html;

    }

    location /health {

        access_log off;

        return 200 "healthy\n";

        add_header Content-Type text/plain;

    }

}
```

---

# 28. Dockerfile

```dockerfile
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK \
  --interval=30s \
  --timeout=3s \
  CMD wget -q --spider http://localhost/health || exit 1
```

---

# 29. Docker Build

```bash
docker build \
  -t aks-webapp:v1 \
  ./app
```

Run:

```bash
docker run -d \
  --name aks-webapp \
  -p 8080:80 \
  aks-webapp:v1
```

Test:

```bash
curl http://localhost:8080
```

Health:

```bash
curl http://localhost:8080/health
```

---

# 30. Push Image to ACR

Login:

```bash
az acr login \
  --name YOUR-ACR-NAME
```

Get ACR server:

```bash
ACR_SERVER=$(az acr show \
  --name YOUR-ACR-NAME \
  --query loginServer \
  -o tsv)
```

Build:

```bash
docker build \
  -t $ACR_SERVER/webapp:v1 \
  ./app
```

Push:

```bash
docker push \
  $ACR_SERVER/webapp:v1
```

---

# 31. Kubernetes Namespace

## `kubernetes/namespace.yaml`

```yaml
apiVersion: v1

kind: Namespace

metadata:

  name: production
```

---

# 32. Kubernetes Deployment

## `kubernetes/deployment.yaml`

```yaml
apiVersion: apps/v1

kind: Deployment

metadata:

  name: webapp

  namespace: production

spec:

  replicas: 3

  strategy:

    type: RollingUpdate

    rollingUpdate:

      maxUnavailable: 0

      maxSurge: 1

  selector:

    matchLabels:

      app: webapp

  template:

    metadata:

      labels:

        app: webapp

    spec:

      nodeSelector:

        workload: application

      containers:

      - name: webapp

        image: YOUR-ACR.azurecr.io/webapp:v1

        ports:

        - containerPort: 80

        resources:

          requests:

            cpu: "100m"

            memory: "128Mi"

          limits:

            cpu: "500m"

            memory: "256Mi"

        readinessProbe:

          httpGet:

            path: /health

            port: 80

          initialDelaySeconds: 5

          periodSeconds: 10

        livenessProbe:

          httpGet:

            path: /health

            port: 80

          initialDelaySeconds: 15

          periodSeconds: 20
```

---

# 33. Kubernetes Service

## `kubernetes/service.yaml`

```yaml
apiVersion: v1

kind: Service

metadata:

  name: webapp-service

  namespace: production

spec:

  type: LoadBalancer

  selector:

    app: webapp

  ports:

  - protocol: TCP

    port: 80

    targetPort: 80
```

---

# 34. Horizontal Pod Autoscaler

## `kubernetes/hpa.yaml`

```yaml
apiVersion: autoscaling/v2

kind: HorizontalPodAutoscaler

metadata:

  name: webapp-hpa

  namespace: production

spec:

  scaleTargetRef:

    apiVersion: apps/v1

    kind: Deployment

    name: webapp

  minReplicas: 3

  maxReplicas: 10

  metrics:

  - type: Resource

    resource:

      name: cpu

      target:

        type: Utilization

        averageUtilization: 70
```

---

# 35. Deploy Kubernetes Resources

```bash
kubectl apply -f kubernetes/
```

Check:

```bash
kubectl get all \
  -n production
```

Check HPA:

```bash
kubectl get hpa \
  -n production
```

---

# 36. Azure DevOps Service Connection

Create:

```text
Azure DevOps
      ↓
Project Settings
      ↓
Service Connections
      ↓
Azure Resource Manager
      ↓
Workload Identity Federation
```

Recommended name:

```text
azure-production-connection
```

Prefer workload identity federation instead of storing long-lived Azure client secrets.

---

# 37. Infrastructure Pipeline

## `pipelines/infrastructure.yml`

```yaml
trigger:

  branches:

    include:

    - main

  paths:

    include:

    - terraform/*


pool:

  vmImage: ubuntu-latest


variables:

  terraformDirectory: terraform

  azureServiceConnection: azure-production-connection


stages:


- stage: Validate

  jobs:

  - job: TerraformValidate

    steps:

    - checkout: self


    - script: |

        terraform fmt -check -recursive

      displayName: Terraform Format


    - task: AzureCLI@2

      inputs:

        azureSubscription: $(azureServiceConnection)

        scriptType: bash

        scriptLocation: inlineScript

        inlineScript: |

          cd $(terraformDirectory)

          terraform init

          terraform validate


- stage: Plan

  dependsOn: Validate

  jobs:

  - job: TerraformPlan

    steps:

    - checkout: self


    - task: AzureCLI@2

      inputs:

        azureSubscription: $(azureServiceConnection)

        scriptType: bash

        scriptLocation: inlineScript

        inlineScript: |

          cd $(terraformDirectory)

          terraform init

          terraform plan -out=tfplan


    - publish: $(System.DefaultWorkingDirectory)/terraform/tfplan

      artifact: terraform-plan


- stage: Apply

  dependsOn: Plan

  jobs:

  - deployment: TerraformApply

    environment: production

    strategy:

      runOnce:

        deploy:

          steps:

          - checkout: self


          - download: current

            artifact: terraform-plan


          - task: AzureCLI@2

            inputs:

              azureSubscription: $(azureServiceConnection)

              scriptType: bash

              scriptLocation: inlineScript

              inlineScript: |

                cd $(terraformDirectory)

                terraform init

                cp $(Pipeline.Workspace)/terraform-plan/tfplan .

                terraform apply \
                  -auto-approve \
                  tfplan
```

---

# 38. Infrastructure Pipeline Flow

```text
Git Push
    ↓
Terraform FMT
    ↓
Terraform Validate
    ↓
Terraform Init
    ↓
Terraform Plan
    ↓
Publish Plan Artifact
    ↓
Production Approval
    ↓
Terraform Apply
    ↓
Azure Infrastructure
```

---

# 39. Application Pipeline

## `pipelines/application.yml`

```yaml
trigger:

  branches:

    include:

    - main

  paths:

    include:

    - app/*
    - kubernetes/*


pool:

  vmImage: ubuntu-latest


variables:

  azureServiceConnection: azure-production-connection

  resourceGroup: rg-aks-production

  aksCluster: aks-production

  acrName: YOUR-ACR-NAME

  imageRepository: webapp

  imageTag: $(Build.BuildId)


stages:


- stage: Build

  jobs:

  - job: DockerBuild

    steps:

    - checkout: self


    - task: AzureCLI@2

      inputs:

        azureSubscription: $(azureServiceConnection)

        scriptType: bash

        scriptLocation: inlineScript

        inlineScript: |

          ACR_SERVER=$(az acr show \
            --name $(acrName) \
            --query loginServer \
            -o tsv)

          az acr login \
            --name $(acrName)

          docker build \
            -t $ACR_SERVER/$(imageRepository):$(imageTag) \
            ./app

          docker push \
            $ACR_SERVER/$(imageRepository):$(imageTag)


- stage: Deploy

  dependsOn: Build

  jobs:

  - deployment: DeployAKS

    environment: production

    strategy:

      runOnce:

        deploy:

          steps:

          - checkout: self


          - task: AzureCLI@2

            inputs:

              azureSubscription: $(azureServiceConnection)

              scriptType: bash

              scriptLocation: inlineScript

              inlineScript: |

                az aks get-credentials \
                  --resource-group $(resourceGroup) \
                  --name $(aksCluster) \
                  --overwrite-existing

                ACR_SERVER=$(az acr show \
                  --name $(acrName) \
                  --query loginServer \
                  -o tsv)

                kubectl apply \
                  -f kubernetes/namespace.yaml

                sed \
                  "s|YOUR-ACR.azurecr.io/webapp:v1|$ACR_SERVER/$(imageRepository):$(imageTag)|g" \
                  kubernetes/deployment.yaml \
                  | kubectl apply -f -

                kubectl apply \
                  -f kubernetes/service.yaml

                kubectl apply \
                  -f kubernetes/hpa.yaml

                kubectl rollout status \
                  deployment/webapp \
                  -n production \
                  --timeout=300s
```

---

# 40. Application CI/CD Flow

```text
Developer
    ↓
Git Push
    ↓
Azure Pipeline
    ↓
Docker Build
    ↓
Tag Image
    ↓
Push Image
    ↓
Azure Container Registry
    ↓
Authenticate AKS
    ↓
Kubernetes Deployment
    ↓
Rolling Update
    ↓
Health Check
    ↓
Production Web Application
```

---

# 41. Production Approval

Configure:

```text
Azure DevOps
      ↓
Pipelines
      ↓
Environments
      ↓
production
      ↓
Approvals and Checks
      ↓
Approvals
```

Production workflow:

```text
Plan
 ↓
Review
 ↓
Approval
 ↓
Apply
```

---

# 42. Verification

Check nodes:

```bash
kubectl get nodes -o wide
```

Check pods:

```bash
kubectl get pods \
  -n production \
  -o wide
```

Check services:

```bash
kubectl get svc \
  -n production
```

Check deployment:

```bash
kubectl get deployment \
  -n production
```

Check autoscaling:

```bash
kubectl get hpa \
  -n production
```

Check rollout:

```bash
kubectl rollout status \
  deployment/webapp \
  -n production
```

Check logs:

```bash
kubectl logs \
  -n production \
  deployment/webapp
```

---

# 43. Application Access

Get LoadBalancer IP:

```bash
kubectl get svc \
  webapp-service \
  -n production
```

Flow:

```text
Browser
   ↓
Public IP
   ↓
Azure Load Balancer
   ↓
Kubernetes Service
   ↓
Deployment
   ↓
Pod
   ↓
NGINX
   ↓
Web Application
```

---

# 44. Rolling Deployment

Update application:

```html
<h1>Production AKS Deployment - Version 2</h1>
```

Commit:

```bash
git add .

git commit \
  -m "Release webapp v2"

git push
```

Pipeline:

```text
Version 1
   │
   ▼
Build Version 2
   │
   ▼
Push ACR
   │
   ▼
AKS Rolling Update
   │
   ├── Pod V1
   ├── Pod V1
   └── Pod V1

        ↓

   ├── Pod V2
   ├── Pod V2
   └── Pod V2
```

---

# 45. Scaling Architecture

Two levels of scaling are implemented.

## Pod Scaling

```text
CPU Load ↑
    ↓
HPA
    ↓
3 Pods
    ↓
5 Pods
    ↓
8 Pods
    ↓
Maximum 10 Pods
```

## Node Scaling

```text
Pods cannot schedule
       ↓
Cluster Autoscaler
       ↓
Increase AKS Nodes
       ↓
New Pods Scheduled
```

---

# 46. Security Architecture

```text
Azure Pipelines
       │
       ▼
Workload Identity Federation
       │
       ▼
Azure
       │
       ├── RBAC
       │
       ├── Managed Identity
       │
       ├── AKS
       │
       ├── ACR
       │
       └── Key Vault
```

Important practices:

- No passwords inside Terraform
- No ACR admin account
- Use Managed Identity
- Use RBAC
- Use Workload Identity
- Store application secrets in Key Vault
- Protect Terraform state
- Use production approvals
- Apply least-privilege access
- Avoid committing `.tfvars` containing sensitive information

---

# 47. Production Monitoring

Target monitoring architecture:

```text
AKS
 │
 ├── Nodes
 ├── Pods
 ├── Containers
 └── Applications
       │
       ▼
 Azure Monitor
       │
       ▼
 Log Analytics
       │
       ├── Logs
       ├── Metrics
       ├── Alerts
       └── Dashboards
```

Monitor:

- CPU utilization
- Memory utilization
- Node health
- Pod health
- Restart count
- Failed deployments
- Kubernetes events
- Application logs
- HPA scaling
- Cluster autoscaling

---

# 48. Production Enhancements

For a stricter enterprise implementation, add:

| Area | Enhancement |
|---|---|
| AKS | Private Cluster |
| Network | Private Endpoints |
| Security | Network Policies |
| Registry | Private ACR access |
| Secrets | Key Vault CSI integration |
| Entry Point | Managed Ingress / Application Gateway |
| DNS | Azure DNS |
| Security | HTTPS/TLS |
| Certificates | Automated certificate management |
| Monitoring | Azure Monitor |
| Logs | Log Analytics |
| Security Monitoring | Microsoft Defender |
| Deployment | Blue/Green or Canary |
| Reliability | Pod Disruption Budget |
| Availability | Availability Zones |
| Governance | Azure Policy |
| Environments | Dev / Stage / Prod |

---

# 49. Complete Production Architecture

```text
                           USERS
                             │
                             ▼
                         Azure DNS
                             │
                             ▼
                         HTTPS/TLS
                             │
                             ▼
                    Ingress / Gateway
                             │
                             ▼
             ┌────────── Azure VNet ──────────┐
             │                                │
             │          AKS Cluster           │
             │                                │
             │    ┌──────────────────────┐    │
             │    │ System Node Pool     │    │
             │    └──────────────────────┘    │
             │                                │
             │    ┌──────────────────────┐    │
             │    │ Application Pool     │    │
             │    │                      │    │
             │    │ Pod  Pod  Pod        │    │
             │    └──────────────────────┘    │
             │                                │
             └────────────────────────────────┘
                      ▲              │
                      │              ▼
                     ACR         Key Vault
                      ▲
                      │
                Azure Pipelines
                      ▲
                      │
                 Git Repository
```

---

# 50. Project Outcomes

The project demonstrates practical implementation of:

- Azure cloud architecture
- Infrastructure as Code
- Terraform state management
- Azure networking
- Azure Kubernetes Service
- Containerization
- Container registry management
- Kubernetes workload management
- Kubernetes autoscaling
- Azure DevOps CI/CD
- Production approval gates
- Rolling deployments
- Managed identities
- Workload identity
- RBAC
- Application health monitoring
- Production DevOps practices

---

# 51. Resume Project Entry

## Production-Grade Azure AKS Platform | Terraform & Azure DevOps

**Role:** Cloud / DevOps Solutions Architect

**Technologies:** Azure, AKS, ACR, Terraform, Azure Pipelines, Docker, Kubernetes, Azure VNet, Git, Azure Monitor, Log Analytics, Key Vault

### Responsibilities / Achievements

- Designed and implemented a production-grade Azure Kubernetes platform using Terraform Infrastructure as Code.
- Automated provisioning of Azure VNet, subnet, AKS, ACR, node pools, identities, and supporting infrastructure.
- Implemented remote Terraform state management using Azure Storage.
- Designed separate AKS system and application node pools with cluster autoscaling.
- Containerized the web application using Docker and published versioned images to Azure Container Registry.
- Developed Kubernetes Deployments, Services, health probes, resource controls, and Horizontal Pod Autoscaling.
- Implemented automated CI/CD pipelines using Azure Pipelines for infrastructure and application delivery.
- Implemented Terraform validation, plan artifacts, approval gates, and controlled production deployments.
- Configured AKS-to-ACR integration using Azure RBAC and managed identities.
- Applied rolling deployment strategies to reduce application downtime during releases.
- Incorporated Workload Identity, RBAC, Key Vault integration patterns, and least-privilege security practices.
- Designed monitoring and observability using Azure Monitor and Log Analytics.

---

# 52. Resume One-Line Project Summary

**Designed and automated a production-grade Azure AKS platform using Terraform, Docker, ACR, Kubernetes, and Azure Pipelines with autoscaling, rolling deployments, identity-based security, remote state management, monitoring, and controlled CI/CD releases.**

---

# 53. Interview Explanation

When asked **“Explain your AKS project”**, explain the flow:

```text
1. Developer pushes code to Git.

2. Azure Pipeline triggers.

3. Terraform pipeline validates and plans infrastructure.

4. Production approval controls terraform apply.

5. Terraform provisions VNet, ACR and AKS.

6. Docker pipeline builds the application image.

7. Image is versioned and pushed to ACR.

8. AKS pulls the image using managed identity/RBAC.

9. Kubernetes deploys multiple application replicas.

10. Load Balancer/Ingress exposes the application.

11. HPA scales pods according to application load.

12. Cluster Autoscaler increases/decreases AKS nodes.

13. Readiness/liveness probes monitor workload health.

14. Rolling updates provide controlled application releases.

15. Azure Monitor and Log Analytics provide observability.
```

---

# 54. Key Points to Remember

```text
Terraform       → Infrastructure
Docker          → Container
ACR             → Image Registry
AKS             → Kubernetes Platform
Deployment      → Manages Pods
Service         → Exposes Application
HPA             → Scales Pods
Autoscaler      → Scales Nodes
Key Vault       → Secrets
Azure Monitor   → Monitoring
Azure Pipeline  → Automation
Git             → Source Control
```

---

# 55. Final Project Flow

```text
                       DEVELOPER
                           │
                        Git Push
                           │
                           ▼
                     Git Repository
                           │
            ┌──────────────┴──────────────┐
            │                             │
            ▼                             ▼
      TERRAFORM PIPELINE            APP PIPELINE
            │                             │
           FMT                       Docker Build
            │                             │
         Validate                     Image Scan
            │                             │
           Plan                       Push ACR
            │                             │
      Save Artifact                       │
            │                             │
         Approval                         │
            │                             │
           Apply                          │
            │                             │
            ▼                             ▼
     Azure Infrastructure ────────────── AKS
            │                             │
      VNet + ACR + AKS              Deployment
                                          │
                                          ▼
                                        Pods
                                          │
                                          ▼
                                         HPA
                                          │
                                          ▼
                                  Service / Ingress
                                          │
                                          ▼
                                       Web App
```

# Project Result

The final solution provides an end-to-end production-oriented DevOps workflow:

**Git → Azure Pipelines → Terraform → Azure → Docker → ACR → AKS → Kubernetes → Autoscaling → Monitoring → Production Web Application**

The project can be used as a **portfolio project, GitHub project, technical training lab, Azure DevOps/AKS interview project, and resume project**.
