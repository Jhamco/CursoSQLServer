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
df = pd.read_csv("C:\\Temp\\dim_empleado.csv", sep=',')

# Insertar datos en SQL Server
cursor = conn.cursor()
for index, row in df.iterrows():
    cursor.execute("""
        INSERT INTO etl_stg.dim_empleado (ID_Empleado, Nombre_Empleado, Cargo, Turno, Fecha_Carga)
        VALUES (?, ?, ?, ?, GETDATE())
    """, row.ID_Empleado, row.Nombre_Empleado, row.Cargo, row.Turno)

conn.commit()
conn.close()
