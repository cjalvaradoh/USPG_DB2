--EJERCICIOS DE FUNCIONES ESCALARES Y TABULARES

USE ejercicios;
GO

/*
1- CONVERSION DE UNIDADES DE MEDIDA-ESCALAR
Escribe una funcion que reciba como parametro la abreviatura de la unidad de medida origen, destino
y las unidades a convertir. Y calcule el resultado
SINTAXIS

CREATE FUNCTION NOMBRE_FUNCION 
(@parametro1 as [Tipo Dato] = [ValorxDefecto],
@parametro2 as [Tipo Dato] = [ValorxDefecto])

RETURNS TipoDato_Returnado
AS
BEGIN
<INSTRUCCIONES>
RETURN Expresion_salida
END

*/

SELECT * FROM inv.conversion;
SELECT * FROM inv.unidad_medida;
SELECT * FROM inv.tipo_unidad_medida;

DROP FUNCTION IF EXISTS u_Medida;
GO

CREATE FUNCTION u_Medida (
    @um_origen_abrev VARCHAR(10),
    @um_destino_abrev VARCHAR(10),
    @cantidad FLOAT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @um_origen_id INT;
    DECLARE @um_destino_id INT;
    DECLARE @factor FLOAT;
    DECLARE @resultado FLOAT;

    -- 1. Buscar el ID de la unidad de origen
    SELECT @um_origen_id = um_id
    FROM inv.unidad_medida
    WHERE abreviatura = @um_origen_abrev;

    -- 2. Buscar el ID de la unidad de destino
    SELECT @um_destino_id = um_id
    FROM inv.unidad_medida
    WHERE abreviatura = @um_destino_abrev;

    -- 3. Buscar el factor de conversión directo (de origen a destino)
    SELECT @factor = factor
    FROM inv.conversion
    WHERE um_origen_id = @um_origen_id
      AND um_destino_id = @um_destino_id;

    -- 4. Calcular el resultado
    SET @resultado = @cantidad * @factor;

    RETURN @resultado;
END;
GO

-- Convertir 2 kilogramos (kg) a libras (lb)
SELECT dbo.u_Medida('km', 'lb', 2) AS resultado;
-- Debería devolver: 2 * 2.204623 = 4.409246


/*
2- UNIDADES DE MEDIDA MAS UTILIZADAS -MSTVF
Encuentra las unidades de medida mas utilizadas en la tabla UNIDAD_MEDIDA, muestra las unidades de Medida
y la cantidad de productos que las utilizan
*/
SELECT * FROM inv.conversion;
SELECT * FROM inv.unidad_medida;
SELECT * FROM inv.tipo_unidad_medida;

DROP FUNCTION IF EXISTS unidadMedidaFrecuente;
GO


CREATE OR ALTER FUNCTION dbo.unidadMedidaFrecuente()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        um.unidad_medida,
        COUNT(p.producto_id) AS cantidad_productos
    FROM 
        inv.unidad_medida um
    LEFT JOIN 
        inv.producto p ON um.um_id = p.um_recepcion_id OR um.um_id = p.um_entrega_id
    GROUP BY 
        um.unidad_medida
);
GO

-- Ejemplo de uso
SELECT *
FROM dbo.unidadMedidaFrecuente()
ORDER BY cantidad_productos DESC;
