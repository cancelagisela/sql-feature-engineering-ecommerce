# Ingeniería de Features con SQL Analítico para E-Commerce

Este proyecto transforma datos transaccionales crudos de pedidos de e-commerce en un conjunto de variables (*features*) por usuario orientadas a entrenar modelos de predicción de *Churn* (abandono de clientes).

## Estructura del repositorio

- `feature_engineering.sql`: Consulta SQL estructurada con CTEs (`WITH`) para limpiar transacciones válidas, calcular métricas RFM, aplicar funciones de ventana y estandarizar valores nulos.
- `README.md`: Documentación de la lógica analítica y del propósito de cada variable generada.

## Lógica y utilidad de las features para Churn

1. **`recency_days` (Recency):**
   - **Cálculo:** Días transcurridos desde la última compra válida (`status = 'completed'` y `amount > 0`) de cada usuario hasta la fecha de referencia del conjunto de datos (`MAX(order_date)`).
   - **Aporte a Churn:** Un aumento en los días sin compra es uno de los indicadores más directos de desinterés o pérdida de recurrencia del cliente.

2. **`frequency_orders` (Frequency):**
   - **Cálculo:** Cantidad de pedidos únicos realizados por el usuario (`COUNT(DISTINCT order_id)`).
   - **Aporte a Churn:** Permite distinguir entre compradores ocasionales y clientes habituales; una base histórica de compras recurrentes ayuda a contextualizar si una pausa reciente es atípica o habitual.

3. **`monetary_total` (Monetary):**
   - **Cálculo:** Gasto total acumulado en pedidos válidos (`SUM(amount)`).
   - **Aporte a Churn:** Ayuda a dimensionar el valor económico del cliente y a priorizar segmentos de alto impacto ante señales de abandono.

4. **`trend_vs_avg_delta` (Trend vs. promedio histórico):**
   - **Cálculo:** Diferencia entre el gasto del último mes activo del usuario y su promedio mensual histórico calculado con función de ventana (`AVG(monthly_amount) OVER (PARTITION BY user_id)`).
   - **Aporte a Churn:** Detecta si el cliente está comprando por debajo de su nivel habitual, lo que suele anticipar una reducción progresiva de actividad.

5. **`trend_vs_prev_month_delta` y `ROW_NUMBER` (Funciones de ventana adicionales):**
   - **Cálculo:** Compara el gasto del último mes activo frente al mes previo mediante `LAG(monthly_amount) OVER (PARTITION BY user_id ORDER BY order_month)` y selecciona el registro más reciente por usuario con `ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_month DESC)`.
   - **Aporte a Churn:** Captura cambios bruscos de un período a otro (por ejemplo, una caída fuerte respecto al mes anterior) para complementar la tendencia histórica.

## Manejo de nulos y consideraciones técnicas

- Se filtran únicamente pedidos completados con monto mayor a cero para evitar distorsiones por cancelaciones o valores inválidos.
- Se utiliza `COALESCE(..., 0)` en las métricas y deltas resultantes para evitar valores `NULL` en la salida final y facilitar su consumo en etapas posteriores de modelado.
- La consulta está organizada por bloques (`WITH`) con alias descriptivos y agrupación explícita por usuario y período para mantener la legibilidad y evitar errores de agregación o ventanas temporales.

## Ejecución de prueba

La consulta fue probada en Google Colab utilizando DuckDB sobre una tabla de ejemplo `orders` (`order_id`, `user_id`, `order_date`, `amount`, `status`), verificando el cálculo de las métricas por `user_id` y exportando el script `feature_engineering.sql`.
