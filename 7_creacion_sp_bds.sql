CREATE OR ALTER PROCEDURE etl_bds.sp_cargar_fact_inventario
AS
BEGIN
    SET NOCOUNT ON;

    MERGE etl_bds.fact_inventario AS target
    USING (
        SELECT 
            f.ID_Movimiento,
            f.Fecha_Hora,
            p.ID_Producto,
            p.Nombre_Producto,
            p.Marca,
            c.ID_Categoria,
            c.Nombre_Categoria,
            c.Impuesto_Aplicado,
            a.ID_Almacen,
            a.Nombre_Almacen,
            v.ID_Proveedor,
            v.Nombre_Proveedor,
            e.ID_Empleado,
            e.Nombre_Empleado,
            e.Cargo,
            f.Tipo_Movimiento,
            f.Cantidad,
            f.Valor_Unitario,
            -- Cálculo del stock acumulado por producto en el almacén
            COALESCE((  
                SELECT SUM(CASE WHEN f2.Tipo_Movimiento = 'Entrada' THEN f2.Cantidad ELSE -f2.Cantidad END) 
                FROM etl_ods.fact_inventario f2
                WHERE f2.ID_Producto = f.ID_Producto
                  AND f2.ID_Almacen = f.ID_Almacen
                  AND f2.Fecha_Hora <= f.Fecha_Hora
            ), 0) AS Stock_Acumulado
        FROM etl_ods.fact_inventario f
        INNER JOIN etl_ods.dim_producto p ON f.ID_Producto = p.ID_Producto
        INNER JOIN etl_ods.dim_categoria c ON f.ID_Categoria = c.ID_Categoria
        INNER JOIN etl_ods.dim_almacen a ON f.ID_Almacen = a.ID_Almacen
        INNER JOIN etl_ods.dim_proveedor v ON f.ID_Proveedor = v.ID_Proveedor
        INNER JOIN etl_ods.dim_empleado e ON f.ID_Empleado = e.ID_Empleado
    ) AS source
    ON target.ID_Movimiento = source.ID_Movimiento  -- Control de duplicados por ID de movimiento
    WHEN MATCHED AND (
        target.Fecha_Hora <> source.Fecha_Hora OR
        target.ID_Producto <> source.ID_Producto OR
        target.Nombre_Producto <> source.Nombre_Producto OR
        target.Marca <> source.Marca OR
        target.ID_Categoria <> source.ID_Categoria OR
        target.Nombre_Categoria <> source.Nombre_Categoria OR
        target.Impuesto_Aplicado <> source.Impuesto_Aplicado OR
        target.ID_Almacen <> source.ID_Almacen OR
        target.Nombre_Almacen <> source.Nombre_Almacen OR
        target.ID_Proveedor <> source.ID_Proveedor OR
        target.Nombre_Proveedor <> source.Nombre_Proveedor OR
        target.ID_Empleado <> source.ID_Empleado OR
        target.Nombre_Empleado <> source.Nombre_Empleado OR
        target.Cargo <> source.Cargo OR
        target.Tipo_Movimiento <> source.Tipo_Movimiento OR
        target.Cantidad <> source.Cantidad OR
        target.Valor_Unitario <> source.Valor_Unitario OR
        target.Stock_Acumulado <> source.Stock_Acumulado
    ) THEN 
        UPDATE SET 
            target.Fecha_Hora = source.Fecha_Hora,
            target.ID_Producto = source.ID_Producto,
            target.Nombre_Producto = source.Nombre_Producto,
            target.Marca = source.Marca,
            target.ID_Categoria = source.ID_Categoria,
            target.Nombre_Categoria = source.Nombre_Categoria,
            target.Impuesto_Aplicado = source.Impuesto_Aplicado,
            target.ID_Almacen = source.ID_Almacen,
            target.Nombre_Almacen = source.Nombre_Almacen,
            target.ID_Proveedor = source.ID_Proveedor,
            target.Nombre_Proveedor = source.Nombre_Proveedor,
            target.ID_Empleado = source.ID_Empleado,
            target.Nombre_Empleado = source.Nombre_Empleado,
            target.Cargo = source.Cargo,
            target.Tipo_Movimiento = source.Tipo_Movimiento,
            target.Cantidad = source.Cantidad,
            target.Valor_Unitario = source.Valor_Unitario,
            target.Stock_Acumulado = source.Stock_Acumulado,
            target.Fecha_Carga = GETDATE()
    WHEN NOT MATCHED THEN 
        INSERT (ID_Movimiento, Fecha_Hora, ID_Producto, Nombre_Producto, Marca, 
                ID_Categoria, Nombre_Categoria, Impuesto_Aplicado, 
                ID_Almacen, Nombre_Almacen, ID_Proveedor, Nombre_Proveedor, 
                ID_Empleado, Nombre_Empleado, Cargo, Tipo_Movimiento, 
                Cantidad, Valor_Unitario, Stock_Acumulado, Fecha_Carga)
        VALUES (source.ID_Movimiento, source.Fecha_Hora, source.ID_Producto, source.Nombre_Producto, source.Marca, 
                source.ID_Categoria, source.Nombre_Categoria, source.Impuesto_Aplicado, 
                source.ID_Almacen, source.Nombre_Almacen, source.ID_Proveedor, source.Nombre_Proveedor, 
                source.ID_Empleado, source.Nombre_Empleado, source.Cargo, source.Tipo_Movimiento, 
                source.Cantidad, source.Valor_Unitario, source.Stock_Acumulado, GETDATE());

    PRINT 'Carga de datos a fact_inventario completada exitosamente.';
