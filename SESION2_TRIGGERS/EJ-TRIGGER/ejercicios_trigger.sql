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

 SELECT * FROM inv.producto;

 --REFERENCIA

 CREATE SCHEMA system_logs
GO

DROP TABLE system_logs.logs_insercion

DROP SCHEMA system_logs;

CREATE SCHEMA system_logs;

CREATE TABLE system_logs.insercion (
fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
registro VARCHAR (MAX)
)
GO

CREATE TRIGGER inv.tgr_insersion_categoria ON inv.categoria
AFTER INSERT AS
BEGIN
INSERT INTO system_logs.insercion (registro)
SELECT
CONCAT('Se agego una nueva categoria con el ID:', categoria_id, 'y la descripcion: ', categoria) AS registro
FROM inserted
END
GO

SELECT * FROM inv.categoria

INSERT INTO inv.categoria (categoria)
VALUES ('Productos Varios')

SELECT * FROM system_logs.insercion;

ALTER TABLE system_logs.insercion
ADD usuarios VARCHAR (100 ) default ORIGINAL_LOGIN()
GO

INSERT INTO inv.categoria (categoria)
VALUES ('Descuentos Verano')
GO

--EJERCICIO APLICADO

-- EJERCICIO TRIGGERS PARA inv.producto
-- Seleccionamos la base de datos
USE ejercicios;
GO

CREATE SCHEMA system_logs;
GO

-- TABLA DE INSERSIONES
CREATE TABLE system_logs.inserciones (
fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
usuario VARCHAR(100),
registros VARCHAR(MAX)
);


-- TABLA DE MODIFICACIONES
CREATE TABLE system_logs.modificaciones (
fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
usuario VARCHAR(100),
registros VARCHAR(MAX),
registros_anteriores VARCHAR(MAX)
);


-- TRIGGER DE INSERCIÓN
DROP TRIGGER IF EXISTS inv.tgr_insercion_producto;
GO

CREATE TRIGGER inv.tgr_insercion_producto
ON inv.producto
AFTER INSERT
AS
BEGIN
    INSERT INTO system_logs.inserciones (fecha_creacion, usuario, registros)
    SELECT 
        GETDATE(),
        ORIGINAL_LOGIN(),
        'Se agregó un nuevo producto con ID: ' + CAST(producto_id AS VARCHAR) +
        ', Nombre: ' + nombre_producto +
        ', Precio: ' + CAST(precio_unitario_entrega AS VARCHAR) +
        ', Categoría ID: ' + CAST(categoria_id AS VARCHAR)
    FROM inserted;
END
GO

-- TRIGGER DE ACTUALIZACIÓN
DROP TRIGGER IF EXISTS inv.tgr_actualizacion_producto;
GO

CREATE TRIGGER inv.tgr_actualizacion_producto
ON inv.producto
AFTER UPDATE
AS
BEGIN
    INSERT INTO system_logs.modificaciones (fecha_creacion, usuario, registros, registros_anteriores)
    SELECT 
        GETDATE(),
        ORIGINAL_LOGIN(),
        'Producto ID: ' + CAST(i.producto_id AS VARCHAR) +
        ', Nuevo Nombre: ' + i.nombre_producto +
        ', Nuevo Precio: ' + CAST(i.precio_unitario_entrega AS VARCHAR) +
        ', Nueva Categoría ID: ' + CAST(i.categoria_id AS VARCHAR),
        
        'Producto ID: ' + CAST(d.producto_id AS VARCHAR) +
        ', Nombre Anterior: ' + d.nombre_producto +
        ', Precio Anterior: ' + CAST(d.precio_unitario_entrega AS VARCHAR) +
        ', Categoría Anterior: ' + CAST(d.categoria_id AS VARCHAR)
    FROM inserted i, deleted d
    WHERE i.producto_id = d.producto_id;
END
GO

--Verificar
SELECT * FROM inv.producto;
SELECT * FROM system_logs.inserciones;
SELECT * FROM system_logs.modificaciones;

INSERT INTO inv.producto (codigo_de_barras, nombre_producto, descripcion, categoria_id, marca_id, tipo_producto_id, um_recepcion_id, um_entrega_id, precio_unitario_entrega, stock, stock_minimo, stock_maximo, servicio, disponible_en_pos, url_de_imagen, url_de_miniatura_de_imagen
) VALUES ('9876543210050', 'Prueba Trigger', 'Producto de prueba para inserción', 1, 1, 1, 1, 1, 100.00, 50, 10, 100, 0, 1, 'http://ejemplo.com/img.jpg', 'http://ejemplo.com/mini.jpg');


SELECT * FROM system_logs.inserciones;

UPDATE inv.producto SET nombre_producto = 'Trigger Actualizado', precio_unitario_entrega = 150.00,
categoria_id = 2 WHERE producto_id = 1;

SELECT * FROM system_logs.modificaciones;
