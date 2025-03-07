-- Creacion SP limpieza
CREATE PROCEDURE etl_ods.limpiar_y_cargar_fact_inventario
AS
BEGIN
    SET NOCOUNT ON;

    -- Contadores
    DECLARE @Total_Procesados INT = 0;
    DECLARE @Total_Eliminados INT = 0;
    DECLARE @Total_Cargados INT = 0;

    -- Contar total de registros procesados en esta ejecución
    SELECT @Total_Procesados = COUNT(*) FROM etl_stg.fact_inventario;

    -- Registrar en la auditoría los registros eliminados y contarlos
    INSERT INTO etl_ods.audit_limpieza (
        ID_Movimiento, Fecha_Hora, ID_Producto, ID_Categoria, ID_Almacen, 
        ID_Proveedor, ID_Empleado, Tipo_Movimiento, Cantidad, 
        Valor_Unitario, Valor_Total, Motivo_Eliminacion, Fecha_Registro
    )
    SELECT 
        ID_Movimiento, Fecha_Hora, ID_Producto, ID_Categoria, ID_Almacen, 
        ID_Proveedor, ID_Empleado, Tipo_Movimiento, Cantidad, 
        Valor_Unitario, Valor_Total, 
        CASE 
            WHEN ID_Proveedor IS NULL THEN 'ID_Proveedor es NULL'
            WHEN ID_Empleado IS NULL THEN 'ID_Empleado es NULL'
            WHEN Fecha_Hora < '2000-01-01' THEN 'Fecha_Hora menor a 2000-01-01'
            WHEN Fecha_Hora > GETDATE() THEN 'Fecha_Hora mayor a la fecha actual'
            ELSE 'Otro motivo'
        END AS Motivo_Eliminacion,
        GETDATE()
    FROM etl_stg.fact_inventario S
    WHERE (ID_Proveedor IS NULL 
           OR ID_Empleado IS NULL 
           OR Fecha_Hora < '2000-01-01' 
           OR Fecha_Hora > GETDATE())
          AND NOT EXISTS (
              SELECT 1 
              FROM etl_ods.audit_limpieza A
              WHERE A.ID_Movimiento = S.ID_Movimiento
          );

    -- Contar los registros eliminados en esta ejecución
    SET @Total_Eliminados = @@ROWCOUNT;

    -- Insertar registros limpios en la ODS y contarlos
    INSERT INTO etl_ods.fact_inventario (
        ID_Movimiento, Fecha_Hora, ID_Producto, ID_Categoria, ID_Almacen, 
        ID_Proveedor, ID_Empleado, Tipo_Movimiento, Cantidad, 
        Valor_Unitario, Valor_Total, Fecha_Carga
    )
    SELECT 
        S.ID_Movimiento, 
        CASE 
            WHEN S.Fecha_Hora < '2000-01-01' OR S.Fecha_Hora > GETDATE() 
            THEN (SELECT MIN(Fecha_Hora) FROM etl_stg.fact_inventario) 
            ELSE S.Fecha_Hora 
        END AS Fecha_Hora,
        S.ID_Producto, S.ID_Categoria, S.ID_Almacen, S.ID_Proveedor, S.ID_Empleado,
        CASE 
            WHEN S.Tipo_Movimiento = 'Enrtrada' THEN 'Entrada' 
            WHEN S.Tipo_Movimiento = 'Salid' THEN 'Salida' 
            ELSE S.Tipo_Movimiento 
        END AS Tipo_Movimiento,
        ABS(S.Cantidad) AS Cantidad,  -- Convertir valores negativos en positivos
        CASE 
            WHEN S.Valor_Unitario > (SELECT AVG(Valor_Unitario) * 5 FROM etl_stg.fact_inventario) 
            THEN S.Valor_Unitario / 10 
            ELSE S.Valor_Unitario 
        END AS Valor_Unitario,
        S.Valor_Total, 
        GETDATE() AS Fecha_Carga
    FROM etl_stg.fact_inventario S
    WHERE ID_Proveedor IS NOT NULL 
          AND ID_Empleado IS NOT NULL 
          AND Fecha_Hora BETWEEN '2000-01-01' AND GETDATE()
          -- Solo insertar si no existe en ODS
          AND NOT EXISTS (
              SELECT 1 
              FROM etl_ods.fact_inventario O 
              WHERE O.ID_Movimiento = S.ID_Movimiento
          );

    -- Contar los registros insertados en esta ejecución
    SET @Total_Cargados = @@ROWCOUNT;

    -- Registrar auditoría del proceso en la tabla etl_ods.audit_limpieza_desc
    INSERT INTO etl_ods.audit_limpieza_desc (
        Fecha_Proceso, Registros_Procesados, Registros_Eliminados, Registros_Cargados
    )
    VALUES (GETDATE(), @Total_Procesados, @Total_Eliminados, @Total_Cargados);

    PRINT 'Datos limpios cargados en etl_ods.fact_inventario.';
    PRINT 'Registros eliminados auditados en etl_ods.audit_limpieza.';
    PRINT 'Resumen del proceso registrado en etl_ods.audit_limpieza_desc.';
