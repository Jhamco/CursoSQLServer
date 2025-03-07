-- Vista de Ventas Totales por Producto y Fecha
CREATE VIEW etl_bds.v_ventas_totales AS
SELECT 
	CONVERT(DATE, f.Fecha_Hora) AS Fecha,
    p.Nombre_Producto, 
    p.Marca, 
    SUM(f.Cantidad) AS Total_Vendido
FROM etl_bds.fact_inventario f
JOIN etl_ods.dim_producto p ON f.ID_Producto = p.ID_Producto
WHERE f.Tipo_Movimiento = 'Salida'
GROUP BY CONVERT(DATE, f.Fecha_Hora), p.Nombre_Producto, p.Marca;

-- Vista de Empleados con Más Movimientos
CREATE VIEW etl_bds.v_movimientos_empleado AS
SELECT 
    e.Nombre_Empleado, 
    e.Cargo, 
    COUNT(f.ID_Fact_BDS) AS Movimientos_Registrados
FROM etl_bds.fact_inventario f
JOIN etl_ods.dim_empleado e ON f.ID_Empleado = e.ID_Empleado
GROUP BY e.Nombre_Empleado, e.Cargo;

-- Top 10 productos mas vendidos
CREATE VIEW etl_bds.v_top10_productos_mas_vendidos AS
SELECT TOP 10
    p.Nombre_Producto,
    c.Nombre_Categoria,
    SUM(f.Cantidad) AS Total_Ventas,
    SUM(f.Cantidad * f.Valor_Unitario) AS Ingresos_Totales
FROM etl_bds.fact_inventario f
JOIN etl_ods.dim_producto p ON f.ID_Producto = p.ID_Producto
JOIN etl_ods.dim_categoria c ON p.ID_Categoria = c.ID_Categoria
WHERE f.Tipo_Movimiento = 'Salida'  -- Solo considerar ventas (salidas de stock)
GROUP BY p.Nombre_Producto, c.Nombre_Categoria

-- Categorias mas vendidas
CREATE VIEW etl_bds.v_categorias_mas_vendidas AS
SELECT 
    c.Nombre_Categoria, 
    SUM(f.Cantidad) AS Total_Ventas
FROM etl_bds.fact_inventario f
JOIN etl_ods.dim_categoria c ON f.ID_Categoria = c.ID_Categoria
WHERE f.Tipo_Movimiento = 'Salida'
GROUP BY c.Nombre_Categoria