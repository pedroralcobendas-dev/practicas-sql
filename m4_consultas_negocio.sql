USE ventas_tech_db;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 1: Resumen ejecutivo mensual
-- Total facturado, cantidad de pedidos y ticket promedio por mes.
-- ----------------------------------------------------------------------------
SELECT 
    MONTH(fecha_venta) AS Mes,
    SUM(cantidad * precio_unitario) AS Total_Facturado,
    COUNT(*) AS Cantidad_Pedidos,
    AVG(cantidad * precio_unitario) AS Ticket_Promedio
FROM ventas
GROUP BY MONTH(fecha_venta)
ORDER BY Mes;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 2: Ranking de productos (Top 5)
-- Top 5 id_producto por total facturado y unidades vendidas.
-- ----------------------------------------------------------------------------
SELECT TOP 5
    id_producto,
    SUM(cantidad) AS Unidades_Vendidas,
    SUM(cantidad * precio_unitario) AS Total_Facturado
FROM ventas
GROUP BY id_producto
ORDER BY Total_Facturado DESC;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 3: Clientes recurrentes
-- Clientes con más de un pedido, mostrando cantidad de pedidos y total gastado.
-- ----------------------------------------------------------------------------
SELECT 
    id_cliente,
    COUNT(*) AS Cantidad_Pedidos,
    SUM(cantidad * precio_unitario) AS Total_Gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY Cantidad_Pedidos DESC, Total_Gastado DESC;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 4: Meses por encima / por debajo del promedio general
-- Compara la facturación mensual contra el promedio de facturación de los meses.
-- ----------------------------------------------------------------------------
WITH FacturacionMensual AS (
    SELECT 
        MONTH(fecha_venta) AS Mes,
        SUM(cantidad * precio_unitario) AS Total_Facturado
    FROM ventas
    GROUP BY MONTH(fecha_venta)
)
SELECT 
    Mes,
    Total_Facturado,
    CASE 
        WHEN Total_Facturado >= (SELECT AVG(Total_Facturado) FROM FacturacionMensual) 
        THEN 'Por encima'
        ELSE 'Por debajo'
    END AS Rendimiento_Mensual
FROM FacturacionMensual
ORDER BY Mes;
GO


/*
===============================================================================
BLOQUE DE CIERRE: HALLAZGOS DE NEGOCIO
===============================================================================

1. Concentración en Clientes Recurrentes:
   Los clientes recurrentes (id_cliente 10, 20 y 30) representan más del 70% 
   de las transacciones registradas en el período, lo que demuestra una alta 
   fidelización en la base de clientes inicial.

2. Producto Líder en Ventas (Top 1):
   El producto con id_producto 6 (Auriculares con Micrófono) y el id_producto 1 
   (Mouse USB Estándar) registran la mayor frecuencia de compra en el volumen 
   total de unidades, posicionando a los periféricos básicos como el motor de volumen.

3. Estabilidad de Facturación Mensual:
   Al analizar las ventas registradas durante el mes de Marzo de 2024, se observa 
   un flujo de caja constante distribuido a lo largo de las semanas, manteniendo 
   un ticket promedio sostenido superior a los $20 por transacción.
===============================================================================
*/
