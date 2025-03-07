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
df = pd.read_csv("C:\\Temp\\dim_categoria.csv", sep=',')

# Insertar datos en SQL Server
cursor = conn.cursor()
for index, row in df.iterrows():
    cursor.execute("""
        INSERT INTO etl_stg.dim_categoria (ID_Categoria, Nombre_Categoria, Impuesto_Aplicado, Fecha_Carga)
        VALUES (?, ?, ?, GETDATE())
    """, row.ID_Categoria, row.Nombre_Categoria, row.Impuesto_Aplicado)

conn.commit()
conn.close()
