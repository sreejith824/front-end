RESOURCE_GROUP="socksshop-rg"
AKS_CLUSTER_NAME="socksshop-aks"
ACR_NAME="socksshopacr"
ACR_SP="socksshopacr-push-service-principal"
ACR_HELM_SP="socksshopacr-helm-push-service-principal"
AKS_SP="socksshop-aks-sp"
REGION="eastus"
AKS_ROLE="contributor"


#Create RG
RG_REGISTRY_ID=$(az group create --name $RESOURCE_GROUP --location $REGION --query id --output tsv)

#Create AKS Cluster
az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count 1 --enable-addons monitoring --generate-ssh-keys --query id --output tsv
# Obtain the full registry ID for subsequent command args
AKS_REGISTRY_ID=$(az aks show --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP --query id --output tsv)

# Run the following line to create an Azure Container Registry if you do not already have one
az acr create -n $ACR_NAME -g $RESOURCE_GROUP --sku basic
# Obtain the full registry ID for subsequent command args
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

# Connect aks with acr
#az role assignment create --assignee $CLIENT_ID --role acrpull --scope $ACR_ID
az aks update -n $AKS_CLUSTER_NAME -g $RESOURCE_GROUP --attach-acr $ACR_NAME
echo "======================================================================="
#service principal for ACR push
az ad sp delete --id http://$ACR_SP
ACR_SP_AZ_CRED=$(az ad sp create-for-rbac --name http://$ACR_SP --scopes $ACR_REGISTRY_ID --role acrpush --sdk-auth --output json)
echo "Secret for for ACR image push : $ACR_SP_AZ_CRED"

#service principal for ACR Helm push
az ad sp delete --id http://$ACR_HELM_SP
ACR_HELM_SP_AZ_CRED=$(az ad sp create-for-rbac --name http://$ACR_HELM_SP --scopes $ACR_REGISTRY_ID --role acrpush --sdk-auth --output json)
echo "Secret for for ACR Helm package push : $ACR_HELM_SP_AZ_CRED"

#service principal for AKS deployment
az ad sp delete --id http://$AKS_SP
AKS_SP_AZ_CRED=$(az ad sp create-for-rbac --name http://$AKS_SP --scopes $RG_REGISTRY_ID --role $AKS_ROLE  --sdk-auth --output json)
echo "Secret for for AKS deployment : $AKS_SP_AZ_CRED"
echo "======================================================================="