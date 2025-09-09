-- EJERCICIOS - VISTAS

/*
Cree las vistas listadas posteriormente:

vw_carritos_abandonados_participacion_por_categoria
Genera una vista que liste carritos abandonados (sell.carrito_compras.abandonado = 1) con:
    carrito_id,
    cliente_id,
    valor estimado del carrito (sumando cantidad * precio del producto),
    porcentaje por categoría del valor del carrito (participación de cada categoría en el total del carrito).
Esta vista servirá a marketing para campañas de recuperación.

Posibles Tablas: sell.carrito_compras, sell.detalle_carrito_compras, sell.productos, sell.categoria

*/

USE Ecommerce;
GO


SELECT * FROM sell.carrito_compras;
SELECT * FROM sell.detalle_carrito_compras;
SELECT * FROM sell.productos;
SELECT * FROM sell.categoria;

--DROP VIEW vw_carritos_abandonados_participacion_por_categoria;

CREATE VIEW vw_carritos_abandonados_participacion_por_categoria AS
SELECT 
    cc.carrito_id,
    cc.cliente_id,
    SUM(dcc.cantidad * p.precio) AS valor_total_carrito,
    cat.categoria,
    SUM(dcc.cantidad * p.precio) * 100.0 / 
        SUM(SUM(dcc.cantidad * p.precio)) OVER (PARTITION BY cc.carrito_id) AS porcentaje_categoria
FROM sell.carrito_compras cc
JOIN sell.detalle_carrito_compras dcc ON cc.carrito_id = dcc.carrito_id
JOIN sell.productos p  ON dcc.producto_id = p.producto_id
JOIN sell.categoria cat ON p.categoria_id = cat.categoria_id
WHERE cc.abandonado = 1
GROUP BY 
    cc.carrito_id,
    cc.cliente_id,
    cat.categoria;


SELECT * 
FROM vw_carritos_abandonados_participacion_por_categoria
WHERE carrito_id = 3020;


/*
vw_ventas_por_categoria_diaDefine una vista determinista de ventas por categoría y fecha con:
    categoria_id,
    fecha,
    ventas (cantidad de "facturas") ,
    monto.
Asegúrate de cumplir requisitos de vista indexada (por ejemplo, SCHEMABINDING, sin funciones no deterministas) y 
crea el índice clúster único sobre (categoria_id, fecha). Servirá como base “materializada” para múltiples reportes
diarios por categoría. 

Posibles Tablas: sell.ventas, sell.detalle_ventas, sell.productos, sell.categoria
*/

SELECT * FROM sell.ventas;
SELECT * FROM sell.detalle_ventas;
SELECT * FROM sell.productos;
SELECT * FROM sell.categoria;

DROP VIEW sell.vw_ventas_por_categoria_dia;

CREATE VIEW sell.vw_ventas_por_categoria_dia
WITH SCHEMABINDING
AS
SELECT  
    c.categoria_id,
    CAST(v.fecha_venta AS date) AS fecha,
    COUNT_BIG(*) AS ventas,
    SUM(ISNULL(dv.cantidad,0) * ISNULL(dv.precio_unitario,0)) AS monto
FROM sell.ventas v
JOIN sell.detalle_ventas dv ON v.venta_id = dv.venta_id
JOIN sell.productos p ON dv.producto_id = p.producto_id
JOIN sell.categoria c ON p.categoria_id = c.categoria_id
GROUP BY  
    c.categoria_id,
    CAST(v.fecha_venta AS date);
GO

CREATE UNIQUE CLUSTERED INDEX IX_vw_ventas_por_categoria_dia
ON sell.vw_ventas_por_categoria_dia (categoria_id, fecha);

SELECT * FROM sell.vw_ventas_por_categoria_dia;

