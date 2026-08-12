USE ventas_tech_db;
GO

-- ============================================================================
-- PRE-ENTREGA: CONSULTAS CON JOINs PARA EL PROYECTO (Módulo 5)
-- Archivo: m5_consultas_joins.sql
-- Empresa: RetailPro
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PASO PREVIO: Adecuación del esquema para incorporar Canal, Segmento y Región
-- ----------------------------------------------------------------------------

-- Agregamos segmento y región a la tabla de clientes si no existen
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('clientes') AND name = 'segmento')
BEGIN
    ALTER TABLE clientes ADD segmento VARCHAR(50) DEFAULT 'Consumidor Final', region VARCHAR(50) DEFAULT 'Centro';
END;
GO

-- Agregamos la columna canal a la tabla de ventas si no existe
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ventas') AND name = 'canal')
BEGIN
    ALTER TABLE ventas ADD canal VARCHAR(20) DEFAULT 'Online';
END;
GO

-- Actualizamos datos de ejemplo para tener diversidad en canales, regiones y segmentos
UPDATE clientes SET segmento = 'Corporativo', region = 'Centro' WHERE id_cliente = 10;
UPDATE clientes SET segmento = 'Pyme', region = 'Centro' WHERE id_cliente = 20;
UPDATE clientes SET segmento = 'Consumidor Final', region = 'CABA/GBA' WHERE id_cliente = 30;
UPDATE clientes SET segmento = 'Pyme', region = 'Cuyo' WHERE id_cliente = 40;

-- Insertamos un cliente adicional sin ventas para testear la Consulta 2
IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = 50)
BEGIN
    INSERT INTO clientes (id_cliente, nombre, email, ciudad, fecha_registro, segmento, region)
    VALUES (50, 'Esteban Quito', 'esteban@mail.com', 'Salta', '2024-03-01', 'Consumidor Final', 'NOA');
END;

-- Insertamos un producto adicional sin ventas para testear la Consulta 3
IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = 7)
BEGIN
    INSERT INTO productos (id_producto, nombre_producto, id_categoria, precio, stock, activo)
    VALUES (7, 'Webcam HD 1080p', 102, 45.00, 15, 1);
END;

-- Asignamos canales variados a las ventas
UPDATE ventas SET canal = 'Online' WHERE id_venta % 2 = 0;
UPDATE ventas SET canal = 'Presencial' WHERE id_venta % 2 <> 0;
GO


-- ============================================================================
-- CONSULTAS DE NEGOCIO (JOINs)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONSULTA 1: Vista base del proyecto (INNER JOIN)
-- Combina ventas, clientes, productos y categorías para alimentar Power BI.
-- ----------------------------------------------------------------------------
SELECT 
    v.fecha_venta AS Fecha,
    c.nombre AS Nombre_Cliente,
    c.segmento AS Segmento,
    c.region AS Region,
    p.nombre_producto AS Nombre_Producto,
    cat.nombre_categoria AS Categoria,
    v.cantidad AS Cantidad,
    v.precio_unitario AS Precio_Unitario,
    (v.cantidad * v.precio_unitario) AS Total_Venta,
    v.canal AS Canal
FROM ventas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta DESC;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 2: Clientes sin ventas (LEFT JOIN)
-- Identifica clientes registrados en el CRM que aún no han realizado ninguna compra.
-- ----------------------------------------------------------------------------
SELECT 
    c.nombre AS Nombre_Cliente,
    c.email AS Email,
    c.fecha_registro AS Fecha_Registro
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 3: Productos sin ventas (LEFT JOIN)
-- Identifica productos del catálogo que no registran transacciones.
-- ----------------------------------------------------------------------------
SELECT 
    p.nombre_producto AS Nombre_Producto,
    cat.nombre_categoria AS Categoria,
    p.precio AS Precio
FROM productos p
INNER JOIN categorias cat ON p.id_categoria = cat.id_categoria
LEFT JOIN ventas v ON p.id_producto = v.id_producto
WHERE v.id_venta IS NULL;
GO


-- ----------------------------------------------------------------------------
-- CONSULTA 4: Consolidado y total por canal (UNION ALL + GROUP BY)
-- Combina flujos de ventas Online y Presencial y calcula el acumulado por canal.
-- ----------------------------------------------------------------------------
WITH VentasConsolidadas AS (
    -- Subconsulta de ventas canal Online
    SELECT 
        id_venta,
        fecha_venta,
        id_cliente,
        id_producto,
        (cantidad * precio_unitario) AS monto_total,
        canal
    FROM ventas
    WHERE canal = 'Online'

    UNION ALL

    -- Subconsulta de ventas canal Presencial
    SELECT 
        id_venta,
        fecha_venta,
        id_cliente,
        id_producto,
        (cantidad * precio_unitario) AS monto_total,
        canal
    FROM ventas
    WHERE canal = 'Presencial'
)
SELECT 
    canal AS Canal_Venta,
    COUNT(id_venta) AS Cantidad_Transacciones,
    SUM(monto_total) AS Total_Facturado
FROM VentasConsolidadas
GROUP BY canal
ORDER BY Total_Facturado DESC;
GO
