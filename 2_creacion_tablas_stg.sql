-- Tabla Staging para Producto
CREATE TABLE etl_stg.dim_producto (
    ID_Producto INT,
    Nombre_Producto VARCHAR(100),
    Marca VARCHAR(50),
    ID_Categoria INT,
    Unidad_Medida VARCHAR(50),
    Stock_Minimo INT,
    Stock_Maximo INT,
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Tabla Staging para Proveedor
CREATE TABLE etl_stg.dim_proveedor (
    ID_Proveedor INT PRIMARY KEY,
    Nombre_Proveedor VARCHAR(100),
    Pais VARCHAR(50),
    Tipo_Proveedor VARCHAR(50),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Tabla Staging para Empleado
CREATE TABLE etl_stg.dim_empleado (
    ID_Empleado INT PRIMARY KEY,
    Nombre_Empleado NVARCHAR(100),
    Cargo NVARCHAR(50),
    Turno NVARCHAR(50),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO


-- Tabla Staging para Almacen
CREATE TABLE etl_stg.dim_almacen (
    ID_Almacen INT PRIMARY KEY,
    Nombre_Almacen NVARCHAR(100),
    Ubicacion NVARCHAR(100),
    Capacidad_Maxima INT,
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO


-- Tabla Staging para Categoria
CREATE TABLE etl_stg.dim_categoria (
    ID_Categoria INT PRIMARY KEY,
    Nombre_Categoria NVARCHAR(100),
    Impuesto_Aplicado DECIMAL(5,2),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO


-- Tabla Staging para Inventario
CREATE TABLE etl_stg.fact_inventario (
    ID_Movimiento INT,  -- Incluido porque está en el CSV
    Fecha_Hora DATETIME,  -- Mantiene la precisión de la fecha y hora
    ID_Producto INT,
    ID_Categoria INT,  -- Incluido porque está en el CSV
    ID_Almacen INT,
    ID_Proveedor INT,
    ID_Empleado INT,
    Tipo_Movimiento VARCHAR(50),  -- Se usará para "Estado"
    Cantidad INT,
    Valor_Unitario DECIMAL(10,2),  -- Equivalente a "Precio_Unitario"
    Valor_Total DECIMAL(10,2),  -- Equivalente a "Costo_Total"
    Fecha_Carga DATETIME DEFAULT GETDATE()  -- Para registrar la fecha de carga
);
GO

-- Creacion tabla de logs 

CREATE TABLE etl_stg.audit_carga (
    ID_Carga INT IDENTITY(1,1) PRIMARY KEY, -- Identificador único de la carga
    Nombre_Archivo NVARCHAR(255), -- Nombre del archivo CSV cargado
    Tabla_Destino NVARCHAR(255), -- Nombre de la tabla donde se insertaron los datos
    Fecha_Carga DATETIME DEFAULT GETDATE(), -- Fecha y hora de la carga
    Registros_Insertados INT, -- Cantidad de registros insertados
    Estado NVARCHAR(50), -- Estado de la carga ('Éxito' o 'Error')
    Mensaje_Error NVARCHAR(MAX), -- Mensaje de error en caso de fallo
    Usuario_Carga NVARCHAR(100) DEFAULT SUSER_NAME() -- Usuario que ejecutó la carga
);
GO