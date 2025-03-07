import pandas as pd
import pyodbc

try:
    # Conectar a SQL Server
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=localhost;"
        "DATABASE=CVEOperational;"
        "Trusted_Connection=yes;"
    )

    # Cargar CSV
    df = pd.read_csv("C:\\Temp\\dim_producto.csv", sep=',')

    # Insertar datos en SQL Server sin modificar los valores
    cursor = conn.cursor()
    for index, row in df.iterrows():
        cursor.execute("""
            INSERT INTO etl_stg.dim_producto 
            (ID_Producto, Nombre_Producto, Marca, ID_Categoria, Unidad_Medida, Stock_Minimo, Stock_Maximo, Fecha_Carga)
            VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE())
        """, row.ID_Producto, row.Nombre_Producto, row.Marca, row.ID_Categoria, row.Unidad_Medida, row.Stock_Minimo, row.Stock_Maximo)

    # Confirmar la transacción
    conn.commit()
    print("Carga exitosa de dim_producto.csv")

except Exception as e:
    print("Error durante la carga:", e)

finally:
    conn.close()
