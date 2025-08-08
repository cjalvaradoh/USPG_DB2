/* TAREA- PROCEDIMIENTOS ALMACENADOS
Crear un procedimiento almacenado que inserte un nuevo cliente en la tabla [cli].[clientes] y su tarjeta
de crédito asociada en la tabla [cli].[tarjetas_credito]

Crear el procedimiento almacenado sp_insertar_cliente_y_tarjeta.
El procedimiento debe aceptar los siguientes parámetros de entrada:
@nombre (varchar(50))
@apellido (varchar(50))
@correoElectronico (varchar(100))
@contrasena (nvarchar(128))
@direccion (varchar(255))
@telefono (varchar(15))
@numeroTarjeta (nvarchar(50))
@fechaVencimiento (date)
@cvv (nvarchar(10))

Utilizar una transacción para asegurarse de que ambas inserciones (cliente y tarjeta de crédito) se
realicen correctamente.
*/

USE Ecommerce;
GO

SELECT * FROM cli.clientes;
SELECT * FROM cli.clientes;

USE [Ecommerce]
GO
--PRUEBA: DROP PROCEDURE cli.sp_insertar_cliente_y_tarjeta;

CREATE PROCEDURE [cli].[sp_insertar_cliente_y_tarjeta]
    @nombre            VARCHAR(50),
    @apellido          VARCHAR(50),
    @correoElectronico VARCHAR(100),
    @contrasena        NVARCHAR(128),
    @direccion         VARCHAR(255),
    @telefono          VARCHAR(15),
    @numeroTarjeta     NVARCHAR(50),
    @fechaVencimiento  DATE,
    @cvv               NVARCHAR(10)
AS
BEGIN
    BEGIN TRANSACTION;

    INSERT INTO [cli].[clientes] (nombre, apellido, correo_electronico, contrasena, direccion, telefono)
    VALUES (@nombre, @apellido, @correoElectronico, @contrasena, @direccion, @telefono);

    DECLARE @cliente_id INT = SCOPE_IDENTITY();

    INSERT INTO [cli].[tarjetas_credito] (cliente_id, numero_tarjeta, fecha_vencimiento, cvv)
    VALUES (@cliente_id, @numeroTarjeta, @fechaVencimiento, @cvv);

    COMMIT TRANSACTION;
END
GO

EXEC [cli].[sp_insertar_cliente_y_tarjeta] @nombre = 'Juan', @apellido = 'Pérez', @correoElectronico = 'juan.perez@example.com',
@contrasena = N'123456', @direccion = 'Calle Falsa 123', @telefono = '555123456', @numeroTarjeta = N'4111111111111111',
@fechaVencimiento = '2026-12-31',@cvv = N'123';

SELECT * FROM cli.clientes WHERE nombre = 'Juan';
SELECT * FROM cli.tarjetas_credito WHERE cliente_id= 1001;
