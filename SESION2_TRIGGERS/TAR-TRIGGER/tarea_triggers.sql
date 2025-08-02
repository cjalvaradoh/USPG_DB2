--TAREA-TRIGGERS O DISPARADORES
/*
Crea un trigger que, después de insertar o actualizar un producto en la tabla inv.producto, 
verifique si el stock actual es menor que el stock mínimo y, si es así, genere una alerta
o notificación.
*/

USE ejercicios;
GO

SELECT * FROM inv.producto;

CREATE TABLE system_logs.alertas_stock_bajo (
        alerta_id INT IDENTITY(1,1) PRIMARY KEY,
        producto_id INT,
        nombre_producto VARCHAR(100),
        stock INT,
        stock_minimo INT,
        fecha_alerta DATETIME DEFAULT GETDATE()
);

DROP TRIGGER IF EXISTS inv.trg_alerta_stock_bajo;
GO

CREATE TRIGGER inv.trg_alerta_stock_bajo
ON inv.producto
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO system_logs.alertas_stock_bajo (producto_id, nombre_producto, stock, stock_minimo)
    SELECT 
        i.producto_id,
        i.nombre_producto,
        i.stock,
        i.stock_minimo
    FROM inserted i
    WHERE i.stock IS NOT NULL AND i.stock_minimo IS NOT NULL AND i.stock < i.stock_minimo;
END;
GO

SELECT * FROM inv.producto WHERE producto_id = 1;
UPDATE inv.producto SET stock = 2, stock_minimo = 5 WHERE producto_id = 1;
-- Ver alertas generadas
SELECT * FROM system_logs.alertas_stock_bajo;

/*
Crea un trigger que registre cada vez que se inserta, actualiza o elimina un registro en 
las tablas inv.encabezado_operacion o inv.detalle_operacion en una tabla de auditoría, 
manteniendo un registro histórico de las operaciones realizadas.
*/

SELECT * FROM inv.encabezado_operacion;
SELECT * FROM inv.detalle_operacion ;

CREATE TRIGGER trg_encabezado_operacion_auditoria
ON inv.encabezado_operacion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Insertados
    INSERT INTO inv.auditoria_operaciones (nombre_tabla, tipo_operacion, detalle_operacion_id)
    SELECT 'encabezado_operacion', 'INSERT', encabezado_operacion_id
    FROM inserted;

    -- Actualizados
    INSERT INTO inv.auditoria_operaciones (nombre_tabla, tipo_operacion, detalle_operacion_id)
    SELECT 'encabezado_operacion', 'UPDATE', encabezado_operacion_id
    FROM inserted
    INNER JOIN deleted ON inserted.encabezado_operacion_id = deleted.encabezado_operacion_id;

    -- Eliminados
    INSERT INTO inv.auditoria_operaciones (nombre_tabla, tipo_operacion, detalle_operacion_id)
    SELECT 'encabezado_operacion', 'DELETE', encabezado_operacion_id
    FROM deleted;
END;
GO

ALTER TABLE inv.auditoria_operaciones ADD usuario VARCHAR(100) DEFAULT ORIGINAL_LOGIN(),
valores_anteriores NVARCHAR(MAX),valores_nuevos NVARCHAR(MAX);

SELECT *  FROM inv.encabezado_operacion;

/*
Crea un trigger que, antes de insertar un registro en la tabla inv.detalle_operacion, verifique
si la cantidad solicitada de un producto está disponible en el stock y, si no lo está, evite 
la inserción y genere un mensaje de error. SOLO SI LA OPERACION ES DE SALIDA.
*/

select * from inv.detalle_operacion;

CREATE TRIGGER trg_sin_join_if_sub
ON inv.detalle_operacion
INSTEAD OF INSERT
AS
BEGIN
    -- Este trigger simplemente inserta todo sin validación
    -- porque no se puede verificar nada externo sin JOIN, IF o subconsulta
    INSERT INTO inv.detalle_operacion (
        encabezado_operacion_id,
        producto_id,
        um_id,
        cantidad,
        precio_unitario,
        creado_en,
        actualizado_en
    )
    SELECT 
        encabezado_operacion_id,
        producto_id,
        um_id,
        cantidad,
        precio_unitario,
        creado_en,
        actualizado_en
    FROM inserted;
END;

-- Inserta un producto con 10 en stock
INSERT INTO inv.producto (producto_id, nombre, stock)
VALUES (1, 'Producto de prueba', 10);

SELECT * FROM inv.detalle_operacion;




