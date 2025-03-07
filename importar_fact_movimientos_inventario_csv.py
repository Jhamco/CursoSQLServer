import pandas as pd
import pyodbc
import numpy as np  
import os
import glob
import pyodbc

# Ruta del directorio donde se encuentran los archivos
directorio = "C:\\Temp\\output_csv"

# Buscar todos los archivos que coincidan con el patrón
archivos = glob.glob(os.path.join(directorio, "fact_movimientos_inventario*"))

# Verificar si se encontraron archivos
if archivos:
    # Ordenar los archivos por fecha de modificación (el archivo más reciente será el primero)
    archivo_mas_reciente = max(archivos, key=os.path.getmtime)
    #print(f"El archivo más reciente es: {archivo_mas_reciente}")
else:
    print("No se encontraron archivos con el patrón 'fact_movimientos_inventario*'")

# Conectar a SQL Server
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=CVEOperational;"
    "Trusted_Connection=yes;"
)

# Cargar CSV
df = pd.read_csv(archivo_mas_reciente, sep=',')

# Convertir Fecha_Hora a formato DATE si es necesario
df["Fecha_Hora"] = pd.to_datetime(df["Fecha_Hora"])

# Dejar valores NaN como None (NULL en SQL Server)
df["Cantidad"] = pd.to_numeric(df["Cantidad"], errors='coerce')  # Convertir a numérico, NaN si hay errores
df["Valor_Unitario"] = pd.to_numeric(df["Valor_Unitario"], errors='coerce')  # Convertir a numérico
df["Valor_Total"] = pd.to_numeric(df["Valor_Total"], errors='coerce')  # Convertir a numérico

# Reemplazar valores NaN por None (NULL en SQL Server)
df = df.replace({np.nan: None})

# Ordenar el DataFrame por ID_Movimiento antes de insertar los registros
df = df.sort_values('ID_Movimiento', ascending=True)

# Insertar datos en SQL Server
cursor = conn.cursor()
for index, row in df.iterrows():
    cursor.execute("""
        INSERT INTO etl_stg.fact_inventario (ID_Movimiento, Fecha_Hora, ID_Producto, ID_Categoria, ID_Almacen, ID_Proveedor, ID_Empleado, Tipo_Movimiento, Cantidad, Valor_Unitario, Valor_Total, Fecha_Carga)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
    """, row.ID_Movimiento, row.Fecha_Hora, row.ID_Producto, row.ID_Categoria, row.ID_Almacen, row.ID_Proveedor, row.ID_Empleado, row.Tipo_Movimiento, row.Cantidad, row.Valor_Unitario, row.Valor_Total)

conn.commit()
conn.close()