END;
GO

-- SP para cargar dimensiones
CREATE PROCEDURE etl_bds.sp_cargar_dimensiones
AS
BEGIN
    SET NOCOUNT ON;

    -- Actualizar o insertar datos en dim_producto
    MERGE etl_bds.dim_producto AS target
    USING etl_ods.dim_producto AS source
    ON target.ID_Producto = source.ID_Producto
    WHEN MATCHED THEN 
        UPDATE SET 
            target.Nombre_Producto = source.Nombre_Producto,
            target.Marca = source.Marca,
            target.ID_Categoria = source.ID_Categoria,
            target.Unidad_Medida = source.Unidad_Medida,
            target.Stock_Minimo = source.Stock_Minimo,
            target.Stock_Maximo = source.Stock_Maximo,
            target.Fecha_Carga = GETDATE()
    WHEN NOT MATCHED THEN 
        INSERT (ID_Producto, Nombre_Producto, Marca, ID_Categoria, Unidad_Medida, Stock_Minimo, Stock_Maximo, Fecha_Carga)
        VALUES (source.ID_Producto, source.Nombre_Producto, source.Marca, source.ID_Categoria, source.Unidad_Medida, source.Stock_Minimo, source.Stock_Maximo, GETDATE());

    -- Actualizar o insertar datos en dim_categoria
    MERGE etl_bds.dim_categoria AS target
    USING etl_ods.dim_categoria AS source
    ON target.ID_Categoria = source.ID_Categoria
    WHEN MATCHED THEN 
        UPDATE SET 
            target.Nombre_Categoria = source.Nombre_Categoria,
            target.Impuesto_Aplicado = source.Impuesto_Aplicado,
            target.Fecha_Carga = GETDATE()
    WHEN NOT MATCHED THEN 
        INSERT (ID_Categoria, Nombre_Categoria, Impuesto_Aplicado, Fecha_Carga)
        VALUES (source.ID_Categoria, source.Nombre_Categoria, source.Impuesto_Aplicado, GETDATE());

    -- Actualizar o insertar datos en dim_almacen
    MERGE etl_bds.dim_almacen AS target
    USING etl_ods.dim_almacen AS source
    ON target.ID_Almacen = source.ID_Almacen
    WHEN MATCHED THEN 
        UPDATE SET 
            target.Nombre_Almacen = source.Nombre_Almacen,
            target.Ubicacion = source.Ubicacion,
            target.Capacidad_Maxima = source.Capacidad_Maxima,
            target.Fecha_Carga = GETDATE()
    WHEN NOT MATCHED THEN 
        INSERT (ID_Almacen, Nombre_Almacen, Ubicacion, Capacidad_Maxima, Fecha_Carga)
        VALUES (source.ID_Almacen, source.Nombre_Almacen, source.Ubicacion, source.Capacidad_Maxima, GETDATE());

    -- Actualizar o insertar datos en dim_proveedor
    MERGE etl_bds.dim_proveedor AS target
    USING etl_ods.dim_proveedor AS source
    ON target.ID_Proveedor = source.ID_Proveedor
    WHEN MATCHED THEN 
        UPDATE SET 
            target.Nombre_Proveedor = source.Nombre_Proveedor,
            target.Pais = source.Pais,
            target.Tipo_Proveedor = source.Tipo_Proveedor,
            target.Fecha_Carga = GETDATE()
    WHEN NOT MATCHED THEN 
        INSERT (ID_Proveedor, Nombre_Proveedor, Pais, Tipo_Proveedor, Fecha_Carga)
        VALUES (source.ID_Proveedor, source.Nombre_Proveedor, source.Pais, source.Tipo_Proveedor, GETDATE());

    -- Actualizar o insertar datos en dim_empleado
    MERGE etl_bds.dim_empleado AS target
    USING etl_ods.dim_empleado AS source
    ON target.ID_Empleado = source.ID_Empleado
    WHEN MATCHED THEN 
        UPDATE SET 
            target.Nombre_Empleado = source.Nombre_Empleado,
            target.Cargo = source.Cargo,
            target.Turno = source.Turno,
            target.Fecha_Carga = GETDATE()
    WHEN NOT MATCHED THEN 
        INSERT (ID_Empleado, Nombre_Empleado, Cargo, Turno, Fecha_Carga)
        VALUES (source.ID_Empleado, source.Nombre_Empleado, source.Cargo, source.Turno, GETDATE());

    PRINT 'Carga de dimensiones completada exitosamente.';
END;
GO