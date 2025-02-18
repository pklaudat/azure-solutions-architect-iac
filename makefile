# Deploy commands for each landing zone
network:
	az stack sub create --name network-landing-zone \
	--template-file network-landing-zone/main.bicep \
	--parameters parameter-store/network-landing-zone.bicepparam \
	--location CentralUs --deny-settings-mode None

app:
	az stack sub create --name enterprise-web-app \
	--template-file enterprise-web-app/main.bicep \
	--parameters parameter-store/enterprise-web-app.bicepparam \
	--location CentralUs --deny-settings-mode None

k8s:
	az stack sub create --name enterprise-aks-cluster \
	--template-file enterprise-aks-cluster/main.bicep \
	--parameters parameter-store/enterprise-aks-cluster.bicepparam \
	--location CentralUs --deny-settings-mode None

k8s-vm:
	az stack sub create --name k8s-cluster-on-vm \
	--template-file k8s-cluster-on-vm/main.bicep \
	--parameters parameter-store/k8s-cluster-on-vm.bicepparam \
	--location CentralUs --deny-settings-mode None

# Delete commands for each landing zone
delete-network:
	az stack sub delete --name network-landing-zone --yes --delete-all --verbose

delete-app:
	az stack sub delete --name enterprise-web-app --yes --delete-all --verbose

delete-k8s:
	az stack sub delete --name enterprise-aks-cluster --yes --delete-all --verbose

delete-k8s-vm:
	az stack sub delete --name k8s-cluster-on-vm --yes --delete-all --verbose

# Delete all landing zones
delete:
	make delete-network
	make delete-app
	make delete-k8s
	make delete-k8s-vm

# Help command
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make network        - Deploy the network landing zone"
	@echo "  make app            - Deploy the app landing zone"
	@echo "  make k8s-vm         - Deploy the k8s-vm landing zone"
	@echo "  make delete         - Delete all landing zones"
	@echo "  make delete-network - Delete the network landing zone"
	@echo "  make delete-app     - Delete the app landing zone"
	@echo "  make delete-k8s     - Delete the enterprise aks landing zone"
	@echo "  make delete-k8s-vm  - Delete the k8s-vm landing zone"
