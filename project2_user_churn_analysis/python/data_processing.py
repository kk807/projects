# 项目二：用户流失分析 - 数据处理与策略标签
# 功能：从MySQL读取统计数据，添加策略标签，导出给PowerBI使用

import pandas as pd
import pymysql  # 如果没安装，在终端运行 pip install pymysql

# ================== 1. 连接 MySQL 读取数据 ==================
# 注意：请修改为您自己的数据库连接信息
conn = pymysql.connect(
    host='localhost',
    user='root',
    password='your_password',  # 改成你自己的 MySQL 密码
    database='p1',      # 改成你的数据库名
    charset='utf8'
)

# 读取 4 张表
df_channel = pd.read_sql("SELECT * FROM channel_funnel_stats", conn)
df_monthly = pd.read_sql("SELECT * FROM monthly_trend_stats", conn)
df_device = pd.read_sql("SELECT * FROM device_os_loss_stats", conn)
df_users = pd.read_sql("SELECT * FROM user_lost_tags", conn)
conn.close()

print("✅ 数据读取成功！")

# ================== 2. 给"渠道"打策略标签 ==================
# 根据支付转化率，给每个渠道一个"行动建议"
def channel_strategy(row):
    pct = row['payment_to_checkout_pct']
    if pct < 27.7:
        return '🚨 紧急优化：检查支付流程是否对搜索/广告用户不友好'
    elif pct < 40:
        return '⚠️ 需改进：考虑增加新人优惠券或简化登录'
    else:
        return '✅ 保持：继续维持当前策略'

df_channel['策略建议'] = df_channel.apply(channel_strategy, axis=1)

# 额外加一列：流失率（方便看）
df_channel['支付流失率_%'] = 100 - df_channel['payment_to_checkout_pct']

# ================== 3. 给"月度趋势"打标签 ==================
avg_pct = df_monthly['payment_to_checkout_pct'].mean()

def month_strategy(row):
    if row['payment_to_checkout_pct'] > avg_pct * 1.05:
        return '📈 优秀月份：分析该月做了什么活动，复制经验'
    elif row['payment_to_checkout_pct'] < avg_pct * 0.95:
        return '📉 异常月份：排查该月是否有技术故障或活动缺失'
    else:
        return '➖ 正常'

df_monthly['表现评价'] = df_monthly.apply(month_strategy, axis=1)

# ================== 4. 给"设备流失"打标签 ==================
# 计算整体平均流失率
avg_loss = df_device['lost_rate_pct'].mean()

def device_strategy(row):
    if row['lost_rate_pct'] > avg_loss * 1.1:
        return '🔧 重点关注该设备组合的支付适配性'
    elif row['lost_rate_pct'] > avg_loss:
        return '👀 持续监控'
    else:
        return '✅ 表现良好'

df_device['优化建议'] = df_device.apply(device_strategy, axis=1)

# ================== 5. 导出为 CSV（给 Power BI 用） ==================
df_channel.to_csv('渠道漏斗_含策略.csv', index=False, encoding='utf-8-sig')
df_monthly.to_csv('月度趋势_含评价.csv', index=False, encoding='utf-8-sig')
df_device.to_csv('设备流失_含建议.csv', index=False, encoding='utf-8-sig')
# 用户标签表直接导出，不需要额外处理
df_users.to_csv('用户流失标签.csv', index=False, encoding='utf-8-sig')

print("\n✅ 已生成 4 个带策略标签的 CSV 文件，供 Power BI 使用！")
print("\n📊 渠道策略建议预览：")
print(df_channel[['流量来源', 'payment_to_checkout_pct', '支付流失率_%', '策略建议']])
