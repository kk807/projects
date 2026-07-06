# 项目一：电商用户行为分析 - 数据清洗与特征工程
# 功能：从MySQL读取数据，进行特征加工，导出给PowerBI使用

import pandas as pd
import pymysql

# ================== 1. 数据库连接 ==================
# 注意：请修改为您自己的数据库连接信息
conn = pymysql.connect(
    host='localhost',
    port=3306,
    user='root',
    password='your_password',  # 请修改为您的密码
    database='p1',      # 请修改为您的数据库名
    charset='utf8mb4'
)

# 读取购买行为数据
df = pd.read_sql("""
SELECT
    u.user_id,
    FROM_UNIXTIME(u.timestamp) AS order_date,
    g.price,
    g.category,
    g.brand,
    g.item_id
FROM user_behavior u
INNER JOIN goods_info g ON u.item_id = g.item_id
WHERE u.behavior = 'buy'
""", conn)
conn.close()

# ================== 2. 时间特征提取 ==================
df['order_date'] = pd.to_datetime(df['order_date'])  # 统一转时间类型
df['month'] = df['order_date'].dt.month
df['weekday'] = df['order_date'].dt.dayofweek  # 0=周一，6=周日

# ================== 3. 商品价格分箱 ==================
bins = [0, 100, 500, 2000, 100000]
labels = ['低端(<100)', '中低端(100-500)', '中高端(500-2000)', '高端(>2000)']
df['价格带'] = pd.cut(df['price'], bins=bins, labels=labels, right=False)

# ================== 4. 用户消费分层（RFM-M维度分层） ==================
user_total = df.groupby('user_id')['price'].sum().reset_index()
user_total.columns = ['user_id', '用户总消费额']
user_total['用户等级'] = pd.qcut(
    user_total['用户总消费额'],
    q=4,
    labels=['低价值', '中低价值', '中高价值', '高价值']
)

# 合并用户分层标签到原始订单表
df = pd.merge(df, user_total, on='user_id')

# ================== 5. 导出PowerBI专用清洗数据 ==================
df.to_csv('clean_sales_data.csv', index=False, encoding='utf-8-sig')
print("数据加工完成！已导出 clean_sales_data.csv，共 {} 行".format(len(df)))
