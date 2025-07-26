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
    @um_origen_abrev VARCHAR(10),  -- Declarar el primer argumento (Abreviatura de la unidad de origen)
    @um_destino_abrev VARCHAR(10), -- Declarar el segundo argumento (Abreviatura de la unidad de destino)
    @cantidad FLOAT                -- Declarar el tercer argumento (Cantidad a convertir)
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @um_origen_id INT; -- Declarar variables? 
    DECLARE @um_destino_id INT; --variable id correspondiante a la unidad de medida destino
    DECLARE @factor FLOAT; --Varibale del factor de converion entre origen y destino
    DECLARE @resultado FLOAT; --Varibale para el Resultado final de la conversión

    -- Consulta 1 : Buscar el ID de la unidad de origen (El primer parametro)
    SELECT @um_origen_id = um_id
    FROM inv.unidad_medida
    WHERE abreviatura = @um_origen_abrev;

    -- Consulta 2 : Buscar el ID de la unidad de destino (El segundo parametro)
    SELECT @um_destino_id = um_id
    FROM inv.unidad_medida
    WHERE abreviatura = @um_destino_abrev;

    -- Consulta 3 : Consulta 3: Buscar el valor del factor de conversión de la unidad origen a la unidad destino
    SELECT @factor = factor
    FROM inv.conversion
    WHERE um_origen_id = @um_origen_id
      AND um_destino_id = @um_destino_id;

    -- Cálculo final: multiplicamos la cantidad por el factor para obtener el resultado de la conversión
    SET @resultado = @cantidad * @factor;

    RETURN @resultado;
END;
GO

-- Peticion de una conversion 
SELECT dbo.u_Medida('kg', 'lb', 2) AS resultado;


/*
2- UNIDADES DE MEDIDA MAS UTILIZADAS -MSTVF
Encuentra las unidades de medida mas utilizadas en la tabla UNIDAD_MEDIDA, muestra las unidades de Medida
y la cantidad de productos que las utilizan
*/

--Consultas a las tablas a usar
SELECT * FROM inv.conversion;
SELECT * FROM inv.unidad_medida;
SELECT * FROM inv.tipo_unidad_medida;

DROP FUNCTION IF EXISTS dbo.unidadMedidaFrecuente;
GO

-- Retornar una tabla con la cantidad de usos por unidad
CREATE FUNCTION dbo.unidadMedidaFrecuente()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        um_origen_id AS unidad_id,  
        COUNT(*) AS cantidad_usos   
    FROM inv.conversion
    GROUP BY um_origen_id          
);
GO

SELECT *
FROM dbo.unidadMedidaFrecuente()
ORDER BY cantidad_usos DESC;