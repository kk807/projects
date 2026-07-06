-- 项目二：用户流失分析 - SQL查询
-- 数据库表：data（用户行为数据表）

-- ============================================
-- 1. 渠道漏斗统计表
-- ============================================
CREATE TABLE channel_funnel_stats AS
SELECT
    `流量来源`,
    home_uv,
    list_uv,
    detail_uv,
    payment_uv,
    checkout_uv,
    ROUND(list_uv * 1.0 / NULLIF(home_uv,0) * 100, 2) AS home_to_list_pct,
    ROUND(detail_uv * 1.0 / NULLIF(list_uv,0) * 100, 2) AS list_to_detail_pct,
    ROUND(payment_uv * 1.0 / NULLIF(detail_uv,0) * 100, 2) AS detail_to_payment_pct,
    ROUND(checkout_uv * 1.0 / NULLIF(payment_uv,0) * 100, 2) AS payment_to_checkout_pct
FROM (
    SELECT 
        `流量来源`,
        COUNT(DISTINCT CASE WHEN `是否访问首页` = 1 THEN 用户ID END) AS home_uv,
        COUNT(DISTINCT CASE WHEN `是否访问列表页` = 1 THEN 用户ID END) AS list_uv,
        COUNT(DISTINCT CASE WHEN `是否访问商品详情页` = 1 THEN 用户ID END) AS detail_uv,
        COUNT(DISTINCT CASE WHEN `是否访问支付页面` = 1 THEN 用户ID END) AS payment_uv,
        COUNT(DISTINCT CASE WHEN `是否访问确认订单页` = 1 THEN 用户ID END) AS checkout_uv
    FROM `data`
    WHERE 流量来源 IS NOT NULL AND 流量来源 != ''
    GROUP BY `流量来源`
) t
ORDER BY payment_to_checkout_pct;

-- ============================================
-- 2. 月度趋势监控表
-- ============================================
CREATE TABLE monthly_trend_stats AS
SELECT
    DATE_FORMAT(`访问时间`, '%Y-%m') AS `month`,
    COUNT(DISTINCT CASE WHEN `是否访问支付页面` = 1 THEN `用户ID` END) AS payment_uv,
    COUNT(DISTINCT CASE WHEN `是否访问确认订单页` = 1 THEN `用户ID` END) AS checkout_uv,
    ROUND(
        COUNT(DISTINCT CASE WHEN `是否访问确认订单页` = 1 THEN `用户ID` END) * 1.0
        / NULLIF(COUNT(DISTINCT CASE WHEN `是否访问支付页面` = 1 THEN `用户ID` END), 0)
        * 100,
        2
    ) AS payment_to_checkout_pct
FROM `data`
GROUP BY DATE_FORMAT(`访问时间`, '%Y-%m')
ORDER BY `month`;

-- ============================================
-- 3. 用户级流失标签表
-- ============================================
CREATE TABLE user_lost_tags AS
SELECT 
    用户ID,
    MAX(`用户所在省份`) AS 省份,
    MAX(`设备类型`) AS 设备,
    MAX(`操作系统`) AS 系统,
    MAX(`流量来源`) AS 渠道,
    -- 用户是否存在支付页流失行为：1=流失用户，0=无流失
    MAX(CASE WHEN `是否访问支付页面` = 1 AND `是否访问确认订单页` = 0 THEN 1 ELSE 0 END) AS is_payment_lost,
    -- 该用户累计流失次数
    SUM(CASE WHEN `是否访问支付页面` = 1 AND `是否访问确认订单页` = 0 THEN 1 ELSE 0 END) AS lost_times
FROM `data`
GROUP BY 用户ID;

-- ============================================
-- 4. 设备 + 操作系统交叉流失分析
-- ============================================
DROP TABLE IF EXISTS device_os_loss_stats;
CREATE TABLE device_os_loss_stats AS
SELECT 
    `设备类型`,
    `操作系统`,
    COUNT(DISTINCT 用户ID) AS total_users,
    COUNT(DISTINCT CASE WHEN `是否访问支付页面` = 1 AND `是否访问确认订单页` = 0 THEN 用户ID END) AS lost_users,
    ROUND(COUNT(DISTINCT CASE WHEN `是否访问支付页面` = 1 AND `是否访问确认订单页` = 0 THEN 用户ID END) * 1.0 / 
          NULLIF(COUNT(DISTINCT 用户ID), 0) * 100, 2) AS lost_rate_pct
FROM `data`
WHERE `设备类型` IS NOT NULL AND `操作系统` IS NOT NULL
GROUP BY `设备类型`, `操作系统`
ORDER BY lost_rate_pct DESC;
