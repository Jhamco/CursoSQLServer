-- Tabla de Proveedor en ODS
CREATE TABLE etl_ods.dim_proveedor (
    ID_Proveedor INT PRIMARY KEY,
    Nombre_Proveedor VARCHAR(100),
    Pais VARCHAR(50),
    Tipo_Proveedor VARCHAR(50),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Tabla de Empleado en ODS
CREATE TABLE etl_ods.dim_empleado (
    ID_Empleado INT PRIMARY KEY,
    Nombre_Empleado NVARCHAR(100),
    Cargo NVARCHAR(50),
    Turno NVARCHAR(50),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Tabla de Almacén en ODS
CREATE TABLE etl_ods.dim_almacen (
    ID_Almacen INT PRIMARY KEY,
    Nombre_Almacen NVARCHAR(100),
    Ubicacion NVARCHAR(100),
    Capacidad_Maxima INT,
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Tabla de Categoría en ODS
CREATE TABLE etl_ods.dim_categoria (
    ID_Categoria INT PRIMARY KEY,
    Nombre_Categoria NVARCHAR(100),
    Impuesto_Aplicado DECIMAL(5,2),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Creacion Tabla auditoria para tablas dim
CREATE TABLE etl_ods.audit_carga_dim (
    ID_Auditoria INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Tabla VARCHAR(100),
    Registros_Staging INT,
    Registros_Cargados INT,
    Registros_Duplicados INT,
    Registros_Rechazados INT,
    Motivo_Rechazo VARCHAR(255),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO

-- Creacion tabla inventario en ODS
CREATE TABLE etl_ods.fact_inventario (
    ID_Fact_Ods INT IDENTITY(1,1) PRIMARY KEY, -- Nuevo ID autoincremental
    ID_Movimiento INT, -- Referencia al Staging
    Fecha_Hora DATETIME,
    ID_Producto INT,
    ID_Categoria INT,
    ID_Almacen INT,
    ID_Proveedor INT,
    ID_Empleado INT,
    Tipo_Movimiento VARCHAR(50),
    Cantidad INT,
    Valor_Unitario DECIMAL(10,2),
    Valor_Total DECIMAL(18,2),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);
GO


-- Creacion tabla auditoria limpieza total
CREATE TABLE etl_ods.audit_limpieza (
    ID_Auditoria INT IDENTITY(1,1) PRIMARY KEY,
    ID_Movimiento INT,
    Fecha_Hora DATETIME,
    ID_Producto INT,
    ID_Categoria INT,
    ID_Almacen INT,
    ID_Proveedor INT,
    ID_Empleado INT,
    Tipo_Movimiento VARCHAR(50),
    Cantidad INT,
    Valor_Unitario DECIMAL(10,2),
    Valor_Total DECIMAL(18,2),
    Motivo_Eliminacion NVARCHAR(255),
    Fecha_Registro DATETIME DEFAULT GETDATE()
);
GO


-- Crear la tabla de auditoría descripcion
CREATE TABLE etl_ods.audit_limpieza_desc (
    ID_Auditoria INT IDENTITY(1,1) PRIMARY KEY,
    Fecha_Proceso DATETIME DEFAULT GETDATE(),
    Registros_Procesados INT,
    Registros_Eliminados INT,
    Registros_Cargados INT
);
GO