USE Ecommerce;
GO

/*
CASO DE ESTUDIO — Transacciones & Concurrencia (SQL Server)
*/

SET XACT_ABORT ON
GO

 -- 1. Registra una venta con detalle y descuenta stock.
CREATE SCHEMA fraude;
SELECT * FROM sys.schemas WHERE name = 'fraude';

-- Tabla de operaciones antifraude
SELECT * FROM sysobjects WHERE name='operaciones' AND xtype='U';
CREATE TABLE fraude.operaciones (
    operacion_id INT IDENTITY PRIMARY KEY,
    cliente_id INT,
    tarjeta_hash VARBINARY(64), 
    ubicacion NVARCHAR(50),
    ip NVARCHAR(50),
    estado NVARCHAR(20),
    motivo NVARCHAR(100),
    fecha_hora DATETIME2,
    venta_id INT NULL
);

-- Tabla de histórico de precios 
SELECT * FROM sysobjects WHERE name='precio_historial' AND xtype='U';
CREATE TABLE sell.precio_historial (
    historial_id INT IDENTITY PRIMARY KEY,
    producto_id INT,
    precio_anterior DECIMAL(10,2),
    nuevo_precio DECIMAL(10,2),
    motivo NVARCHAR(100),
    fecha_cambio DATETIME2
);

 BEGIN TRY
    BEGIN TRAN;

    DECLARE @clienteId INT = (SELECT TOP 1 cliente_id FROM cli.clientes);
    DECLARE @productoId INT = (SELECT producto_id FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC');
    DECLARE @cantidad INT = 2;
    DECLARE @precio DECIMAL(10,2) = (SELECT precio FROM sell.productos WHERE producto_id = @productoId);

    INSERT INTO sell.ventas (cliente_id, fecha_venta, total_venta)
    VALUES (@clienteId, SYSDATETIME(), @cantidad * @precio);

    DECLARE @ventaId INT = SCOPE_IDENTITY();

    INSERT INTO sell.detalle_ventas (venta_id, producto_id, cantidad, precio_unitario)
    VALUES (@ventaId, @productoId, @cantidad, @precio);

    UPDATE sell.productos
    SET stock = stock - @cantidad
    WHERE producto_id = @productoId;

    COMMIT;
    PRINT 'Venta registrada correctamente. ID: ' + CAST(@ventaId AS VARCHAR);
END TRY
BEGIN CATCH
    ROLLBACK;
    SELECT ERROR_NUMBER() AS num, ERROR_MESSAGE() AS mensaje;
END CATCH;
GO

SELECT TOP 5 * FROM sell.ventas ORDER BY venta_id DESC;
SELECT TOP 5 * FROM sell.detalle_ventas ORDER BY venta_id DESC;

SELECT producto_id, codigo_barras, nombre_producto, stock
FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC';


 -- 2. Si el stock resultante < 10, incrementa el precio en 10% y registra el cambio en un histórico.

BEGIN TRY
  BEGIN TRAN;

  DECLARE @clienteId INT = (SELECT TOP 1 cliente_id FROM cli.clientes);
  DECLARE @productoId INT = (SELECT producto_id FROM sell.productos WHERE codigo_barras='CMKNG-SZCNC');
  DECLARE @cant INT = 5;
  DECLARE @precio DECIMAL(10,2), @stock INT;

  SELECT @precio = precio, @stock = stock FROM sell.productos WHERE producto_id=@productoId;
  IF @stock < @cant THROW 50012, 'Stock insuficiente', 1;

  INSERT INTO sell.ventas(cliente_id,fecha_venta,total_venta)
  VALUES(@clienteId,SYSDATETIME(),@cant*@precio);

  DECLARE @ventaId INT = SCOPE_IDENTITY();

  INSERT INTO sell.detalle_ventas(venta_id,producto_id,cantidad,precio_unitario)
  VALUES(@ventaId,@productoId,@cant,@precio);

  UPDATE sell.productos SET stock = stock-@cant WHERE producto_id=@productoId;
  SET @stock = @stock - @cant;

  IF @stock < 10
  BEGIN
    DECLARE @nuevo DECIMAL(10,2) = ROUND(@precio*1.10,2);
    INSERT INTO sell.precio_historial(producto_id,precio_anterior,nuevo_precio,motivo,fecha_cambio)
    VALUES(@productoId,@precio,@nuevo,'STOCK_BAJO',SYSDATETIME());
    UPDATE sell.productos SET precio=@nuevo WHERE producto_id=@productoId;
  END

  COMMIT;
END TRY
BEGIN CATCH
  ROLLBACK;
  SELECT ERROR_MESSAGE() msg;
END CATCH;
GO

SELECT 
    producto_id,
    codigo_barras,
    precio AS precio_actual,
    stock AS stock_actual
FROM sell.productos;

 -- 3. Evita lecturas sucias y lost updates ante concurrencia.

CREATE INDEX IX_ventas_fecha ON sell.ventas(fecha_venta);
CREATE INDEX IX_operaciones_antifraude ON fraude.operaciones(tarjeta_hash, fecha_hora, ubicacion);

BEGIN TRY
  BEGIN TRAN;

  DECLARE @clienteId INT = (SELECT TOP 1 cliente_id FROM cli.clientes);
  DECLARE @productoId INT = (SELECT producto_id FROM sell.productos WHERE codigo_barras='CMKNG-SZCNC');
  DECLARE @cant INT = 3;
  DECLARE @precio DECIMAL(10,2), @stock INT;

  SELECT @precio = precio, @stock = stock
  FROM sell.productos WITH (UPDLOCK, ROWLOCK)
  WHERE producto_id=@productoId;

  IF @stock < @cant THROW 50012, 'Stock insuficiente', 1;

  INSERT INTO sell.ventas(cliente_id,fecha_venta,total_venta)
  VALUES(@clienteId,SYSDATETIME(),@cant*@precio);

  DECLARE @ventaId INT = SCOPE_IDENTITY();

  INSERT INTO sell.detalle_ventas(venta_id,producto_id,cantidad,precio_unitario)
  VALUES(@ventaId,@productoId,@cant,@precio);

  UPDATE sell.productos SET stock = stock-@cant WHERE producto_id=@productoId;

  COMMIT;
END TRY
BEGIN CATCH
  ROLLBACK;
  SELECT ERROR_MESSAGE() msg;
END CATCH;
GO

-- A 
BEGIN TRAN;
SELECT precio, stock 
FROM sell.productos WITH (UPDLOCK, ROWLOCK) 
WHERE codigo_barras = 'CMKNG-SZCNC';

 -- 4. Detecta y bloquea ráfagas de compras con la misma tarjeta en T minutos desde ubicaciones distintas.

BEGIN TRY
    BEGIN TRAN;

    DECLARE @clienteId INT = 1;
    DECLARE @productoId INT = (SELECT producto_id FROM sell.productos WHERE codigo_barras = 'CMKNG-SZCNC');
    DECLARE @precio DECIMAL(10,2) = (SELECT precio FROM sell.productos WHERE producto_id = @productoId);
    DECLARE @tarjeta_hash VARBINARY(64) = HASHBYTES('SHA2_256', '411111******1111salt');

    -- Verificar antifraude
    IF (SELECT COUNT(DISTINCT ubicacion) FROM fraude.operaciones 
        WHERE tarjeta_hash = @tarjeta_hash 
        AND fecha_hora >= DATEADD(MINUTE, -5, GETDATE())) >= 2
    BEGIN
        INSERT INTO fraude.operaciones(cliente_id, tarjeta_hash, ubicacion, estado, motivo, fecha_hora)
        VALUES(@clienteId, @tarjeta_hash, 'GUA', 'BLOQUEADA', 'Ráfaga de compras', GETDATE());
        ROLLBACK;
        THROW 50001, 'Compra bloqueada: múltiples ubicaciones en 5 minutos', 1;
    END

    -- Procesar venta
    INSERT INTO sell.ventas(cliente_id, fecha_venta, total_venta) VALUES(@clienteId, GETDATE(), @precio);
    DECLARE @ventaId INT = SCOPE_IDENTITY();
    
    INSERT INTO sell.detalle_ventas(venta_id, producto_id, cantidad, precio_unitario) VALUES(@ventaId, @productoId, 1, @precio);
    UPDATE sell.productos SET stock = stock - 1 WHERE producto_id = @productoId;
    INSERT INTO fraude.operaciones(cliente_id, tarjeta_hash, ubicacion, estado, fecha_hora, venta_id) VALUES(@clienteId, @tarjeta_hash, 'GUA', 'APROBADA', GETDATE(), @ventaId);

    COMMIT;
    PRINT 'Venta exitosa. ID: ' + CAST(@ventaId AS VARCHAR);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;