--PRUEBAS
USE Ecommerce;
GO

 -- 1. Registra una venta con detalle y descuenta stock.
SELECT TOP 5 * FROM sell.ventas ORDER BY venta_id DESC;
SELECT TOP 5 * FROM sell.detalle_ventas ORDER BY venta_id DESC;

SELECT producto_id, codigo_barras, nombre_producto, stock
FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC';

 -- 2. Si el stock resultante < 10, incrementa el precio en 10% y registra el cambio en un histórico.
SELECT producto_id, nombre_producto, precio, stock 
FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC';
UPDATE sell.productos SET stock = 14 WHERE codigo_barras = 'CMKNG-SZCNC';

SELECT producto_id, nombre_producto, precio, stock 
FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC';

SELECT * FROM sell.precio_historial ORDER BY fecha_cambio DESC;

-- 3. PRUEBAS Evita lecturas sucias y lost updates ante concurrencia.
/*-- A 
BEGIN TRAN;
SELECT precio, stock 
FROM sell.productos WITH (UPDLOCK, ROWLOCK) 
WHERE codigo_barras = 'CMKNG-SZCNC';*/ 

-- B
BEGIN TRAN;
SELECT precio, stock 
FROM sell.productos WITH (UPDLOCK, ROWLOCK) 
WHERE codigo_barras = 'CMKNG-SZCNC';


-- 4. Detecta y bloquea ráfagas de compras con la misma tarjeta en T minutos desde ubicaciones distintas.

DELETE FROM fraude.operaciones;
DELETE FROM sell.detalle_ventas;
DELETE FROM sell.ventas;

UPDATE sell.productos SET stock = 20 WHERE codigo_barras = 'CMKNG-SZCNC';

DECLARE @tarjeta NVARCHAR(50) = '411111******1111';
DECLARE @tarjeta_hash VARBINARY(64) = HASHBYTES('SHA2_256', @tarjeta + 'salt');

INSERT INTO fraude.operaciones (cliente_id, tarjeta_hash, ubicacion, estado, fecha_hora)
VALUES 
(1, @tarjeta_hash, 'GUA', 'APROBADA', DATEADD(MINUTE, -4, GETDATE())),
(1, @tarjeta_hash, 'LIM', 'APROBADA', DATEADD(MINUTE, -3, GETDATE()));

SELECT 'Ubicaciones distintas en 5 min: ' + 
       CAST(COUNT(DISTINCT ubicacion) AS VARCHAR) + 
       ' (debe ser 2)' AS Resultado
FROM fraude.operaciones 
WHERE tarjeta_hash = @tarjeta_hash 
AND fecha_hora >= DATEADD(MINUTE, -5, GETDATE());


BEGIN TRY
    BEGIN TRAN;
    
    DECLARE @clienteId INT = 1;
    DECLARE @productoId INT = (SELECT producto_id FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC');

    IF (SELECT COUNT(DISTINCT ubicacion) 
        FROM fraude.operaciones 
        WHERE tarjeta_hash = @tarjeta_hash 
        AND fecha_hora >= DATEADD(MINUTE, -5, GETDATE())) >= 2
    BEGIN
        INSERT INTO fraude.operaciones(cliente_id, tarjeta_hash, ubicacion, estado, motivo, fecha_hora)
        VALUES(@clienteId, @tarjeta_hash, 'GUA', 'BLOQUEADA', 'Ráfaga de compras', GETDATE());
        
        ROLLBACK;
        THROW 50001, 'COMPRA BLOQUEADA: Múltiples ubicaciones detectadas', 1;
    END

    INSERT INTO sell.ventas(cliente_id, fecha_venta, total_venta) VALUES(@clienteId, GETDATE(), 100);
    COMMIT;
    PRINT 'Venta exitosa';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    PRINT ERROR_MESSAGE();
END CATCH;


SELECT 
    'Operaciones antifraude: ' + CAST(COUNT(*) AS VARCHAR) AS Resultado,
    'Estado: ' + estado AS Detalle
FROM fraude.operaciones 
GROUP BY estado;

SELECT 'Ventas registradas: ' + CAST(COUNT(*) AS VARCHAR) AS Resultado FROM sell.ventas;