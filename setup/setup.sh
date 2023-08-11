#!/bin/bash

appId=$(az ad app create --display-name $1 | jq '.id')

assigneeObjectId=$(az ad sp create --id $appId)

subscriptionId=$(az account show | jq '.id')

tenantId=$(az account show | jq '.homeTenantId')