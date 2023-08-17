#!/bin/bash

cat <<EOF
********************************************** WARNING **********************************************
Please install the Azure CLI 2.0
(https://docs.microsoft.com/cli/azure/install-azure-cli) and use these 3 easy commands:

  az login
  az account set --subscription <Subscription ID>
  az ad sp create-for-rbac

By default, the last command creates a Service Principal with the 'Contributor' role scoped to the
current subscription. Pass the '--help' parameter for more info if you want to change the defaults.
********************************************** WARNING **********************************************
EOF


if !(command -v az >/dev/null); then
  echo "ERROR: This script requires Azure CLI 1.0, but it could not be found. Is it installed and on your path?" 1>&2
  exit -1
fi

SUBSCRIPTION_ID=$1

susbcriptions_list=$(az account list --all)
subscriptions_list_count=$(az account list --all | jq '. | length' )

if [[ $subscriptions_list_count -gt "0" ]]; then
    echo "  You are already logged in with an Azure account so we won't ask for credentials again."
    echo "  If you want to select a subscription from a different account, before running this script you should either log out from all the Azure accounts or login manually with the new account."
    echo "  azure login"
    echo ""
else
    az login
fi

if [ -z "$SUBSCRIPTION_ID" ]
then
  #prompt for subscription
  subscription_index=0
  subscriptions_list=$(az account list --all)
  subscriptions_list_count=$(echo $subscriptions_list | jq '. | length')
  if [ $subscriptions_list_count -eq 0 ]
  then
    echo "  You need to sign up an Azure Subscription here: https://azure.microsoft.com"
    exit 1
  elif [ $subscriptions_list_count -gt 1 ]
  then
    echo $subscriptions_list | jq -r 'keys[] as $i | "  \($i+1). \(.[$i] | .name)"'

    while read -r -t 0; do read -r; done #clear stdin
    subscription_idx=0
    until [ $subscription_idx -ge 1 -a $subscription_idx -le $subscriptions_list_count ]
    do
      read -p "  Select a subscription by typing an index number from above list and press [Enter]: " subscription_idx
      if [ $subscription_idx -ne 0 -o $subscription_idx -eq 0 2>/dev/null ]
      then
        :
      else
        subscription_idx=0
      fi
    done
    subscription_index=$((subscription_idx-1))
  fi

  SUBSCRIPTION_ID=`echo $subscriptions_list | jq -r '.['$subscription_index'] | .id'`
  echo ""
fi

az account set --subscription $SUBSCRIPTION_ID >/dev/null
if [ $? -ne 0 ]
then
  exit 1
else
  echo "  Using subscription ID $SUBSCRIPTION_ID"
  echo ""
fi
read -p "Enter a name for the Service Principal App Registration: " MY_APP_NAME
MY_SUBSCRIPTION_ID=$(az account show | jq -r '.id')
MY_TENANT_ID=$(az account show | jq -r '.tenantId')

az account set --subscription $MY_SUBSCRIPTION_ID >/dev/null

my_error_check=$(az ad sp list --display-name $MY_APP_NAME  | grep "displayName" | grep -c \"$MY_APP_NAME\" )

if [ $my_error_check -gt 0 ];
then
  echo "  Found an app id matching the one we are trying to create; we will reuse that instead"
else
  echo "  Creating application in active directory:"
  echo "  az ad app create --display-name '$MY_APP_NAME'"
  az ad app create --display-name $MY_APP_NAME >/dev/null
  if [ $? -ne 0 ]
  then
    exit 1
  fi
  # Give time for operation to complete
  echo "  Waiting for operation to complete...."
  sleep 20
  my_error_check=$(az ad app list --display-name $MY_APP_NAME | grep "displayName" | grep -c \"$MY_APP_NAME\" )

  if [ $my_error_check -gt 0 ];
  then
    my_app_object_id=$(az ad app list --display-name $MY_APP_NAME | jq -r '.[].id')
    MY_CLIENT_ID=$(az ad app list --display-name $MY_APP_NAME | jq -r '.[].appId')
    echo " "
    echo "  Creating the service principal in AD"
    echo "  az ad sp create --id $MY_CLIENT_ID"
    az ad sp create --id $MY_CLIENT_ID >/dev/null
    # Give time for operation to complete
    echo "  Waiting for operation to complete...."
    sleep 20
    my_app_sp_object_id=$(az ad sp list --display-name $MY_APP_NAME | jq -r '.[].id')

    subscriptionId=$(az account show | jq -r '.id' )
    assigneeObjectId=$(az ad sp list --display-name $MY_APP_NAME | jq -r '.[].id')


    echo "  Assign rights to service principle"
    echo "  az role assignment create --role contributor  --subscription $subscriptionId --assignee-object-id $assigneeObjectId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId"
    az role assignment create --role contributor  --subscription $subscriptionId --assignee-object-id $assigneeObjectId --assignee-principal-type ServicePrincipal --scope /subscriptions/$subscriptionId >/dev/null
    if [ $? -ne 0 ]
    then
      exit 1
    fi
  else
    echo " "
    echo "  We've encounter an unexpected error; please hit Ctr-C and retry from the beginning"
    read my_error
  fi
fi

MY_CLIENT_ID=$(az ad sp list --display-name $MY_APP_NAME | jq -r '.[].appId')

echo " Creating federated credentials for GitHub OAuth "
read -p "Enter the GitHub repo you would like to create credentials for. E.G. <repo owner>/<repository name>: " github_repository

json_string=$(
    jq --null-input \
        --arg name "$MY_APP_NAME" \
        --arg subject "$github_repository" \
        '{ name: $name, issuer: "https://token.actions.githubusercontent.com", subject: $subject, description: "Github Actions", audiences: ["api://AzureADTokenExchange"]}'
)

echo $json_string | jq > /tmp/credentials.json
sp_parameters=/tmp/credentials.json

applicationObjectId=$(az ad app list --display-name $MY_APP_NAME | jq -r '.[].id')
echo "Creating federated credentials for app: '$MY_APP_NAME'"
echo " az ad app federated-credential create --id '$applicationObjectId' --parameters $sp_parameters"
az ad app federated-credential create --id $applicationObjectId --parameters $sp_parameters 

echo "Removing credentials.json"
echo "rm '/tmp/credentials.json'"
rm /tmp/credentials.json

clientId=$(az ad app list --display-name $MY_APP_NAME | jq -r '.[].id')
tenantId=$(az account show | jq -r '.tenantId')
subscriptionId=$(az account show | jq -r '.id' )
echo "  "
echo "  Your access credentials ============================="
echo "  "
echo "  In your GitHub repository, add the following secrets"
echo "  Client ID:" $clientId
echo "  Tenant ID:" $tenantId
echo "  Subscription ID:" $subscriptionId
echo "  OAuth 2.0 Token Endpoint:" "https://login.microsoftonline.com/${MY_TENANT_ID}/oauth2/token"
echo "  Tenant ID:" $MY_TENANT_ID
echo "  "
echo "  You can verify the service principal was created properly by running:"
echo "  azure login -u "$MY_CLIENT_ID" --service-principal --tenant $MY_TENANT_ID"
echo "  "