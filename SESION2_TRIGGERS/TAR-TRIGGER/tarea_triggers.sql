--TAREA-TRIGGERS O DISPARADORES

/*
Crea un trigger que, después de insertar o actualizar un producto en la tabla inv.producto, 
verifique si el stock actual es menor que el stock mínimo y, si es así, genere una alerta
o notificación.
*/

USE ejercicios;
GO

SELECT * FROM inv.producto;

DROP TRIGGER IF EXISTS trg_alerta_stock_bajo;
GO

CREATE TRIGGER trg_alerta_stock_bajo
ON inv.producto
AFTER INSERT, UPDATE
AS
BEGIN
    DECLARE @producto_id INT;
    DECLARE @stock_actual INT;
    DECLARE @stock_minimo INT;
    DECLARE @nombre_producto VARCHAR(255);

    -- Asumimos que solo se inserta/actualiza un producto a la vez
    SELECT
        @producto_id = producto_id,
        @stock_actual = stock,
        @stock_minimo = stock_minimo,
        @nombre_producto = nombre_producto
    FROM inserted;

    IF @stock_actual IS NOT NULL AND @stock_minimo IS NOT NULL AND @stock_actual < @stock_minimo
    BEGIN
        PRINT 'Alerta, El producto "' + @nombre_producto + '" (ID: ' + CAST(@producto_id AS VARCHAR) + ') tiene un stock por debajo del mínimo.';
    END
END;
GO


UPDATE inv.producto
SET stock = 50
WHERE producto_id = 12; 


SELECT * FROM inv.producto;

/*
Crea un trigger que registre cada vez que se inserta, actualiza o elimina un registro en 
las tablas inv.encabezado_operacion o inv.detalle_operacion en una tabla de auditoría, 
manteniendo un registro histórico de las operaciones realizadas.
*/

SELECT * FROM inv.encabezado_operacion;
SELECT * FROM inv.detalle_operacion ;

CREATE TABLE inv.auditoria_operaciones (
    auditoria_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tabla VARCHAR(50),
    tipo_operacion VARCHAR(10),
    detalle_operacion_id INT,
    fecha_auditoria DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER inv.tr_auditoria_detalle_operacion
ON inv.detalle_operacion
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO inv.auditoria_operaciones (nombre_tabla, tipo_operacion, detalle_operacion_id)
        SELECT 'detalle_operacion', 'INSERT', detalle_operacion_id
        FROM inserted;
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO inv.auditoria_operaciones (nombre_tabla, tipo_operacion, detalle_operacion_id)
        SELECT 'detalle_operacion', 'DELETE', detalle_operacion_id
        FROM deleted;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO inv.auditoria_operaciones (nombre_tabla, tipo_operacion, detalle_operacion_id)
        SELECT 'detalle_operacion', 'UPDATE', detalle_operacion_id
        FROM inserted;
    END
END;
GO

SELECT * FROM inv.detalle_operacion;
SELECT * FROM inv.auditoria_operaciones;


-- Inserta un registro nuevo (ajusta los campos a tu estructura real)
INSERT INTO inv.detalle_operacion (detalle_operacion_id, um_id, cantidad)
VALUES (1, 100, 5);
-- Modifica el registro recién insertado
UPDATE inv.detalle_operacion
SET cantidad = 10
WHERE detalle_operacion_id = 1;
-- Elimina el registro
DELETE FROM inv.detalle_operacion
WHERE detalle_operacion_id = 1;


SELECT * FROM inv.auditoria_operaciones
WHERE tipo_operacion = 'UPDATE';


/*
Crea un trigger que, antes de insertar un registro en la tabla inv.detalle_operacion, verifique
si la cantidad solicitada de un producto está disponible en el stock y, si no lo está, evite 
la inserción y genere un mensaje de error. SOLO SI LA OPERACION ES DE SALIDA.
*/

select * from inv.detalle_operacion;

CREATE TRIGGER trg_verificar_stock
ON inv.detalle_operacion
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @tipo_operacion_id INT,
            @producto_id INT,
            @cantidad INT,
            @stock_actual INT;

    -- Obtener datos del nuevo registro
    SELECT 
        @tipo_operacion_id = tipo_operacion_id,
        @producto_id = producto_id,
        @cantidad = cantidad
    FROM inserted;

    -- Obtener el stock actual del producto
    SELECT 
        @stock_actual = stock 
    FROM inv.producto
    WHERE producto_id = @producto_id;

    -- Verificar si es una operación de salida (por ejemplo, tipo_operacion_id = 2)
    IF @tipo_operacion_id = 2 AND @cantidad > @stock_actual
    BEGIN
        RAISERROR('No hay suficiente stock para esta operación de salida.', 16, 1);
        RETURN;
    END

    -- Si pasa la validación, insertar el registro
    INSERT INTO inv.detalle_operacion (
        tipo_operacion_id,
        producto_id,
        cantidad,
        fecha,
        numero_de_documento,
        fecha_de_documento,
        comentario,
        creado_en,
        actualizado_en
    )
    SELECT 
        tipo_operacion_id,
        producto_id,
        cantidad,
        fecha,
        numero_de_documento,
        fecha_de_documento,
        comentario,
        creado_en,
        actualizado_en
    FROM inserted;
END;

-- Inserta un producto con 10 en stock
INSERT INTO inv.producto (producto_id, nombre, stock)
VALUES (1, 'Producto de prueba', 10);

SELECT * FROM inv.detalle_operacion;




