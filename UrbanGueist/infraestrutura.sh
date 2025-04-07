#!/bin/bash

#Variaveis
RESOURCE_GROUP="urbangeist-rg"
LOCATION="francecentral"
APP_NAME="urbangeist-app"
COSMOSDB_NAME="urbangeist-db"
BD_NAME="urbangeist"
STORAGE_ACCOUNT="urbangeiststorage"
FUNCTION_APP="urbangeist-function"

#Criar Resource Group
az group create --name $RESOURCE_GROUP \
                --location $LOCATION

#Criar App Service Plan
az appservice plan create --name $APP_NAME-plan \
                          --resource-group $RESOURCE_GROUP \
                          --sku B1 \
                          --location $LOCATION

#Criar App Service + container
az webapp create --resource-group $RESOURCE_GROUP \
                 --plan $APP_NAME-plan \
                 --name $APP_NAME \
                 --runtime "NODE|16LTS"

#Criar conta CosmosDB + Base de Dados
az cosmosdb create --name $COSMOSDB_NAME \
                   --resource-group $RESOURCE_GROUP \
                   --kind MongoDB
				   
az cosmosdb mongodb database create --account-name $COSMOSDB_NAME \
				    --name $BD_NAME \
				    --resource-group $RESOURCE_GROUP
									

#Criar as Tabelas	
COLLECTIONS=("tb_utilizador" "tb_review" "tb_categoria" "tb_preferencias" "tb_user_action")

for c in "${COLLECTIONS[@]}"; do
	az cosmosdb mongodb collection create --account-name $COSMOSDB_NAME \
					      --database-name $BD_NAME \
					      --name $c \
					      --resource-group $RESOURCE_GROUP \
					      --throughput 400
done

az cosmosdb mongodb collection create --account-name $COSMOSDB_NAME \
				      --database-name $BD_NAME \
                                      --name tb_local \
                                      --idx '[{"key": {"keys": ["_id"]}}, {"key": {"keys": ["coords"], "options": {"2dsphereIndexVersion": 3}}}]' \
				      --resource-group $RESOURCE_GROUP \
				      --throughput 400  
									  
: '			
az cosmosdb mongodb collection create --account-name $COSMOSDB_NAME \
									  --database-name $BD_NAME \
									  --name tb_utilizador \
									  --resource-group $RESOURCE_GROUP \
									  --throughput 400
									  
az cosmosdb mongodb collection create --account-name $COSMOSDB_NAME \
									  --database-name $BD_NAME \
									  --name tb_local \
									  --resource-group $RESOURCE_GROUP \
									  --throughput 400
									  
az cosmosdb mongodb collection create --account-name $COSMOSDB_NAME \
									  --database-name $BD_NAME \
									  --name tb_review \
									  --resource-group $RESOURCE_GROUP \
									  --throughput 400	
									  
az cosmosdb mongodb collection create --account-name $COSMOSDB_NAME \
									  --database-name $BD_NAME \
									  --name tb_categoria \
									  --resource-group $RESOURCE_GROUP \
									  --throughput 400
'
#-----------------------------------------------------------------------------


#Criar Storage Account
az storage account create --name $STORAGE_ACCOUNT \
                          --resource-group $RESOURCE_GROUP \
                          --sku Standard_LRS

#Criar Azure Function
az functionapp create --resource-group $RESOURCE_GROUP \
                      --consumption-plan-location $LOCATION \
                      --name $FUNCTION_APP \
                      --storage-account $STORAGE_ACCOUNT \
                      --runtime node \
                      --functions-version 4

#Configurar GitHub
az webapp deployment source config --name $APP_NAME \
                                   --resource-group $RESOURCE_GROUP \
                                   --repo-url https://github.com/JoseAgostinho/UrbanG.git \
                                   --branch master \
                                   --repository-type github
								   
WEBAPP_URL=$(az webapp show --name $APP_NAME 
			    --resource-group $RESOURCE_GROUP 
			    --query defaultHostName -o tsv)

echo "Infraestrutura criada com sucesso!"
echo "A aplicação está disponível em: https://$WEBAPP_URL"
echo "Para popular a base de dados correr: ./bd.sh"
