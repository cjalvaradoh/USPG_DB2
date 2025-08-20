/*
Creación y Gestión de Usuarios y Roles
Crear un login en SQL Server llamado dev_login con la siguiente contraseña: SecurePass123!
Crear un usuario en la base de datos ecommerce asociado a ese login. El nombre del usuario será dev_user
Crear un rol personalizado en la base de datos ecommerce llamado reporting_role.
Asignar al rol reporting_role permisos para SELECT en todas las tablas del esquema cli.
Agregar al usuario dev_user al rol reporting_role.
Verificar los permisos del usuario dev_user al intentar realizar consultas SELECT en las tablas cli.clientes y sell.detalle_ventas.
Documentar el resultado y explicar por qué el usuario pudo o no pudo realizar la consulta.
*/

-- Crear login
USE master;
GO

CREATE LOGIN dev_login WITH PASSWORD = 'SecurePass123!';
GO

-- Crear usuario en la base de datos ecommerce
USE ecommerce;
GO

CREATE USER dev_user FOR LOGIN dev_login;
GO

-- Crear rol
CREATE ROLE reporting_role;
GO

-- Dar permisos SELECT sobre el esquema cli
GRANT SELECT ON SCHEMA::cli TO reporting_role;
GO

-- Agregar usuario al rol
ALTER ROLE reporting_role ADD MEMBER dev_user;
GO

-- Verificar permisos
EXECUTE AS USER = 'dev_user';
SELECT * FROM cli.clientes;       
SELECT * FROM sell.detalle_ventas; 
