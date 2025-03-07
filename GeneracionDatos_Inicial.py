import pandas as pd
import numpy as np
from faker import Faker
from datetime import datetime, timedelta
import random
import os

# Configurar Faker en español
fake = Faker('es_ES')

# Obtener la fecha y hora actual para los nombres de archivo
timestamp_str = datetime.now().strftime("%Y-%m-%d_%H-%M")

# 📌 1️⃣ Generar Categorías de Productos
categorias = [
    (1, "Electrodomésticos"), 
    (2, "Ropa y Calzado"), 
    (3, "Alimentos y Bebidas"), 
    (4, "Juguetes y Juegos"), 
    (5, "Muebles y Decoración")
]
df_categoria = pd.DataFrame(categorias, columns=["ID_Categoria", "Nombre_Categoria"])
df_categoria["Impuesto_Aplicado"] = [18, 12, 5, 15, 20]  # Impuestos ficticios

# 📌 2️⃣ Generar Productos Asociados a Categorías
productos_lista = []
for cat_id, nombres in enumerate([
    ["Refrigerador", "Microondas", "Licuadora", "Lavadora", "Televisor"],
    ["Zapatos deportivos", "Jeans", "Camiseta", "Chaqueta", "Sombrero"],
    ["Arroz", "Cerveza", "Jugo de naranja", "Papas fritas", "Chocolate"],
    ["Muñeca", "Auto de juguete", "Lego", "Rompecabezas", "Pelota"],
    ["Sofá", "Mesa de centro", "Silla de oficina", "Estantería", "Lámpara"]
], start=1):
    for i, nombre in enumerate(nombres, start=1):
        productos_lista.append([
            cat_id * 10 + i,  # ID de producto único
            nombre,
            fake.company(),  # Marca ficticia
            cat_id,  # 📌 Relación correcta con ID_Categoria
            random.choice(["Unidad", "Kg", "Litros"]),
            random.randint(5, 20),  # Stock mínimo
            random.randint(50, 200)  # Stock máximo
        ])
df_producto = pd.DataFrame(productos_lista, columns=["ID_Producto", "Nombre_Producto", "Marca", "ID_Categoria", "Unidad_Medida", "Stock_Minimo", "Stock_Maximo"])

# 📌 3️⃣ Generar Almacenes
almacenes = []
for i in range(1, 6):
    almacenes.append([
        i,
        f"Almacén {i}",
        fake.city(),
        random.randint(1000, 5000)  # Capacidad máxima
    ])
df_almacen = pd.DataFrame(almacenes, columns=["ID_Almacen", "Nombre_Almacen", "Ubicacion", "Capacidad_Maxima"])

# 📌 4️⃣ Generar Proveedores
proveedores = []
for i in range(1, 6):
    proveedores.append([
        i,
        fake.company(),
        fake.country(),
        random.choice(["A", "B", "C"])  # Calificación del proveedor
    ])
df_proveedor = pd.DataFrame(proveedores, columns=["ID_Proveedor", "Nombre_Proveedor", "Pais_Origen", "Calificacion"])

# 📌 5️⃣ Generar Empleados
empleados = []
for i in range(1, 6):
    empleados.append([
        i,
        fake.name(),
        random.choice(["Almacenero", "Supervisor", "Gerente"]),
        random.choice(["Mañana", "Tarde", "Noche"])
    ])
df_empleado = pd.DataFrame(empleados, columns=["ID_Empleado", "Nombre_Empleado", "Cargo", "Turno"])

# 📌 6️⃣ Generar Movimientos de Inventario (Tabla de Hechos)
num_registros = 1000
fact_movimientos = []

for i in range(1, num_registros + 1):
    id_producto = random.choice(df_producto["ID_Producto"].tolist())
    id_categoria = df_producto.loc[df_producto["ID_Producto"] == id_producto, "ID_Categoria"].values[0]  # 📌 Corrección aquí
    id_almacen = random.choice(df_almacen["ID_Almacen"].tolist())
    id_proveedor = random.choice(df_proveedor["ID_Proveedor"].tolist())
    id_empleado = random.choice(df_empleado["ID_Empleado"].tolist())

    fecha_hora = datetime.now() - timedelta(days=random.randint(0, 30), hours=random.randint(0, 23), minutes=random.randint(0, 59))
    tipo_movimiento = random.choice(["Entrada", "Salida"])
    cantidad = random.randint(1, 100)
    valor_unitario = round(random.uniform(10, 500), 2)
    valor_total = round(cantidad * valor_unitario, 2)

    fact_movimientos.append([
        i, fecha_hora, id_producto, id_categoria, id_almacen, id_proveedor, id_empleado, tipo_movimiento, cantidad, valor_unitario, valor_total
    ])

df_fact = pd.DataFrame(fact_movimientos, columns=[
    "ID_Movimiento", "Fecha_Hora", "ID_Producto", "ID_Categoria", "ID_Almacen", "ID_Proveedor", "ID_Empleado",
    "Tipo_Movimiento", "Cantidad", "Valor_Unitario", "Valor_Total"
])

# 📌 Guardar archivos CSV
output_dir = "output_csv"
os.makedirs(output_dir, exist_ok=True)

df_fact.to_csv(f"{output_dir}/fact_movimientos_inventario.csv", index=False)
df_producto.to_csv(f"{output_dir}/dim_producto.csv", index=False)
df_categoria.to_csv(f"{output_dir}/dim_categoria.csv", index=False)
df_almacen.to_csv(f"{output_dir}/dim_almacen.csv", index=False)
df_proveedor.to_csv(f"{output_dir}/dim_proveedor.csv", index=False)
df_empleado.to_csv(f"{output_dir}/dim_empleado.csv", index=False)

print("✅ Archivos CSV generados exitosamente en la carpeta 'output_csv'!")
