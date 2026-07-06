-- 项目一：电商用户行为分析 - SQL查询
-- 数据库表：user_behavior（用户行为表）、goods_info（商品信息表）

-- ============================================
-- 1. 全年有效交易概况
-- ============================================
select  
    count(distinct user_id) as 总用户数,
    count(*) as 总订单数,
    sum(g.price) as 总销售额,
    round(avg(g.price),2) as 平均销售额
from user_behavior u
join goods_info g
on u.item_id = g.item_id;

-- ============================================
-- 2. 各品类销售额排行
-- ============================================
SELECT
    g.category,
    SUM(g.price) AS 总销售额,
    COUNT(*) AS 销售量,
    ROUND(AVG(g.price), 2) AS 该品类均价
FROM user_behavior u
JOIN goods_info g
ON u.item_id = g.item_id
WHERE u.behavior = 'buy'
GROUP BY g.category
ORDER BY 总销售额 DESC;

-- ============================================
-- 3. 月度销售趋势
-- ============================================
SELECT 
    DATE_FORMAT(FROM_UNIXTIME(u.timestamp), '%Y-%m') AS 月份,
    SUM(g.price) AS 月GMV,
    COUNT(*) AS 月订单量
FROM user_behavior u
JOIN goods_info g
ON u.item_id = g.item_id
group by 月份
order by 月份;

-- ============================================
-- 4. 用户行为漏斗
-- ============================================
SELECT 
    COUNT(DISTINCT CASE WHEN behavior = 'pv' THEN user_id END) AS 浏览人数,
    COUNT(DISTINCT CASE WHEN behavior = 'fav' THEN user_id END) AS 收藏人数,
    COUNT(DISTINCT CASE WHEN behavior = 'buy' THEN user_id END) AS 购买人数
FROM user_behavior;
