#!/bin/bash

# Configurações
RESOURCE_GROUP="urbangeist-rg"
COSMOSDB_NAME="urbangeist-db"
BD_NAME="urbangeist"

# Obter a connection da conta CosmosDB
CONNECTION_STRING=$(az cosmosdb keys list --name $COSMOSDB_NAME \
                  										    --resource-group $RESOURCE_GROUP \
                  										    --type connection-strings \
                  										    --query "connectionStrings[0].connectionString" \
                  										    --output tsv)

# Inserir dados
mongosh "$CONNECTION_STRING/$DB_NAME" <<EOF
db.tb_categoria.insertMany([
  { "_id": "1", "nome": "Lazer" },
  { "_id": "2", "nome": "Eventos" },
  { "_id": "3", "nome": "Cultura" },
  { "_id": "4", "nome": "Natureza" },
  { "_id": "5", "nome": "Culinária" }
]);

EOF

echo "Dados inseridos com sucesso!"
