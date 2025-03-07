import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
import os
import glob

# Configurar Faker en español
fake = Faker('es_ES')

# Directorio de salida
output_dir = "C:\Temp\output_csv"
os.makedirs(output_dir, exist_ok=True)

# 📌 1️⃣ Obtener el último archivo de la tabla de hechos
fact_pattern = os.path.join(output_dir, "fact_movimientos_inventario*.csv")
fact_files = sorted(glob.glob(fact_pattern))  # Ordenar por nombre (fechas crecientes)

if fact_files:
    last_fact_file = fact_files[-1]  # Último archivo generado
    df_fact = pd.read_csv(last_fact_file)
    last_id = df_fact["ID_Movimiento"].max()
else:
    print("No se encontró un archivo anterior. Generando datos desde ID 1.")
    last_id = 0

# 📌 2️⃣ Cargar las dimensiones existentes
df_producto = pd.read_csv(os.path.join(output_dir, "dim_producto.csv"))
df_categoria = pd.read_csv(os.path.join(output_dir, "dim_categoria.csv"))
df_almacen = pd.read_csv(os.path.join(output_dir, "dim_almacen.csv"))
df_proveedor = pd.read_csv(os.path.join(output_dir, "dim_proveedor.csv"))
df_empleado = pd.read_csv(os.path.join(output_dir, "dim_empleado.csv"))

# 📌 3️⃣ Generar nuevos registros de movimientos de inventario con errores intencionales
num_nuevos_registros = 500
fact_movimientos = []

for i in range(1, num_nuevos_registros + 1):
    id_producto = random.choice(df_producto["ID_Producto"].tolist())
    id_categoria = df_producto.loc[df_producto["ID_Producto"] == id_producto, "ID_Categoria"].values[0]  
    id_almacen = random.choice(df_almacen["ID_Almacen"].tolist())

    # Simular valores nulos en ID_Proveedor y ID_Empleado (10% de los registros)
    id_proveedor = random.choice(df_proveedor["ID_Proveedor"].tolist()) if random.random() > 0.1 else None
    id_empleado = random.choice(df_empleado["ID_Empleado"].tolist()) if random.random() > 0.1 else None

    # Introducir errores tipográficos en "Tipo_Movimiento" (5% de los registros)
    tipo_movimiento = random.choice(["Entrada", "Salida"])
    if random.random() < 0.05:
        tipo_movimiento = "Enrtrada" if tipo_movimiento == "Entrada" else "Salid"

    # Simular valores negativos o extremos en cantidad y valor unitario (5% de los registros)
    cantidad = random.randint(1, 100)
    valor_unitario = round(random.uniform(10, 500), 2)
    if random.random() < 0.05:
        cantidad *= -1  # Negativo
        valor_unitario *= 10  # Valor extremo

    valor_total = round(cantidad * valor_unitario, 2)

    # Introducir fechas incorrectas en un pequeño porcentaje de registros
    if random.random() < 0.03:
        fecha_hora = datetime.now() - timedelta(days=random.randint(31, 35))  # Días fuera de rango
    else:
        fecha_hora = datetime.now() - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23), minutes=random.randint(0, 59))

    fact_movimientos.append([
        last_id + i, fecha_hora, id_producto, id_categoria, id_almacen, id_proveedor, id_empleado, tipo_movimiento, cantidad, valor_unitario, valor_total
    ])

df_fact_new = pd.DataFrame(fact_movimientos, columns=[
    "ID_Movimiento", "Fecha_Hora", "ID_Producto", "ID_Categoria", "ID_Almacen", "ID_Proveedor", "ID_Empleado",
    "Tipo_Movimiento", "Cantidad", "Valor_Unitario", "Valor_Total"
])

# 📌 4️⃣ Generar el nombre del archivo con la hora como número entero
hora_actual = datetime.now().strftime("%y%m%d_%H")  # Extrae solo los números de la hora
fact_filename = f"fact_movimientos_inventario_{hora_actual}.csv"

# 📌 5️⃣ Guardar el archivo
df_fact_new.to_csv(os.path.join(output_dir, fact_filename), index=False)

print(f"Archivo generado: {fact_filename} con {num_nuevos_registros} registros con errores intencionales.")
