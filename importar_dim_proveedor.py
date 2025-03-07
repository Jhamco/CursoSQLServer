import pandas as pd
import pyodbc

# Conectar a SQL Server
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=CVEOperational;"
    "Trusted_Connection=yes;"
)

# Cargar CSV
df = pd.read_csv("C:\\Temp\\dim_proveedor.csv", sep=',')

# Insertar datos en SQL Server
cursor = conn.cursor()
for index, row in df.iterrows():
    cursor.execute("""
        INSERT INTO etl_stg.dim_proveedor (ID_Proveedor, Nombre_Proveedor, Pais, Tipo_Proveedor, Fecha_Carga)
        VALUES (?, ?, ?, ?, GETDATE())
    """, row.ID_Proveedor, row.Nombre_Proveedor, row.Pais_Origen, row.Calificacion)

conn.commit()
conn.close()
