--EJERCICIO-TRIGGERS

/*Usando como referencia el trigger inv.tgr_insercion_categoria, deberás crear adicionales sobre la 
tabla inv.producto, uno para el evento INSERT y otro para UPDATE, cumpliendo con los siguientes 
requisitos:  

Requisitos funcionales
-Registrar el usuario que ejecuta la acción, utilizando la función ORIGINAL_LOGIN().
-Registrar la fecha y hora exactas de la operación, con GETDATE().
-Para el trigger de inserción (AFTER INSERT): Guardar el contenido de cada fila insertada en una 
 sola columna registros.
-Para el trigger de modificación (AFTER UPDATE):
-Guardar los valores nuevos en la columna registros.
-Guardar los valores antiguos en la columna registros_anteriores, accediendo a la tabla lógica 
 deleted.

Requisitos técnicos
-Crear si no existe una tabla system_logs.inserciones para registrar eventos de inserción.
-Crear si no existe una  tabla system_logs.modificaciones  para registrar eventos de actualización.
-La tabla system_logs.modificaciones  debe incluir la columna registros_anteriores para almacenar 
 los registros que existian antes de que se ejecutara la actualización*/

 USE ejercicios;
 GO

 -- Crear tabla para inserciones
IF OBJECT_ID('system_logs.inserciones') IS NULL
BEGIN
    CREATE TABLE system_logs.inserciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        usuario VARCHAR(100),
        fecha DATETIME,
        registros VARCHAR(MAX)
    );
END;

-- Crear tabla para modificaciones
IF OBJECT_ID('system_logs.modificaciones') IS NULL
BEGIN
    CREATE TABLE system_logs.modificaciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        usuario VARCHAR(100),
        fecha DATETIME,
        registros_anteriores VARCHAR(MAX),
        registros VARCHAR(MAX)
    );
END;



CREATE TRIGGER inv.tgr_insercion_producto
ON inv.producto
AFTER INSERT
AS
BEGIN
    INSERT INTO system_logs.inserciones (usuario, fecha, registros)
    SELECT 
        ORIGINAL_LOGIN(),
        GETDATE(),
        CONCAT(
            'Producto insertado - ID: ', producto_id,
            ', Descripción: ', producto,
            ', Marca ID: ', marca_id,
            ', Categoría ID: ', categoria_id,
            ', Precio: ', precio,
            ', Stock: ', stock
        )
    FROM inserted;
END;
GO

CREATE TRIGGER inv.tgr_actualizacion_producto
ON inv.producto
AFTER UPDATE
AS
BEGIN
    INSERT INTO system_logs.modificaciones (usuario, fecha, registros_anteriores, registros)
    SELECT 
        ORIGINAL_LOGIN(),
        GETDATE(),
        CONCAT(
            'Antes - ID: ', d.producto_id,
            ', Descripción: ', d.producto,
            ', Marca ID: ', d.marca_id,
            ', Categoría ID: ', d.categoria_id,
            ', Precio: ', d.precio,
            ', Stock: ', d.stock
        ),
        CONCAT(
            'Después - ID: ', i.producto_id,
            ', Descripción: ', i.producto,
            ', Marca ID: ', i.marca_id,
            ', Categoría ID: ', i.categoria_id,
            ', Precio: ', i.precio,
            ', Stock: ', i.stock
        )
    FROM inserted i
    JOIN deleted d ON i.producto_id = d.producto_id;
END;
GO


