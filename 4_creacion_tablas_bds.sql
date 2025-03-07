
CREATE TABLE etl_bds.fact_inventario (
    ID_Fact_BDS INT IDENTITY(1,1) PRIMARY KEY,
    ID_Movimiento INT NOT NULL,
    Fecha_Hora DATETIME NOT NULL,
    
    ID_Producto INT NOT NULL,
    Nombre_Producto VARCHAR(100) NOT NULL,
    Marca VARCHAR(50) NOT NULL,
    
    ID_Categoria INT NOT NULL,
    Nombre_Categoria VARCHAR(100) NOT NULL,
    Impuesto_Aplicado DECIMAL(5,2) NOT NULL,

    ID_Almacen INT NOT NULL,
    Nombre_Almacen VARCHAR(100) NOT NULL,

    ID_Proveedor INT NOT NULL,
    Nombre_Proveedor VARCHAR(100) NOT NULL,

    ID_Empleado INT NOT NULL,
    Nombre_Empleado VARCHAR(100) NOT NULL,
    Cargo VARCHAR(50) NOT NULL,

    Tipo_Movimiento VARCHAR(20) NOT NULL,  -- Entrada/Salida
    Cantidad INT NOT NULL,
    Valor_Unitario DECIMAL(10,2) NOT NULL,
    Stock_Acumulado INT NOT NULL,  
    Fecha_Carga DATETIME DEFAULT GETDATE(),

    -- Claves Foráneas
    CONSTRAINT FK_fact_producto FOREIGN KEY (ID_Producto) REFERENCES etl_ods.dim_producto(ID_Producto),
    CONSTRAINT FK_fact_categoria FOREIGN KEY (ID_Categoria) REFERENCES etl_ods.dim_categoria(ID_Categoria),
    CONSTRAINT FK_fact_almacen FOREIGN KEY (ID_Almacen) REFERENCES etl_ods.dim_almacen(ID_Almacen),
    CONSTRAINT FK_fact_proveedor FOREIGN KEY (ID_Proveedor) REFERENCES etl_ods.dim_proveedor(ID_Proveedor),
    CONSTRAINT FK_fact_empleado FOREIGN KEY (ID_Empleado) REFERENCES etl_ods.dim_empleado(ID_Empleado)
);
GO

-- Tabla Dimensión Producto
CREATE TABLE etl_bds.dim_producto (
    ID_Producto INT PRIMARY KEY,
    Nombre_Producto VARCHAR(100),
    Marca VARCHAR(50),
    ID_Categoria INT,
    Unidad_Medida VARCHAR(50),
    Stock_Minimo INT,
    Stock_Maximo INT,
    Fecha_Carga DATETIME DEFAULT GETDATE()
);

-- Tabla Dimensión Categoría
CREATE TABLE etl_bds.dim_categoria (
    ID_Categoria INT PRIMARY KEY,
    Nombre_Categoria VARCHAR(100),
    Impuesto_Aplicado DECIMAL(5,2),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);

-- Tabla Dimensión Almacén
CREATE TABLE etl_bds.dim_almacen (
    ID_Almacen INT PRIMARY KEY,
    Nombre_Almacen VARCHAR(100),
    Ubicacion VARCHAR(100),
    Capacidad_Maxima INT,
    Fecha_Carga DATETIME DEFAULT GETDATE()
);

-- Tabla Dimensión Proveedor
CREATE TABLE etl_bds.dim_proveedor (
    ID_Proveedor INT PRIMARY KEY,
    Nombre_Proveedor VARCHAR(100),
    Pais VARCHAR(50),
    Tipo_Proveedor VARCHAR(50),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);

-- Tabla Dimensión Empleado
CREATE TABLE etl_bds.dim_empleado (
    ID_Empleado INT PRIMARY KEY,
    Nombre_Empleado NVARCHAR(100),
    Cargo NVARCHAR(50),
    Turno NVARCHAR(50),
    Fecha_Carga DATETIME DEFAULT GETDATE()
);