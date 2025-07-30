/* TAR-FUNCIONES
1. CÁLCULO DEL PRECIO TOTAL EN UNA UNIDAD DE MEDIDA DIFERENTE - ESCALAR
CREA UNA FUNCIÓN ESCALAR QUE RECIBA COMO PARÁMETROS EL ID DE UN PRODUCTO, UNA
CANTIDAD, Y UNA ABREVIATURA DE LA UNIDAD DE MEDIDA DESTINO. LA FUNCIÓN DEBE CALCULAR
EL PRECIO TOTAL DEL PRODUCTO EN LA NUEVA UNIDAD DE MEDIDA (POR EJEMPLO, CONVERTIR DE
LITROS A GALONES). UTILIZA ESTA FUNCIÓN PARA CALCULAR EL PRECIO TOTAL EN DIFERENTES
UNIDADES DE MEDIDA PARA UN CONJUNTO DE PRODUCTOS.
*/
USE ejercicios;
GO

SELECT * FROM inv.producto;

DROP FUNCTION IF EXISTS f_PrecioTotalConvertido;
GO


CREATE FUNCTION f_PrecioTotalConvertido (
    @producto_id INT, --Primer argumento : ID del producto que se desea consultar
    @cantidad FLOAT,  -- Segundo argumento : Cantidad del producto solicitada, en una unidad de destino
    @abrev_um_destino VARCHAR(10) -- Tercer argumento : Abreviatura de la unidad de medida en la que se expresa la cantidad

)
RETURNS FLOAT
AS
BEGIN
    DECLARE @um_origen_id INT;         -- um_entrega_id del producto (unidad del precio)
    DECLARE @um_destino_id INT;        -- um_id de la unidad destino (convertir desde esta)
    DECLARE @factor FLOAT;             -- Factor de conversión de destino a origen
    DECLARE @precio_unitario FLOAT;    -- Precio unitario del producto en su unidad de entrega original
    DECLARE @precio_total FLOAT;       -- Resultado final

    -- Consulta 1 : Obtener um_entrega_id y precio_unitario_entrega del producto
    SELECT 
        @um_origen_id = um_entrega_id,                -- Extrae el ID de la unidad de medida de entrega
        @precio_unitario = precio_unitario_entrega    -- Extrae el precio unitario en la unidad de entrega
    FROM inv.producto
    WHERE producto_id = @producto_id;                 -- Filtra por el producto especificado

    -- Consulta 2 : Obtener ID de unidad destino por su abreviatura
    SELECT @um_destino_id = um_id
    FROM inv.unidad_medida
    WHERE abreviatura = @abrev_um_destino;

    --Consulta 3 : Buscar el factor de conversión desde la unidad destino hacia la unidad origen
    SELECT @factor = factor
    FROM inv.conversion
    WHERE um_origen_id = @um_destino_id     -- Desde la unidad que el usuario proporcionó
      AND um_destino_id = @um_origen_id;    -- Hacia la unidad del producto

    -- Convertir la cantidad a la unidad original (um_entrega)
    -- Si el factor existe, convierte
    IF @factor IS NOT NULL
        SET @cantidad = @cantidad * @factor;

    -- Calcular el precio total
    SET @precio_total = @cantidad * @precio_unitario;

    RETURN @precio_total;
END;
GO

SELECT dbo.f_PrecioTotalConvertido(12, 2, 'gl') AS precio_total;

/*
2. LISTADO DE PRODUCTOS POR UNIDAD DE MEDIDA - MSTVF
CREA UNA FUNCIÓN DE TABLA QUE RECIBA COMO PARÁMETRO UNA UNIDAD DE MEDIDA Y
DEVUELVA UNA LISTA DE PRODUCTOS QUE UTILIZAN ESA UNIDAD, JUNTO CON SU CANTIDAD EN
INVENTARIO Y SU PRECIO UNITARIO. USA ESTA FUNCIÓN PARA MOSTRAR LOS PRODUCTOS QUE USAN
UNA UNIDAD DE MEDIDA ESPECÍFICA.
*/

SELECT * FROM inv.producto;
SELECT * FROM inv.tipo_unidad_medida;

DROP FUNCTION IF EXISTS inv.f_ProductosPorUnidad;
GO

-- Crear una función en el esquema 'inv' que retorne una tabla filtrada por unidad de medida
CREATE FUNCTION inv.f_ProductosPorUnidad (
    @unidad_abreviatura VARCHAR(10) -- Parámetro: abreviatura de la unidad que se desea consultar (ej. 'kg', 'lt', 'm')
)
RETURNS TABLE
AS
RETURN (
    SELECT  
        p.nombre_producto,                                          -- Nombre del producto
        p.precio_unitario_entrega,                                  -- Precio por unidad en su unidad de entrega
        um.unidad_medida AS unidad_usada                            -- Nombre completo de la unidad usada por el producto
    FROM inv.producto p
    INNER JOIN inv.unidad_medida um ON p.um_entrega_id = um.um_id   -- Une producto con su unidad de entrega
    WHERE um.abreviatura = @unidad_abreviatura                      -- Filtra por la abreviatura que se pasa como parámetro
);
GO


-- Consulta para probar la función: mostrar los productos que usan 'km' como unidad de entrega
SELECT * 
FROM inv.f_ProductosPorUnidad('km');  

