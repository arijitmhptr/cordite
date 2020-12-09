# cordite
cordite NMS

We are going to dockerize the PostgreSQL, Cordite NMS and the Corda nodes.We have specified all the configuration in the docker-compose file.

We have created a script which will run the docker-compose file based on some configuration. Please refer to the deploy-cordite.sh script.
This script will spin up all the docker containers one by one.

After the script executed successfully, use the command - docker ps to check all the container. In case of any issue check the container logs
docker logs ccontainer-id

When you are done with the testing, please execute the clean-network.sh script which will bring down the container and clean all the volumes.

There is a folder db-init, where you can place any sql file which will be executed when the postgre container will be up.
