/*VISTAS- SESION 4
Son tablas virtuales definidas por una consulta que, al igual que una tabla, tienen columnas y filas.
TIPOS DE VISTAS: 
Vista Indexadas: Es una vista indexada es una vista materializada cuyo datos se almacenan fisicamente
Vistas Particionadas: Vista de datos relacionados particionados. 
Vistas de Sistema: Las vistas del sistema exponen metadatos del catalogo. 

CREATE VIEW
DROP VIEW
Vistas Materializadas
Es una vista que almacena fisicamente el resultado de su consulta, en lugar de calcularlo cada vez que se ejecuta.

CREAR UNA VISTA <Schema>.<Nombre Vista> AS
SELECT * FROM

*/

USE Ecommerce;
GO

CREATE VIEW sell.vw_productos_con_categoria AS

SELECT p. *,
FROM sell.productos p
JOIN sell.categoria c on p.categoria_id = c.categoria_id;

SELECT * FROM sell.vw_productos_con_categoria;

--MONTO DE VENTAS
CREATE VIEW sell.vw_ventas_anio_mes_producto AS
SELECT 
    YEAR(v.fecha_venta) AS anio,
    MONTH(v.fecha_venta) AS mes,
	p.nombre_producto,
    SUM(dv.cantidad * dv.precio_unitario) monto_total
FROM sell.detalle_ventas dv
JOIN sell.ventas v ON dv.venta_id = v.venta_id
JOIN sell.productos p ON dv.producto_id = p.producto_id
GROUP BY YEAR(v.fecha_venta), MONTH(v.fecha_venta);
GO

SELECT * FROM sell.vw_ventas_anio_mes_producto
WHERE anio = 2024
ORDER BY mes;

--ELIMIAR VISTA
DROP VIEW sell.vw_productos_con_categoria;

--EJERCICIOS
/*
VISTAS 
Contruir una vista que construya esto: 
RFM por cliente (Recencia, Frecuencia, Valor)
Recencia (R): Dias desde la ultima compra (MAX(fecha_venta)).
Frecuencia (F): numero de ventas
Valor (M): Monto total comprado (suma de cantidad * precio_unitario)

La vista debe exponer cliente_id, nombre, apellido, recencia_dias, frecuencia_ventas, monto_total
*/

SELECT * FROM cli.clientes;
SELECT * FROM sell.ventas;
SELECT * FROM sell.detalle_ventas;


CREATE VIEW cli.vw_rfm_por_cliente AS
SELECT 
    c.cliente_id,
    c.nombre,
    c.apellido,
    GETDATE() - MAX(v.fecha_venta) AS recencia_dias,
    COUNT(v.venta_id) frecuencia_ventas,
    SUM(dv.cantidad * dv.precio_unitario) monto_total
FROM cli.clientes c
JOIN sell.ventas v ON c.cliente_id = v.cliente_id
JOIN sell.detalle_ventas dv ON v.venta_id = dv.venta_id
GROUP BY c.cliente_id, c.nombre, c.apellido;
GO

SELECT * FROM cli.vw_rfm_por_cliente;



/*
vw_rotacion_inventario_por_producto
Construye una vista que muestre, por producto:
    producto_id,
    nombre_producto,
    marca,
    categoria,
    unidades vendidas en los últimos 30 días,
    monto vendido en ese periodo,
    valor inventario (stock * precio),
    días de cobertura = valor inventario / (monto vendido/30) (aprox).
Posibles tablas: sell.productos (tiene precio, stock, categoria_id, marca), sell.detalle_ventas, sell.ventas, sell.categoria.
*/


SELECT * FROM sell.productos;
SELECT * FROM sell.detalle_ventas;
SELECT * FROM sell.ventas;
SELECT * FROM sell.categoria;

CREATE VIEW vw_rotacion_inventario_por_producto AS
SELECT 
    p.producto_id,
    p.nombre_producto,
    p.marca,
    c.categoria,
    SUM(dv.cantidad) u30,
    SUM(dv.cantidad * dv.precio_unitario) m30,
    p.stock * p.precio inv,
    p.stock * 30.0 / SUM(dv.cantidad) dias_cov
FROM sell.productos p
JOIN sell.categoria c ON p.categoria_id = c.categoria_id
JOIN sell.detalle_ventas dv ON p.producto_id = dv.producto_id
JOIN sell.ventas v ON dv.venta_id = v.venta_id 
GROUP BY p.producto_id, p.nombre_producto, p.marca, c.categoria, p.stock, p.precio;
GO

--DROP VIEW  vw_rotacion_inventario_por_producto ;

SELECT * FROM vw_rotacion_inventario_por_producto;