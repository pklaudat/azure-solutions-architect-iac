# Azure Solutions Architect Iac Modules for Training

## Overview
This repository contains core Azure Bicep/Terraform Modules modules designed for training resources in the Solutions Architect learning path. The modules help to spin up enterprise-grade labs on Azure, enabling hands-on experience with Infrastructure as Code (IaC) using Bicep.

Each folder represents an automation unit, containing Bicep templates and associated parameter files. Deployments are managed using a `Makefile`, which provides a structured approach to provisioning and deleting resources.

## Repository Structure
```
├── network-landing-zone/             # Network landing zone automation (basic structure with bastion host to allow test privatelink and forced tunneling in the firewall scenarios)
├── k8s-cluster/         # AKS landing zone automation
├── k8s-cluster-on-vm/   # Kubernetes Cluster hosted on VM landing zone automation
├── enterprise-web-app/  # Enterprise Web App automation
├── parameter-store/     # Parameter Store for all the automations
├── Makefile             # Deployment automation commands
├── README.md            # Documentation
```

## Prerequisites
Before deploying any resources, ensure you have the following:
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- [Bicep CLI](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) installed
- [Make](https://www.gnu.org/software/make/) installed for executing commands

## Deployment Instructions
Use the `Makefile` to deploy or remove resources. Available targets:

### Deploy Resources
```sh
make network        # Deploy the network landing zone
make k8s-cluster-on-vm         # Deploy the Kubernetes and VM landing zone
make app # Deploy enterprise web app automation
```

### Delete Resources
```sh
make delete         # Delete all landing zones
make delete-network # Delete the network landing zone
make delete-app     # Delete the app landing zone
make delete-k8s-vm  # Delete the Kubernetes and VM landing zone
```

## Parameter Management
Bicep parameter files are stored in the `parameter-store` directory. Modify these files to customize deployments.

## Contributing
Contributions are welcome! Please ensure any updates align with best practices and maintain consistency across modules.


