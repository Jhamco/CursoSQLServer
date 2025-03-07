import pandas as pd
import pyodbc

# Conexión a SQL Server
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=CVEOperational;"
    "Trusted_Connection=yes;"
)

# Cargar CSV
df = pd.read_csv("C:\\Temp\\dim_almacen.csv", sep=',')

# Insertar datos en SQL Server
cursor = conn.cursor()
for index, row in df.iterrows():
    cursor.execute("""
        INSERT INTO etl_stg.dim_almacen (ID_Almacen, Nombre_Almacen, Ubicacion, Capacidad_Maxima, Fecha_Carga)
        VALUES (?, ?, ?, ?, GETDATE())
    """, row.ID_Almacen, row.Nombre_Almacen, row.Ubicacion, row.Capacidad_Maxima)

conn.commit()
conn.close()
