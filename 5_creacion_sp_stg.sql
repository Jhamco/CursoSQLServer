-- Creacion SP carga  fact_inventario
CREATE PROCEDURE etl_stg.sp_cargar_fact_inventario
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar variables
    DECLARE @Comando VARCHAR(4000);
    DECLARE @NombreArchivo NVARCHAR(255);
    DECLARE @ID_Carga INT;
    DECLARE @RegistrosInsertados INT;
    DECLARE @Error NVARCHAR(MAX);
    DECLARE @TablaDestino NVARCHAR(255) = 'etl_stg.fact_inventario'; -- Definir la tabla destino

    -- Crear una tabla temporal para capturar la salida de xp_cmdshell
    DECLARE @Salida TABLE (Salida NVARCHAR(MAX));

    -- Definir el nombre del archivo cargado (esto debería venir de tu script Python)
    SET @NombreArchivo = 'fact_movimientos_inventario.csv'; 

    -- Insertar el inicio de la carga en la tabla de auditoría
    INSERT INTO etl_stg.audit_carga (Nombre_Archivo, Estado, Tabla_Destino, Mensaje_Error)
    VALUES (@NombreArchivo, 'En proceso', @TablaDestino, NULL);

    SET @ID_Carga = SCOPE_IDENTITY();

    -- Definir el comando para ejecutar Python
    SET @Comando = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe C:\Temp\importar_fact_movimientos_inventario_csv.py';

    -- Ejecutar Python y capturar salida
    INSERT INTO @Salida (Salida)
    EXEC xp_cmdshell @Comando;

    -- Verificar si hubo un error en la ejecución de Python
    SELECT TOP 1 @Error = Salida FROM @Salida WHERE Salida IS NOT NULL;

    IF @Error IS NOT NULL
    BEGIN
        -- Registrar el error en la auditoría
        UPDATE etl_stg.audit_carga
        SET Estado = 'Error', Mensaje_Error = @Error
        WHERE ID_Carga = @ID_Carga;

        RETURN;
    END;

    -- Contar los registros insertados en la tabla de destino
    SELECT @RegistrosInsertados = COUNT(*) FROM etl_stg.fact_inventario
    WHERE Fecha_Carga >= (SELECT Fecha_Carga FROM etl_stg.audit_carga WHERE ID_Carga = @ID_Carga);

    -- Actualizar la auditoría con el resultado de la carga
    UPDATE etl_stg.audit_carga
    SET Estado = 'Éxito', Registros_Insertados = @RegistrosInsertados
    WHERE ID_Carga = @ID_Carga;
END;
GO


-- Creacion SP carga dim_producto
CREATE PROCEDURE etl_stg.sp_cargar_dim_producto
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Comando NVARCHAR(4000);
    DECLARE @NombreArchivo NVARCHAR(255) = 'dim_producto.csv';
    DECLARE @ID_Carga INT;
    DECLARE @RegistrosInsertados INT;
    DECLARE @Error NVARCHAR(MAX);

    -- Insertar auditoría de inicio
    INSERT INTO etl_stg.audit_carga(Nombre_Archivo, Tabla_Destino, Estado, Mensaje_Error)
    VALUES (@NombreArchivo, 'etl_stg.dim_producto', 'En proceso', NULL);
    
    SET @ID_Carga = SCOPE_IDENTITY();
    
    -- Ejecutar el script de carga con Python
    SET @Comando = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe C:\Temp\importar_dim_producto.py';
    
    DECLARE @Salida TABLE (Salida NVARCHAR(MAX));
    INSERT INTO @Salida EXEC xp_cmdshell @Comando;

    -- Verificar si hubo error
    SELECT @Error = Salida FROM @Salida WHERE Salida LIKE '%Traceback%';

    IF @Error IS NOT NULL
    BEGIN
        UPDATE etl_stg.audit_carga
        SET Estado = 'Error', Mensaje_Error = @Error
        WHERE ID_Carga = @ID_Carga;
        
        RETURN;
    END;

    -- Contar registros insertados
    SELECT @RegistrosInsertados = COUNT(*) FROM etl_stg.dim_producto WHERE Fecha_Carga >= (SELECT Fecha_Carga FROM etl_stg.audit_carga WHERE ID_Carga = @ID_Carga);

    -- Actualizar auditoría
    UPDATE etl_stg.audit_carga
    SET Estado = 'Éxito', Registros_Insertados = @RegistrosInsertados
    WHERE ID_Carga = @ID_Carga;
