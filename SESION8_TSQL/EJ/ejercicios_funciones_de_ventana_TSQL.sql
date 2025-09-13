--Ejercicios — Funciones de Ventana
USE Ecommerce;
GO

/*
1. Gasto mensual y ranking por cliente
Para cada venta en sell.ventas, muestra: cliente_id, fecha_venta, total_venta, el
total del mes de ese cliente y el ranking del cliente dentro del mes por su total mensual
(1 = mayor gasto). Mantén el detalle por venta.
Pistas: usar FORMAT(fecha_venta,'yyyy-MM') (o YEAR/MONTH), SUM()
OVER(PARTITION BY cliente, mes) y luego rankear por mes.
*/

SELECT
    v.cliente_id,
    v.fecha_venta,
    v.total_venta,
    t.total_mensual,
    RANK() OVER ( PARTITION BY t.mes ORDER BY t.total_mensual DESC) AS ranking_mensual
	FROM sell.ventas v
	CROSS APPLY (
    SELECT 
        FORMAT(v.fecha_venta, 'yyyy-MM') AS mes,
        SUM(v2.total_venta) AS total_mensual
    FROM sell.ventas v2
    WHERE v2.cliente_id = v.cliente_id
      AND FORMAT(v2.fecha_venta, 'yyyy-MM') = FORMAT(v.fecha_venta, 'yyyy-MM')
) t;


/*
2.Primera y última compra por cliente
Para cada venta, agrega columnas con el monto de la primera compra y el monto de la
última compra del mismo cliente.
Pistas: FIRST_VALUE() y LAST_VALUE() con marco explícito ROWS BETWEEN UNBOUNDED
PRECEDING AND UNBOUNDED FOLLOWING.
*/

