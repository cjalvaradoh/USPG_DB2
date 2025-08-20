--TAREA VISTAS
/*
vw_carritos_abandonados_participacion_por_categoria
Genera una vista que liste carritos abandonados (sell.carrito_compras.abandonado = 1) con:
    carrito_id,
    cliente_id,
    valor estimado del carrito (sumando cantidad * precio del producto),
    porcentaje por categoría del valor del carrito (participación de cada categoría en el total del carrito).
Esta vista servirá a marketing para campañas de recuperación.

Posibles Tablas: sell.carrito_compras, sell.detalle_carrito_compras, sell.productos, sell.categoria
*/

USE ecommerce;
GO

SELECT * FROM sell.carrito_compras;
SELECT * FROM sell.detalle_carrito_compras;
SELECT * FROM sell.productos;
SELECT * FROM sell.categoria;

--DROP VIEW vw_carritos_abandonados_participacion_por_categoria;
CREATE VIEW vw_carritos_abandonados_participacion_por_categoria
AS
SELECT 
    car.carrito_id,
    car.cliente_id,
    prod.categoria_id,
    SUM(det.cantidad * prod.precio) AS valor_estimado_categoria,
    SUM(det.cantidad * prod.precio) * 100.0 
        / NULLIF(SUM(SUM(det.cantidad * prod.precio)) OVER(PARTITION BY car.carrito_id),0) 
        AS porcentaje_participacion_categoria
FROM sell.carrito_compras car
INNER JOIN sell.detalle_carrito_compras det 
    ON car.carrito_id = det.carrito_id
INNER JOIN sell.productos prod 
    ON det.producto_id = prod.producto_id
WHERE car.abandonado = 1
GROUP BY car.carrito_id, car.cliente_id, prod.categoria_id;

SELECT * FROM vw_carritos_abandonados_participacion_por_categoria;

/*
vw_ventas_por_categoria_diaDefine una vista determinista de ventas por categoría y fecha con:
    categoria_id,
    fecha,
    ventas (cantidad de "facturas") ,
    monto.
Asegúrate de cumplir requisitos de vista indexada (por ejemplo, SCHEMABINDING, sin funciones no deterministas) y crea el índice clúster único sobre (categoria_id, fecha). Servirá como base “materializada” para múltiples reportes diarios por categoría. 

Posibles Tablas: sell.ventas, sell.detalle_ventas, sell.productos, sell.categoria
*/


SELECT * FROM sell.ventas;
SELECT * FROM sell.detalle_ventas;
SELECT * FROM sell.productos;
SELECT * FROM sell.categoria;

DROP VIEW sell.vw_ventas_por_categoria_dia
GO

CREATE VIEW sell.vw_ventas_por_categoria_dia
WITH SCHEMABINDING
AS
SELECT 
    cat.categoria_id,
    CONVERT(date, v.fecha_venta) AS fecha,
    COUNT_BIG(*) AS ventas,
    SUM(ISNULL(dv.cantidad, 0) * ISNULL(dv.precio_unitario, 0)) AS monto
FROM sell.ventas v
INNER JOIN sell.detalle_ventas dv ON v.venta_id = dv.venta_id
INNER JOIN sell.productos p ON dv.producto_id = p.producto_id
INNER JOIN sell.categoria cat ON p.categoria_id = cat.categoria_id
GROUP BY cat.categoria_id, CONVERT(date, v.fecha_venta);
GO

CREATE UNIQUE CLUSTERED INDEX IX_vw_ventas_por_categoria_dia
ON sell.vw_ventas_por_categoria_dia (categoria_id, fecha);

SELECT * FROM sell.vw_ventas_por_categoria_dia
ORDER BY categoria_id, fecha;