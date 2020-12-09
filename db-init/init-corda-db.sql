/**
The following sets up the databases required by each corda network in the docker-compose test cluster
*/
DROP DATABASE IF EXISTS notary;
DROP DATABASE IF EXISTS manufacturer;
DROP DATABASE IF EXISTS distributer;
DROP DATABASE IF EXISTS retailer;
CREATE DATABASE notary;
CREATE DATABASE manufacturer;
CREATE DATABASE distributer;
CREATE DATABASE retailer;
