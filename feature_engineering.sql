WITH valid_orders AS (
    SELECT
        order_id,
        user_id,
        CAST(order_date AS DATE) AS order_date,
        amount
    FROM orders
    WHERE status = 'completed'
      AND amount > 0
),
ref_date AS (
    SELECT MAX(order_date) AS max_date
    FROM valid_orders
),
rfm_metrics AS (
    SELECT
        v.user_id,
        DATE_DIFF('day', MAX(v.order_date), r.max_date) AS recency_days,
        COUNT(DISTINCT v.order_id) AS frequency_orders,
        COALESCE(SUM(v.amount), 0) AS monetary_total
    FROM valid_orders v
    CROSS JOIN ref_date r
    GROUP BY v.user_id, r.max_date
),
monthly_spend AS (
    SELECT
        user_id,
        DATE_TRUNC('month', order_date) AS order_month,
        SUM(amount) AS monthly_amount
    FROM valid_orders
    GROUP BY user_id, DATE_TRUNC('month', order_date)
),
window_features AS (
    SELECT
        user_id,
        order_month,
        monthly_amount,
        AVG(monthly_amount) OVER (PARTITION BY user_id) AS avg_historical_monthly_spend,
        LAG(monthly_amount) OVER (PARTITION BY user_id ORDER BY order_month) AS prev_month_spend,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_month DESC) AS rn_recent_month
    FROM monthly_spend
),
latest_trend AS (
    SELECT
        user_id,
        COALESCE(monthly_amount - avg_historical_monthly_spend, 0) AS trend_vs_avg_delta,
        COALESCE(monthly_amount - prev_month_spend, 0) AS trend_vs_prev_month_delta
    FROM window_features
    WHERE rn_recent_month = 1
)
SELECT
    rfm.user_id,
    rfm.recency_days,
    rfm.frequency_orders,
    rfm.monetary_total,
    COALESCE(lt.trend_vs_avg_delta, 0) AS trend_vs_avg_delta,
    COALESCE(lt.trend_vs_prev_month_delta, 0) AS trend_vs_prev_month_delta
FROM rfm_metrics rfm
LEFT JOIN latest_trend lt
    ON rfm.user_id = lt.user_id
ORDER BY rfm.user_id;