SELECT
    v.cliente_id,
    v.fecha_venta,
    v.total_venta,
    FIRST_VALUE(v.total_venta) OVER (
        PARTITION BY v.cliente_id
        ORDER BY v.fecha_venta
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS primera_compra,
    LAST_VALUE(v.total_venta) OVER (
        PARTITION BY v.cliente_id
        ORDER BY v.fecha_venta
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS ultima_compra
FROM sell.ventas v;

/*
3. Comparación con compra anterior y variación
Para cada venta, muestra también el monto de la compra anterior del mismo cliente y
la variación porcentual respecto a la anterior. Incluye la cantidad de días
transcurridos desde la compra anterior.
Pistas: LAG(total_venta), DATEDIFF(DAY, LAG(fecha_venta), fecha_venta) y
cálculo de %.
*/

SELECT 
    venta_id,
    cliente_id,
    fecha_venta,
    total_venta,
    LAG(total_venta) OVER(PARTITION BY cliente_id ORDER BY fecha_venta) AS compra_anterior,
    (total_venta - LAG(total_venta) OVER(PARTITION BY cliente_id ORDER BY fecha_venta))
        * 100.0 / LAG(total_venta) OVER(PARTITION BY cliente_id ORDER BY fecha_venta) AS variacion_pct,
    DATEDIFF(DAY, LAG(fecha_venta) OVER(PARTITION BY cliente_id ORDER BY fecha_venta), fecha_venta) AS dias_transcurridos
FROM sell.ventas;


/*
4. Acumulado progresivo (LTV) por cliente
Para cada venta, calcula el acumulado histórico del cliente hasta esa fecha (running
total).
Pistas: SUM(total_venta) OVER(PARTITION BY cliente ORDER BY fecha_venta,
venta_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW).
*/

SELECT
    v.venta_id,
    v.cliente_id,
    v.fecha_venta,
    v.total_venta,
    SUM(v.total_venta) OVER(
        PARTITION BY v.cliente_id 
        ORDER BY v.fecha_venta, v.venta_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS acumulado_cliente
FROM sell.ventas v;


/*
5. Top por categoría con ranking de productos vendidos
Usando sell.detalle_ventas, sell.productos y sell.categoria, calcula el total
de unidades vendidas por producto y, dentro de cada categoría, asigna un ranking del
1 en adelante (1 = más vendido). Muestra solo los 3 primeros por categoría.
Pistas: SUM(dv.cantidad) + RANK() OVER(PARTITION BY categoria ORDER BY
total DESC); filtra ranking <= 3.
*/


SELECT *
FROM (
    SELECT 
        c.categoria,
        p.nombre_producto,
        SUM(dv.cantidad) AS total_vendido,
        RANK() OVER (
            PARTITION BY c.categoria_id 
            ORDER BY SUM(dv.cantidad) DESC
        ) AS ranking
    FROM sell.detalle_ventas dv
    JOIN sell.productos p ON dv.producto_id = p.producto_id
    JOIN sell.categoria c ON p.categoria_id = c.categoria_id
    GROUP BY c.categoria_id, c.categoria, p.nombre_producto
) t;


/*
6. Cuartiles de ventas individuales
Clasifica cada venta de sell.ventas en cuartiles según total_venta a nivel global (1
= mayores montos, 4 = menores).
Pistas: NTILE(4) OVER(ORDER BY total_venta DESC).
*/

SELECT 
    v.venta_id,
    v.cliente_id,
    v.fecha_venta,
    v.total_venta,
    NTILE(4) OVER (ORDER BY v.total_venta DESC) AS cuartil
FROM sell.ventas v;


/*
7. Análisis de carritos: aporte por línea y total
Para cada línea de sell.detalle_carrito_compras, muestra: carrito_id,
producto_id, cantidad, el total de ítems del carrito y el porcentaje que aporta la
línea respecto al total de ítems del carrito.
Pistas: SUM(cantidad) OVER(PARTITION BY carrito_id) y porcentaje = cantidad
/ SUM(...) OVER(...).
*/

SELECT 
    dcc.carrito_id,
    dcc.producto_id,
    dcc.cantidad,
    SUM(dcc.cantidad) OVER (PARTITION BY dcc.carrito_id) AS total_items_carrito,
    CAST(dcc.cantidad * 100.0 / 
         NULLIF(SUM(dcc.cantidad) OVER (PARTITION BY dcc.carrito_id), 0) AS DECIMAL(5,2)) AS porcentaje_aporte
FROM sell.detalle_carrito_compras dcc;


/*
8. Carritos abandonados con valor estimado
Para carritos sell.carrito_compras abandonados (abandonado=1), estima el valor
total del carrito sumando cantidad * precio (unir con sell.productos) y muéstralo
junto con el porcentaje que aporta cada línea al valor total del carrito. Mantén el detalle
por línea.
Pistas: SUM(cantidad*precio) OVER(PARTITION BY carrito_id) y proporción por
línea.
*/

SELECT 
    cc.carrito_id,
    dcc.producto_id,
    dcc.cantidad,
    p.precio,
    dcc.cantidad * p.precio AS valor_linea,
    SUM(dcc.cantidad * p.precio) OVER (PARTITION BY cc.carrito_id) AS valor_total_carrito,
    CAST(dcc.cantidad * p.precio * 100.0 / 
         NULLIF(SUM(dcc.cantidad * p.precio) OVER (PARTITION BY cc.carrito_id), 0) AS DECIMAL(5,2)) AS porcentaje_linea
FROM sell.carrito_compras cc
JOIN sell.detalle_carrito_compras dcc ON cc.carrito_id = dcc.carrito_id
JOIN sell.productos p ON dcc.producto_id = p.producto_id
WHERE cc.abandonado = 1;


/*
9. Rendimiento mensual por región y ranking de vendedores (stg.sales)
En stg.sales, calcula por cada SalesRegion y mes el total mensual por vendedor
(SalesPersonName). Luego, dentro de cada región y mes, asigna el ranking del
vendedor por ese total y su percentil cuartil. Mantén las filas originales y añade
columnas de totales/posiciones.
Pistas: SUM(SalesAmount) OVER(PARTITION BY SalesRegion, mes,
SalesPersonName) y luego DENSE_RANK() OVER(PARTITION BY SalesRegion, mes
ORDER BY total DESC) + NTILE(4).
*/

--DELETE TABLE stg.sales 

create schema stg
CREATE TABLE stg.sales (
    SalesID INT IDENTITY(1,1) PRIMARY KEY,
    SalesPersonName VARCHAR(100) NOT NULL,
    SalesRegion VARCHAR(100) NOT NULL,
    SalesAmount DECIMAL(12,2) NOT NULL,
    SalesDate DATE NOT NULL
);

SELECT
    s.SalesID,
    s.SalesPersonName,
    s.SalesRegion,
    s.SalesAmount,
    s.SalesDate,
    DATEPART(YEAR, s.SalesDate) AS anio,
    DATEPART(MONTH, s.SalesDate) AS mes,
    SUM(s.SalesAmount) OVER ( PARTITION BY s.SalesRegion,
                     DATEPART(YEAR, s.SalesDate),
                     DATEPART(MONTH, s.SalesDate),
                     s.SalesPersonName
    ) AS total_mensual_vendedor,
    DENSE_RANK() OVER (
        PARTITION BY s.SalesRegion,
                     DATEPART(YEAR, s.SalesDate),
                     DATEPART(MONTH, s.SalesDate)
        ORDER BY SUM(s.SalesAmount) OVER (
            PARTITION BY s.SalesRegion,
                         DATEPART(YEAR, s.SalesDate),
                         DATEPART(MONTH, s.SalesDate),
                         s.SalesPersonName
        ) DESC
    ) AS ranking,
    NTILE(4) OVER (
        PARTITION BY s.SalesRegion,
                     DATEPART(YEAR, s.SalesDate),
                     DATEPART(MONTH, s.SalesDate)
        ORDER BY SUM(s.SalesAmount) OVER (
            PARTITION BY s.SalesRegion,
                         DATEPART(YEAR, s.SalesDate),
                         DATEPART(MONTH, s.SalesDate),
                         s.SalesPersonName
        ) DESC
    ) AS cuartil
FROM stg.sales s;

/*
10. Promedio móvil de 3 compras por cliente
Para cada venta, calcula el promedio de las últimas 3 compras del mismo cliente
(incluyendo la actual).
Pistas: AVG(total_venta) OVER(PARTITION BY cliente ORDER BY fecha_venta,
venta_id ROWS BETWEEN 2 PRECEDING AND CURRENT ROW).
*/

SELECT
    v.venta_id,
    v.cliente_id,
    v.fecha_venta,
    v.total_venta,
    AVG(v.total_venta) OVER (
        PARTITION BY v.cliente_id
        ORDER BY v.fecha_venta, v.venta_id
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS promedio_movil_3
FROM sell.ventas v;
