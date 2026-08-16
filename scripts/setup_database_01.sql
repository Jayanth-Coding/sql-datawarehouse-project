/*
This script will create the required medallion structure schemas in the new database called DataWareHouse
*/
USE master;

CREATE DATABASE DataWareHouse;
GO 
  
USE Datawarehouse;
GO
  
CREATE SCHEMA bronze; 
GO
CREATE SCHEMA silver; 
GO
CREATE SCHEMA gold;
GO