END;
GO

-- Creacion SP ODS - Relacionado con tablas dim

  CREATE OR ALTER PROCEDURE etl_ods.sp_cargar_dim_producto
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Fecha_Carga_Max DATETIME;
    DECLARE @Total_Staging INT, @Cargados INT, @Duplicados INT, @Rechazados INT;

    -- Obtener la fecha de carga más reciente sin milisegundos (solo hasta el segundo)
    SELECT @Fecha_Carga_Max = (
        SELECT TOP 1 Fecha_Carga
        FROM etl_stg.dim_producto
        ORDER BY Fecha_Carga DESC
    );

    -- Eliminar milisegundos para comparación
    SET @Fecha_Carga_Max = CAST(FORMAT(@Fecha_Carga_Max, 'yyyy-MM-dd HH:mm:ss') AS DATETIME);

    -- Contar registros en Staging considerando solo la fecha hasta el segundo
    SELECT @Total_Staging = COUNT(*) 
    FROM etl_stg.dim_producto 
    WHERE CAST(FORMAT(Fecha_Carga, 'yyyy-MM-dd HH:mm:ss') AS DATETIME) = @Fecha_Carga_Max;

    -- Contar registros duplicados en ODS
    SELECT @Duplicados = COUNT(*) 
    FROM etl_stg.dim_producto S
    JOIN etl_ods.dim_producto O ON S.ID_Producto = O.ID_Producto
    WHERE CAST(FORMAT(S.Fecha_Carga, 'yyyy-MM-dd HH:mm:ss') AS DATETIME) = @Fecha_Carga_Max;

    -- Insertar datos nuevos en ODS evitando duplicados
    INSERT INTO etl_ods.dim_producto (ID_Producto, Nombre_Producto, Marca, ID_Categoria, Unidad_Medida, Stock_Minimo, Stock_Maximo, Fecha_Carga)
    SELECT S.ID_Producto, S.Nombre_Producto, S.Marca, S.ID_Categoria, S.Unidad_Medida, S.Stock_Minimo, S.Stock_Maximo, GETDATE()
    FROM etl_stg.dim_producto S
    WHERE CAST(FORMAT(S.Fecha_Carga, 'yyyy-MM-dd HH:mm:ss') AS DATETIME) = @Fecha_Carga_Max
    AND NOT EXISTS (SELECT 1 FROM etl_ods.dim_producto O WHERE O.ID_Producto = S.ID_Producto);

    -- Contar registros insertados
    SET @Cargados = @@ROWCOUNT;

    -- Calcular registros rechazados
    SET @Rechazados = @Total_Staging - @Cargados;

    -- Registrar auditoría
    INSERT INTO etl_ods.audit_carga_dim (Nombre_Tabla, Registros_Staging, Registros_Cargados, Registros_Duplicados, Registros_Rechazados, Motivo_Rechazo, Fecha_Carga)
    VALUES ('dim_producto', @Total_Staging, @Cargados, @Duplicados, @Rechazados,
            CASE WHEN @Rechazados > 0 THEN 'Valores nulos o duplicados' ELSE NULL END, 
            GETDATE());
