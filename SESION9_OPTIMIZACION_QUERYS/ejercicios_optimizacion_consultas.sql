-- EJ EN CLASE
USE Ecommerce;
GO

SET STATISTICS IO, TIME ON;

SELECT 
	COUNT(*)
FROM sell.ventas
WHERE YEAR (fecha_venta) = 2024
GO

SELECT 
	COUNT(*)
FROM sell.ventas
WHERE fecha_venta >= '2024-01-01' AND fecha_venta < '2025-01-01'
GO

------------------------------------------------------------
-- 1) Filtro por fecha NO sargable (función sobre la columna)
------------------------------------------------------------
SELECT COUNT(*) AS ventas_2024
FROM sell.ventas
WHERE YEAR(fecha_venta) = 2024; -- MAL

/*
Se trata de evita aplicar una función sobre la columna, permitiendo el uso de índices y un rango de fechas preciso.
*/

SELECT COUNT(*) AS ventas_2024
FROM sell.ventas
WHERE fecha_venta >= '20240101' AND fecha_venta < '20250101';

------------------------------------------------------------
-- 2) Texto NO sargable (función sobre la columna)
------------------------------------------------------------
SELECT producto_id, nombre_producto
FROM sell.productos
WHERE LEFT(nombre_producto, 4) = 'Prod'; -- MAL

/*
LIKE 'Prod%' permite un index seek, mientras que LEFT() fuerza un scan al evaluar cada fila.
*/

SELECT producto_id, nombre_producto
FROM sell.productos
WHERE nombre_producto LIKE 'Prod%';


------------------------------------------------------------
-- 3) Conversión implícita (variable NVARCHAR contra columna VARCHAR)
------------------------------------------------------------
DECLARE @mail NVARCHAR(100) = N'user10@mail.com';
SELECT cliente_id, nombre, apellido
FROM cli.clientes
WHERE correo_electronico = @mail; -- MAL (CONVERT_IMPLICIT)

/*
Alinear los tipos de datos (VARCHAR) evita la conversión implícita.
*/

DECLARE @mail VARCHAR(100) = 'user10@mail.com';
SELECT cliente_id, nombre, apellido
FROM cli.clientes
WHERE correo_electronico = @mail;

------------------------------------------------------------
-- 4) JOIN que duplica filas y obliga a DISTINCT
------------------------------------------------------------
SELECT DISTINCT c.cliente_id
FROM cli.clientes c
JOIN sell.ventas v            ON v.cliente_id = c.cliente_id
JOIN sell.detalle_ventas d    ON d.venta_id   = v.venta_id; -- MAL (DISTINCT por join multiplicador)

/*
EXISTS evita duplicados al no necesitar DISTINCT, siendo más eficiente que un JOIN.
*/

SELECT c.cliente_id
FROM cli.clientes c
WHERE EXISTS (
    SELECT 1 FROM sell.ventas v 
    WHERE v.cliente_id = c.cliente_id
);

------------------------------------------------------------
-- 5) Búsqueda con comodín al inicio (no usa índice) + ordenamiento caro
------------------------------------------------------------
SELECT TOP (100) producto_id, nombre_producto, precio
FROM sell.productos
WHERE nombre_producto LIKE '%Pro%'   -- MAL (leading wildcard)
ORDER BY UPPER(nombre_producto);     -- MAL (función en ORDER BY)

/*
Eliminar el comodín inicial y la función UPPER() permite el uso de índices tanto para la búsqueda como 
para el ordenamiento.
*/

SELECT TOP (100) producto_id, nombre_producto, precio
FROM sell.productos
WHERE nombre_producto LIKE 'Pro%'   -- Prefijo permite Seek
ORDER BY nombre_producto;           -- Sin función

------------------------------------------------------------
-- 6) Patrón propenso a Key Lookups (muchas columnas, filtro poco selectivo)
------------------------------------------------------------
SELECT TOP (200)
       p.producto_id, p.nombre_producto, p.precio, p.stock, p.marca, p.descripcion
FROM sell.productos p
WHERE p.categoria_id IS NULL      -- MAL (filtro débil)
ORDER BY p.nombre_producto;       -- posible Lookup + Sort

/*
El índice covering evita los key lookups al incluir todas las columnas necesarias, mejorando el rendimiento.
*/

SELECT categoria_id FROM sell.categoria 

CREATE INDEX IX_Productos_Categoria_Nombre 
ON sell.productos (categoria_id, nombre_producto) 
INCLUDE (precio, stock, marca, descripcion);

SELECT TOP (200) producto_id, nombre_producto, precio, stock, marca, descripcion
FROM sell.productos
WHERE categoria_id IS NULL
ORDER BY nombre_producto;

------------------------------------------------------------
-- 7) Agregación con JOIN y función sobre la fecha (no sargable)
------------------------------------------------------------
SELECT SUM(d.cantidad * d.precio_unitario) AS ingresos_2024
FROM sell.detalle_ventas d
JOIN sell.ventas v ON v.venta_id = d.venta_id
WHERE YEAR(v.fecha_venta) = YEAR(GETDATE()); -- MAL

/*
Reemplazar YEAR() con un rango de fechas permite un index seek en vez de un scan completo de la tabla.
*/

DECLARE @YearStart DATE = DATEFROMPARTS(YEAR(GETDATE()), 1, 1);
DECLARE @YearEnd DATE = DATEADD(YEAR, 1, @YearStart);

SELECT SUM(d.cantidad * d.precio_unitario) AS ingresos_2024
FROM sell.detalle_ventas d
JOIN sell.ventas v ON v.venta_id = d.venta_id
WHERE v.fecha_venta >= @YearStart AND v.fecha_venta < @YearEnd;

------------------------------------------------------------
-- 8) Búsqueda case-insensitive aplicando función a la columna
------------------------------------------------------------
DECLARE @q NVARCHAR(100) = N'USER30@MAIL.COM';
SELECT cliente_id, nombre, apellido, correo_electronico
FROM cli.clientes
WHERE LOWER(correo_electronico) = LOWER(@q); -- MAL (función sobre la columna)

/*
Usar la intercalación (COLLATE) correcta evita aplicar funciones a la columna, permitiendo el uso de índices.
*/

DECLARE @q VARCHAR(100) = 'user30@mail.com';
SELECT cliente_id, nombre, apellido, correo_electronico
FROM cli.clientes
WHERE correo_electronico = @q COLLATE SQL_Latin1_General_CP1_CI_AS;