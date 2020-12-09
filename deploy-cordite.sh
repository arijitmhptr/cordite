#!/bin/bash

# Build network environment
# Usage ./deploy.sh
ENVIRONMENT_SLUG=dev
NOTARY=notary
NMS_USER=${1:-admin}
NMS_PASSWORD=${2:-admin}
declare -a nodes=("manufacturer distributer")
declare -a ports=("8081 8082")

echo -e "\xE2\x9C\x94 $(date) Creating environment..."
set -e

# Clean up any old docker-compose
docker-compose -p ${ENVIRONMENT_SLUG} down

# Start NMS (and wait for it to be ready)
docker-compose -p ${ENVIRONMENT_SLUG} up -d network-map
until docker-compose -p ${ENVIRONMENT_SLUG} logs network-map | grep -q "io.cordite.networkmap.NetworkMapApp - started"
do
    echo -e "waiting for network-map to start"
    sleep 5
done

# Start databases
docker-compose -p ${ENVIRONMENT_SLUG} up -d corda-db
until docker-compose -p ${ENVIRONMENT_SLUG} logs corda-db | grep -q "database system is ready to accept connections"
do
echo -e "waiting for corda-db to start up and register..."
sleep 5
done

# Start notaries (and wait for them to be ready)
docker-compose -p ${ENVIRONMENT_SLUG} up -d ${NOTARY}
until docker-compose -p ${ENVIRONMENT_SLUG} logs ${NOTARY} | grep -q "started up and registered"
do
echo -e "waiting for ${NOTARY} to start up and register..."
sleep 5
done

# Pause Notaries but not before downloading their NodeInfo-* and whitelist.txt
NODE_ID=$(docker-compose -p ${ENVIRONMENT_SLUG} ps -q ${NOTARY})
NODEINFO=$(docker exec ${NODE_ID} ls | grep nodeInfo-)
docker cp ${NODE_ID}:/opt/cordite/${NODEINFO} ${NODEINFO}
docker exec ${NODE_ID} rm network-parameters
docker pause ${NODE_ID}

# Login to NMS
echo "Logging in to NMS..."

TOKEN=`curl -X POST "http://localhost:8080//admin/api/login" -H  "accept: text/plain" -H  "Content-Type: application/json" -d "{  \"user\": \"${NMS_USER}\",  \"password\": \"${NMS_PASSWORD}\"}"`

echo $TOKEN

NMS_ID=$(docker-compose -p ${ENVIRONMENT_SLUG} ps -q network-map)
# Copy Notary NodeInfo-* and whitelist.txt to NMS
for NODEINFO in nodeInfo-*
do
    echo "Registering Notary by REST API"
    curl -X POST "http://localhost:8080/admin/api/notaries/nonValidating" -H "accept: text/plain" -H "Content-Type: application/octet-stream" -H "Authorization: Bearer $TOKEN" --data-binary "@${NODEINFO}"
    rm ${NODEINFO}
    echo -e "\xE2\x9C\x94 copied ${NODEINFO} to ${NMS_ID}"
done

# re-start the notaries
docker-compose -p ${ENVIRONMENT_SLUG} restart ${NOTARY}

# start regional nodes (and wait for them to be ready)
for NODE in $nodes
do
    docker-compose -p ${ENVIRONMENT_SLUG} up -d ${NODE}
done
for NODE in $nodes
do
  until docker-compose -p ${ENVIRONMENT_SLUG} logs ${NODE} | grep -q "started up and registered"
  do
    echo -e "waiting for ${NODE} to start up and register..."
    sleep 5
  done
done

# test endpoints
#for PORT in $ports
#do
#    while [[ "$(curl -sSfk -m 5 -o /dev/null -w ''%{http_code}'' http://localhost:${PORT}/api/)" != "200" ]]
#    do
#    echo -e "waiting for ${PORT} to return 200..."
#    sleep 5
#    done
#done

echo -e "\xE2\x9C\x94 $(date) created environment ${ENVIRONMENT_SLUG}"