END;
GO

-- Creacion SP carga dim_proveedor
CREATE PROCEDURE etl_stg.sp_cargar_dim_proveedor
AS
BEGIN
    SET NOCOUNT ON;

    -- Declarar variables
    DECLARE @Comando NVARCHAR(4000);
    DECLARE @NombreArchivo NVARCHAR(255);
    DECLARE @ID_Carga INT;
    DECLARE @RegistrosInsertados INT;
    DECLARE @Error NVARCHAR(MAX);
    
    -- Tabla para capturar la salida del comando
    DECLARE @Salida TABLE (Salida NVARCHAR(MAX));

    -- Nombre del archivo (esto debería venir desde el script Python)
    SET @NombreArchivo = 'dim_proveedor.csv';

    -- Insertar registro en auditoría
    INSERT INTO etl_stg.audit_carga (Nombre_Archivo, Tabla_Destino, Estado, Mensaje_Error)
    VALUES (@NombreArchivo, 'etl_stg.dim_proveedor', 'En proceso', NULL);

    SET @ID_Carga = SCOPE_IDENTITY();

    -- Definir el comando para ejecutar Python
    SET @Comando = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe C:\Temp\importar_dim_proveedor.py';

    -- Ejecutar Python y capturar salida
    INSERT INTO @Salida (Salida)
    EXEC xp_cmdshell @Comando;

    -- Verificar si hubo error en la ejecución
    SELECT @Error = Salida FROM @Salida WHERE Salida LIKE '%Traceback%';

    IF @Error IS NOT NULL
    BEGIN
        -- Registrar error en auditoría
        UPDATE etl_stg.audit_carga
        SET Estado = 'Error', Mensaje_Error = @Error
        WHERE ID_Carga = @ID_Carga;

        RETURN;
    END;

    -- Contar registros insertados
    SELECT @RegistrosInsertados = COUNT(*) FROM etl_stg.dim_proveedor
    WHERE Fecha_Carga >= (SELECT Fecha_Carga FROM etl_stg.audit_carga WHERE ID_Carga = @ID_Carga);

    -- Actualizar auditoría con resultado
    UPDATE etl_stg.audit_carga
    SET Estado = 'Éxito', Registros_Insertados = @RegistrosInsertados
    WHERE ID_Carga = @ID_Carga;
END;
GO

-- Creacion SP carga dim_empleado
CREATE PROCEDURE etl_stg.sp_cargar_dim_empleado
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Comando NVARCHAR(4000);
    DECLARE @NombreArchivo NVARCHAR(255);
    DECLARE @ID_Carga INT;
    DECLARE @RegistrosInsertados INT;
    DECLARE @Error NVARCHAR(MAX);

    -- Tabla temporal para capturar la salida de xp_cmdshell
    DECLARE @Salida TABLE (Salida NVARCHAR(MAX));

    -- Nombre del archivo (ajustar si se puede obtener desde Python)
    SET @NombreArchivo = 'dim_empleado.csv';

    -- Insertar registro en la tabla de auditoría
    INSERT INTO etl_stg.audit_carga (Nombre_Archivo, Tabla_Destino, Estado, Mensaje_Error)
    VALUES (@NombreArchivo, 'etl_stg.dim_empleado', 'En proceso', NULL);

    SET @ID_Carga = SCOPE_IDENTITY();

    -- Comando para ejecutar Python
    SET @Comando = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe C:\Temp\importar_dim_empleado.py';

    -- Ejecutar Python y capturar salida
    INSERT INTO @Salida (Salida)
    EXEC xp_cmdshell @Comando;

    -- Verificar si hubo un error
    SELECT @Error = Salida FROM @Salida WHERE Salida LIKE '%Traceback%';

    IF @Error IS NOT NULL
    BEGIN
        UPDATE etl_stg.audit_carga
        SET Estado = 'Error', Mensaje_Error = @Error
        WHERE ID_Carga = @ID_Carga;

        RETURN;
    END

    -- Contar registros insertados
    SELECT @RegistrosInsertados = COUNT(*) FROM etl_stg.dim_empleado
    WHERE Fecha_Carga >= (SELECT Fecha_Carga FROM etl_stg.audit_carga WHERE ID_Carga = @ID_Carga);

    -- Actualizar auditoría con el resultado
    UPDATE etl_stg.audit_carga
    SET Estado = 'Éxito', Registros_Insertados = @RegistrosInsertados
    WHERE ID_Carga = @ID_Carga;
