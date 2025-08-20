-- TAREA: Administración de permisos en BD
/*
Utilizando la base de datos company_db

Crear tres usuarios en la base de datos company_db:
admin_user: debe tener control total sobre la base de datos.
hr_user: debe poder leer y modificar datos en el esquema hr.
finance_user: debe poder leer datos en el esquema finance y realizar inserciones en la tabla finance.expenses, pero no debe tener permisos de modificación en otras tablas del esquema.
Crear los roles necesarios para implementar este esquema de seguridad:
Un rol para administrar el esquema hr.
Un rol para administrar el esquema finance, permitir únicamente la inserción de nuevos registros (INSERT) en la tabla finance.expenses, pero no permitir la modificación (UPDATE) ni eliminación (DELETE) de registros ya existentes.  
Asignar los permisos adecuados a cada rol y asignar los usuarios correspondientes a los roles creados:
Documentar y explicar cómo configuras los roles y permisos, y por qué lo hiciste de esa manera.

Entrega:
Un script SQL completo que implemente el esquema de seguridad descrito.
Un documento explicativo de 1-2 páginas detallando las decisiones tomadas y cómo se cumple el principio de mínimo privilegio.

*/

--CREACION DE USUARIOS A NIVEL DEL SERVIDOR
USE master;
GO

CREATE LOGIN admin_login WITH PASSWORD = 'StrongPassAdmin123!';
GO
CREATE LOGIN hr_login WITH PASSWORD = 'StrongPassHR123!';
GO
CREATE LOGIN finance_login WITH PASSWORD = 'StrongPassFin123!';
GO

--CREACION DE USUARIOS EN LA BD DE COMPANY
USE company_db;
GO

CREATE USER admin_user FOR LOGIN admin_login;
GO
CREATE USER hr_user FOR LOGIN hr_login;
GO
CREATE USER finance_user FOR LOGIN finance_login;
GO

--CREACION DE LOS ROLES
CREATE ROLE hr_role;
GO
CREATE ROLE finance_role;
GO

--ASIGNACION DE PERMISOS DE LOS ROLES
ALTER ROLE db_owner ADD MEMBER admin_user;
GO
GRANT SELECT, INSERT, UPDATE ON SCHEMA::hr TO hr_role;
GO
GRANT SELECT ON SCHEMA::finance TO finance_role;
GO
GRANT INSERT ON finance.expenses TO finance_role;
GO
DENY UPDATE, DELETE ON finance.expenses TO finance_role;
GO

--ASIGNACION DE USUARIOS A ROLES
ALTER ROLE hr_role ADD MEMBER hr_user;
GO

ALTER ROLE finance_role ADD MEMBER finance_user;
GO


--VERIFICACION
-- Admin_user
EXECUTE AS USER = 'admin_user';
SELECT * FROM hr.employees;   -- Debe funcionar
INSERT INTO finance.expenses (description, amount, expense_date) 
VALUES ('Test Admin Insert',250.00,' 2023-09-20'); 

REVERT;
GO

-- Hr_user 
EXECUTE AS USER = 'hr_user';
SELECT * FROM hr.employees;  
INSERT INTO hr.employees (first_name,last_name,email,hire_date, job_title) 
VALUES ('Lizzy','Lucas','lizzy@gmail.com','2019-03-22','IT'); 

SELECT * FROM finance.expenses; 
REVERT;
GO

-- Finance_user
EXECUTE AS USER = 'finance_user';
SELECT * FROM finance.expenses; 
INSERT INTO finance.expenses (description, amount, expense_date) 
VALUES ('QA Analyst',780.00,' 2021-09-20');  

UPDATE finance.expenses SET amount = 780 WHERE id = 2;
DELETE FROM finance.expenses WHERE id = 2;
REVERT;
GO