END;
GO

CREATE OR ALTER PROCEDURE etl_ods.sp_cargar_dim_categoria
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total_Staging INT, @Cargados INT, @Duplicados INT, @Rechazados INT;
    DECLARE @Fecha_Carga_Max DATETIME = (
        SELECT MAX(CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120))) 
        FROM etl_stg.dim_categoria
    );

    -- Contar registros en Staging
    SELECT @Total_Staging = COUNT(*) 
    FROM etl_stg.dim_categoria 
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Contar registros duplicados
    SELECT @Duplicados = COUNT(*) 
    FROM etl_stg.dim_categoria S
    JOIN etl_ods.dim_categoria O ON S.ID_Categoria = O.ID_Categoria
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Insertar datos nuevos evitando duplicados
    INSERT INTO etl_ods.dim_categoria (ID_Categoria, Nombre_Categoria, Impuesto_Aplicado, Fecha_Carga)
    SELECT S.ID_Categoria, S.Nombre_Categoria, S.Impuesto_Aplicado, GETDATE()
    FROM etl_stg.dim_categoria S
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max
    AND NOT EXISTS (SELECT 1 FROM etl_ods.dim_categoria O WHERE O.ID_Categoria = S.ID_Categoria);

    -- Contar registros insertados
    SET @Cargados = @@ROWCOUNT;

    -- Calcular registros rechazados
    SET @Rechazados = @Total_Staging - @Cargados;

    -- Registrar auditoría
    INSERT INTO etl_ods.audit_carga_dim (Nombre_Tabla, Registros_Staging, Registros_Cargados, Registros_Duplicados, Registros_Rechazados, Motivo_Rechazo, Fecha_Carga)
    VALUES ('dim_categoria', @Total_Staging, @Cargados, @Duplicados, @Rechazados,
            CASE WHEN @Rechazados > 0 THEN 'Valores nulos o duplicados' ELSE NULL END, 
            GETDATE());
END;
GO

CREATE OR ALTER PROCEDURE etl_ods.sp_cargar_dim_almacen
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total_Staging INT, @Cargados INT, @Duplicados INT, @Rechazados INT;
    DECLARE @Fecha_Carga_Max DATETIME = (
        SELECT MAX(CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120))) 
        FROM etl_stg.dim_almacen
    );

    -- Contar registros en Staging
    SELECT @Total_Staging = COUNT(*) 
    FROM etl_stg.dim_almacen 
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Contar registros duplicados
    SELECT @Duplicados = COUNT(*) 
    FROM etl_stg.dim_almacen S
    JOIN etl_ods.dim_almacen O ON S.ID_Almacen = O.ID_Almacen
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Insertar datos nuevos evitando duplicados
    INSERT INTO etl_ods.dim_almacen (ID_Almacen, Nombre_Almacen, Ubicacion, Capacidad_Maxima, Fecha_Carga)
    SELECT S.ID_Almacen, S.Nombre_Almacen, S.Ubicacion, S.Capacidad_Maxima, GETDATE()
    FROM etl_stg.dim_almacen S
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max
    AND NOT EXISTS (SELECT 1 FROM etl_ods.dim_almacen O WHERE O.ID_Almacen = S.ID_Almacen);

    -- Contar registros insertados
    SET @Cargados = @@ROWCOUNT;

    -- Calcular registros rechazados
    SET @Rechazados = @Total_Staging - @Cargados;

    -- Registrar auditoría
    INSERT INTO etl_ods.audit_carga_dim (Nombre_Tabla, Registros_Staging, Registros_Cargados, Registros_Duplicados, Registros_Rechazados, Motivo_Rechazo, Fecha_Carga)
    VALUES ('dim_almacen', @Total_Staging, @Cargados, @Duplicados, @Rechazados,
            CASE WHEN @Rechazados > 0 THEN 'Valores nulos o duplicados' ELSE NULL END, 
            GETDATE());
END;
GO