END;
GO

-- Creacion SP carga dim_almacen
CREATE PROCEDURE etl_stg.sp_cargar_dim_almacen
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Comando NVARCHAR(4000);
    DECLARE @NombreArchivo NVARCHAR(255);
    DECLARE @ID_Carga INT;
    DECLARE @RegistrosInsertados INT;
    DECLARE @Error NVARCHAR(MAX);

    -- Tabla temporal para capturar la salida de xp_cmdshell
    DECLARE @Salida TABLE (Salida NVARCHAR(MAX));

    -- Nombre del archivo (ajustar si se puede obtener desde Python)
    SET @NombreArchivo = 'dim_almacen.csv';

    -- Insertar registro en la tabla de auditoría
    INSERT INTO etl_stg.audit_carga (Nombre_Archivo, Tabla_Destino, Estado, Mensaje_Error)
    VALUES (@NombreArchivo, 'etl_stg.dim_almacen', 'En proceso', NULL);

    SET @ID_Carga = SCOPE_IDENTITY();

    -- Comando para ejecutar Python
    SET @Comando = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe C:\Temp\importar_dim_almacen.py';

    -- Ejecutar Python y capturar salida
    INSERT INTO @Salida (Salida)
    EXEC xp_cmdshell @Comando;

    -- Verificar si hubo un error
    SELECT @Error = Salida FROM @Salida WHERE Salida LIKE '%Traceback%';

    IF @Error IS NOT NULL
    BEGIN
        UPDATE etl_stg.audit_carga
        SET Estado = 'Error', Mensaje_Error = @Error
        WHERE ID_Carga = @ID_Carga;

        RETURN;
    END

    -- Contar registros insertados
    SELECT @RegistrosInsertados = COUNT(*) FROM etl_stg.dim_almacen
    WHERE Fecha_Carga >= (SELECT Fecha_Carga FROM etl_stg.audit_carga WHERE ID_Carga = @ID_Carga);

    -- Actualizar auditoría con el resultado
    UPDATE etl_stg.audit_carga
    SET Estado = 'Éxito', Registros_Insertados = @RegistrosInsertados
    WHERE ID_Carga = @ID_Carga;
END;
GO

-- Creacion SP carga dim_categoria
CREATE PROCEDURE etl_stg.sp_cargar_dim_categoria
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Comando NVARCHAR(4000);
    DECLARE @NombreArchivo NVARCHAR(255);
    DECLARE @ID_Carga INT;
    DECLARE @RegistrosInsertados INT;
    DECLARE @Error NVARCHAR(MAX);

    -- Tabla temporal para capturar la salida de xp_cmdshell
    DECLARE @Salida TABLE (Salida NVARCHAR(MAX));

    -- Nombre del archivo (ajustar si se puede obtener desde Python)
    SET @NombreArchivo = 'dim_categoria.csv';

    -- Insertar registro en la tabla de auditoría
    INSERT INTO etl_stg.audit_carga (Nombre_Archivo, Tabla_Destino, Estado, Mensaje_Error)
    VALUES (@NombreArchivo, 'etl_stg.dim_categoria', 'En proceso', NULL);

    SET @ID_Carga = SCOPE_IDENTITY();

    -- Comando para ejecutar Python
    SET @Comando = 'C:\Users\Administrator\AppData\Local\Programs\Python\Python313\python.exe C:\Temp\importar_dim_categoria.py';

    -- Ejecutar Python y capturar salida
    INSERT INTO @Salida (Salida)
    EXEC xp_cmdshell @Comando;

    -- Verificar si hubo un error
    SELECT @Error = Salida FROM @Salida WHERE Salida LIKE '%Traceback%';

    IF @Error IS NOT NULL
    BEGIN
        UPDATE etl_stg.audit_carga
        SET Estado = 'Error', Mensaje_Error = @Error
        WHERE ID_Carga = @ID_Carga;

        RETURN;
    END

    -- Contar registros insertados
    SELECT @RegistrosInsertados = COUNT(*) FROM etl_stg.dim_categoria
    WHERE Fecha_Carga >= (SELECT Fecha_Carga FROM etl_stg.audit_carga WHERE ID_Carga = @ID_Carga);

    -- Actualizar auditoría con el resultado
    UPDATE etl_stg.audit_carga
    SET Estado = 'Éxito', Registros_Insertados = @RegistrosInsertados
    WHERE ID_Carga = @ID_Carga;
END;
GO