/*
PROCEDIMIENTOS ALMACENADOS
Es un codigo que se puede almacenar para poder reutilizar mas adelante.

CREATE PRECEDURE nombreProcedimiento
AS
BEGIN
 SELECT * FROM schema.tabla;
END

TIPOS DE PROCEDIMIENTOS ALMACENADOS
	1.Prodecimientos Almacenados definidos por el usuario
	2.Procedimientos Almacenados definidos por el sistema
	exec sp_addrolemember;
	3.Procedimientos Almacenados Temporales
	LOCALES: Estan enlazados a la sesion y solo son accesibles por el usuario que los define
	Cuando se cierra la sesión 

	<schema>.#<nombre_procedimiento>

	GLOBALES: Estan enlazados a la sesion y son accesibles para todos los usuarios.
	Se eliminan cuando termina la ultima sesion que lo este utilizando
	<shema>.##<nombre_procedimiento>.

	SINTAXIS
	CREATE PRECEDURE <shema>.<nombre_procedimiento>
	@<nombre_parametro> <tipo_dato>,
	@<nombre_parametro> <tipo_dato> OUTPUT
	AS
	BEGIN
	END
*/

USE ejercicios;
GO

--EJEMPLO DE PAGINACION 
CREATE PROCEDURE inv.paginar_detalles_operacion (
	@pagina INT,
	@tamanioPaginan INT
)
AS
BEGIN
	SELECT * FROM inv.detalle_operacion
	ORDER BY creado_en DESC
	OFFSET (@PAGINA - 1 ) * @tamanioPaginan ROWS 
	FETCH NEXT 10 ROWS ONLY
END
GO

exec inv.paginar_detalles_operacion 1,5
exec inv.paginar_detalles_operacion 2,10

-- EJEMPLO

USE Ecommerce;
GO

CREATE OR ALTER PROCEDURE cli.sp_validar_tarjeta_vigente (
	@fechaBusqueda DATE,
	@clienteId INT
)

AS
BEGIN
	DECLARE @cantidadTarjetasCliente INT,

	SELECT 
	@cantidadTarjetasCliente - COUNT(*)
	FROM cli.tarjetas_credito
	WHERE cliente_id - @clienteId

	IF @cantidadTarjetasCliente > 0
	BEGIN
		SELECT 
		tarjeta_id,
		numero_tarjeta,
		fecha_vencimiento
		FROM cli.tarjetas_credito
		WHERE cliente_id = @clienteId AND fecha_vencimiento > @fechaBusqueda
	END
	ELSE
	BEGIN
		SELECT CONCAT('El cliente: ', @clienteId, 'no posee tarjetas almacenadas') message
END
END

EXEC cli.sp_validar_tarjeta_vigente '2024-05-01' , 1

--PREVIEW TRANSACTIONS

SELECT * FROM cli.clientes;

BEGIN TRANSACTION
	UPDATE cli.clientes SET nombre = 'Jose'
	WHERE cliente_id = 1
COMMIT TRANSACTION
ROLLBACK TRANSACTION


--EJERCICIO, EN CLASE
/*
Implementar un procedimiento almacenado que elimine un cliente y todas sus tarjetas de
crédito asociadas, y luego listar los clientes existentes para verificar la eliminación.

	- Crear el procedimiento almacenado sp_eliminar_cliente.
	- El procedimiento debe aceptar un parámetro de entrada: @clienteId (int)
	- Eliminar al cliente de la tabla [cli].[clientes] y todas sus tarjetas de crédito asociadas de la
	  tabla [cli].[tarjetas_credito].
	- Crear un segundo procedimiento almacenado sp_listar_clientes que retorne la lista de
	  clientes para verificar la eliminación.

	SINTAXIS
	CREATE PRECEDURE <shema>.<nombre_procedimiento>
	@<nombre_parametro> <tipo_dato>,
	@<nombre_parametro> <tipo_dato> OUTPUT
	AS
	BEGIN
	END
*/

USE Ecommerce;
GO
SELECT * FROm cli.tarjetas_credito;
SELECT * FROM cli.clientes;
SELECT * FROM sell.carrito_compras;


-- PROCEDIMIENTO ALMACENADO sp_eliminar_cliente
CREATE OR ALTER PROCEDURE cli.sp_eliminar_cliente (
    @clienteId INT
)
AS
BEGIN
    DELETE FROM cli.tarjetas_credito
    WHERE cliente_id = @clienteId;

	DELETE FROM sell.carrito_compras
    WHERE cliente_id = @clienteId;

    DELETE FROM cli.clientes
    WHERE cliente_id = @clienteId;
END;
GO

-- PROCEDIMIENTO ALMACENADO sp_listar_clientes
CREATE OR ALTER PROCEDURE cli.sp_listar_clientes
AS
BEGIN
    SELECT 
        cliente_id,
        nombre,
        apellido,
        correo_electronico,
        telefono
    FROM cli.clientes;
END;
GO

EXEC cli.sp_eliminar_cliente @clienteId = 1;
EXEC cli.sp_listar_clientes;