CREATE OR ALTER PROCEDURE etl_ods.sp_cargar_dim_empleado
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total_Staging INT, @Cargados INT, @Duplicados INT, @Rechazados INT;
    DECLARE @Fecha_Carga_Max DATETIME = (
        SELECT MAX(CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120))) 
        FROM etl_stg.dim_empleado
    );

    -- Contar registros en Staging
    SELECT @Total_Staging = COUNT(*) 
    FROM etl_stg.dim_empleado 
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Contar registros duplicados
    SELECT @Duplicados = COUNT(*) 
    FROM etl_stg.dim_empleado S
    JOIN etl_ods.dim_empleado O ON S.ID_Empleado = O.ID_Empleado
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Insertar datos nuevos evitando duplicados
    INSERT INTO etl_ods.dim_empleado (ID_Empleado, Nombre_Empleado, Cargo, Turno, Fecha_Carga)
    SELECT S.ID_Empleado, S.Nombre_Empleado, S.Cargo, S.Turno, GETDATE()
    FROM etl_stg.dim_empleado S
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max
    AND NOT EXISTS (SELECT 1 FROM etl_ods.dim_empleado O WHERE O.ID_Empleado = S.ID_Empleado);

    -- Contar registros insertados
    SET @Cargados = @@ROWCOUNT;

    -- Calcular registros rechazados
    SET @Rechazados = @Total_Staging - @Cargados;

    -- Registrar auditoría
    INSERT INTO etl_ods.audit_carga_dim (Nombre_Tabla, Registros_Staging, Registros_Cargados, Registros_Duplicados, Registros_Rechazados, Motivo_Rechazo, Fecha_Carga)
    VALUES ('dim_empleado', @Total_Staging, @Cargados, @Duplicados, @Rechazados,
            CASE WHEN @Rechazados > 0 THEN 'Valores nulos o duplicados' ELSE NULL END, 
            GETDATE());
END;
GO


CREATE OR ALTER PROCEDURE etl_ods.sp_cargar_dim_proveedor
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Total_Staging INT, @Cargados INT, @Duplicados INT, @Rechazados INT;
    DECLARE @Fecha_Carga_Max DATETIME = (
        SELECT MAX(CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120))) 
        FROM etl_stg.dim_proveedor
    );

    -- Contar registros en Staging
    SELECT @Total_Staging = COUNT(*) 
    FROM etl_stg.dim_proveedor 
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Contar registros duplicados
    SELECT @Duplicados = COUNT(*) 
    FROM etl_stg.dim_proveedor S
    JOIN etl_ods.dim_proveedor O ON S.ID_Proveedor = O.ID_Proveedor
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max;

    -- Insertar datos nuevos evitando duplicados
    INSERT INTO etl_ods.dim_proveedor (ID_Proveedor, Nombre_Proveedor, Pais, Tipo_Proveedor, Fecha_Carga)
    SELECT S.ID_Proveedor, S.Nombre_Proveedor, S.Pais, S.Tipo_Proveedor, GETDATE()
    FROM etl_stg.dim_proveedor S
    WHERE CONVERT(DATETIME, CONVERT(CHAR(19), S.Fecha_Carga, 120)) = @Fecha_Carga_Max
    AND NOT EXISTS (SELECT 1 FROM etl_ods.dim_proveedor O WHERE O.ID_Proveedor = S.ID_Proveedor);

    -- Contar registros insertados
    SET @Cargados = @@ROWCOUNT;

    -- Calcular registros rechazados
    SET @Rechazados = @Total_Staging - @Cargados;

    -- Registrar auditoría
    INSERT INTO etl_ods.audit_carga_dim (Nombre_Tabla, Registros_Staging, Registros_Cargados, Registros_Duplicados, Registros_Rechazados, Motivo_Rechazo, Fecha_Carga)
    VALUES ('dim_proveedor', @Total_Staging, @Cargados, @Duplicados, @Rechazados,
            CASE WHEN @Rechazados > 0 THEN 'Valores nulos o duplicados' ELSE NULL END, 
            GETDATE());
END;
GO