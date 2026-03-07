#!/bin/bash
# ===============================================
# diy-part2.sh - 固件深度配置预设
# 目标: 刷机后只需填入订阅地址，其他全部自动最优
# ===============================================

# ------------------------------
# 0. 编译时强制修改主题 (确保 Argon 为默认)
# ------------------------------
if [ -f "feeds/luci/collections/luci/Makefile" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
    echo "✓ 默认主题已修改为 Argon"
fi

# ------------------------------
# 1. WiFi 物理修改 (最底层强制开启)
# ------------------------------
sed -i 's/set wireless.radio${devidx}.disabled=1/set wireless.radio${devidx}.disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i 's/set wireless.default_radio${devidx}.ssid=OpenWrt/set wireless.default_radio${devidx}.ssid=5G/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# ------------------------------
# 2. 创建 UCI 默认配置脚本 (所有预设写在这里)
# ------------------------------
# 先删除可能存在的旧文件
rm -f package/base-files/files/etc/uci-defaults/99-init-settings

cat << "EOF" > package/base-files/files/etc/uci-defaults/99-init-settings
#!/bin/sh

# ===============================================
# 系统基础设置
# ===============================================
uci set system.@system[0].hostname='OpenWrt'
uci commit system

# ===============================================
# WiFi 详细配置 (SSID: 5G, 密码: zld74502)
# ===============================================
uci set wireless.radio0.country='US'
uci set wireless.radio1.country='US'
uci set wireless.radio0.channel='4'
uci set wireless.radio1.channel='149'
uci set wireless.radio0.txpower='20'
uci set wireless.radio1.txpower='20'

uci set wireless.@wifi-iface[0].ssid='5G'
uci set wireless.@wifi-iface[0].key='zld74502'
uci set wireless.@wifi-iface[0].encryption='psk2'
uci set wireless.@wifi-iface[1].ssid='5G'
uci set wireless.@wifi-iface[1].key='zld74502'
uci set wireless.@wifi-iface[1].encryption='psk2'
uci commit wireless
wifi up

# ===============================================
# Turbo ACC 网络加速
# ===============================================
uci set turboacc.config.sfe_flow='1'
uci set turboacc.config.dns_cache='1'
uci commit turboacc

# ===============================================
# zRAM 交换内存
# ===============================================
uci set zram.config.enabled='1'
uci set zram.config.zram_size='64'
uci commit zram

# ===============================================
# CPU 频率管理 (锁定 800MHz 性能模式)
# ===============================================
uci set cpufreq.default.governor='performance'
uci set cpufreq.default.min_freq='800000'
uci set cpufreq.default.max_freq='800000'
uci commit cpufreq

# ===============================================
# SSR Plus+ 最佳预设 (占位符订阅)
# ===============================================
uci set ssrplus.@global[0].global_mode='1'
uci set ssrplus.@global[0].dns_hijack='1'
uci set ssrplus.@global[0].chinadns_ng_enable='1'
uci set ssrplus.@global[0].chinadns_ng_china_dns='114.114.114.114,223.5.5.5'
uci set ssrplus.@global[0].chinadns_ng_trust_dns='8.8.8.8'
uci set ssrplus.@global[0].udp_relay_server='1'
uci set ssrplus.@global[0].tcp_fast_open='1'

# 订阅设置 (占位符)
uci set ssrplus.@subscribe[0].enabled='1'
uci set ssrplus.@subscribe[0].subtype='0'
uci set ssrplus.@subscribe[0].cron_time='0 3 * * *'
uci set ssrplus.@subscribe[0].sub_url='https://example.com/your-subscribe-url'

uci commit ssrplus

# ===============================================
# 石像鬼 QoS 深度优化
# ===============================================
uci set qos.gargoyle.enabled='1'
uci set qos.gargoyle.wan_iface='wan'
uci set qos.gargoyle.uplink_smart='1'
uci set qos.gargoyle.ack_priority='1'

# 带宽设置 (默认 100M/10M，请根据实际修改)
DOWNLOAD_TOTAL="102400"
UPLOAD_TOTAL="10240"
uci set qos.gargoyle.download_bandwidth="${DOWNLOAD_TOTAL}"
uci set qos.gargoyle.upload_bandwidth="${UPLOAD_TOTAL}"

# 带宽分配百分比
uci set qos.class_1.percent_min='30'
uci set qos.class_1.percent_max='95'
uci set qos.class_2.percent_min='20'
uci set qos.class_2.percent_max='80'
uci set qos.class_3.percent_min='15'
uci set qos.class_3.percent_max='60'
uci set qos.class_4.percent_min='5'
uci set qos.class_4.percent_max='40'

# 分类规则
uci add qos rule
uci set qos.@rule[-1].name='Game'
uci set qos.@rule[-1].priority='Highest'
uci set qos.@rule[-1].ports='7000-8000 27015-27030 3074 3478-3479 5060 5062 6000-6200 10000-20000'

uci add qos rule
uci set qos.@rule[-1].name='Web_HTTP'
uci set qos.@rule[-1].priority='High'
uci set qos.@rule[-1].ports='80 443 8080 8443'

uci add qos rule
uci set qos.@rule[-1].name='Web_Large'
uci set qos.@rule[-1].priority='Normal'
uci set qos.@rule[-1].ports='80 443 8080 8443'
uci set qos.@rule[-1].threshold='5120'
uci set qos.@rule[-1].threshold_unit='kb'

uci add qos rule
uci set qos.@rule[-1].name='Video'
uci set qos.@rule[-1].priority='High'
uci set qos.@rule[-1].ports='80 443 1935 5223'

uci add qos rule
uci set qos.@rule[-1].name='Chat'
uci set qos.@rule[-1].priority='High'
uci set qos.@rule[-1].ports='53 80 443 5222 5223 5228 5229 5230 8000-8010'

uci add qos rule
uci set qos.@rule[-1].name='Download'
uci set qos.@rule[-1].priority='Normal'
uci set qos.@rule[-1].ports='6881-6889 1863 5190 5000-5010 8080'

uci commit qos

# ===============================================
# 其他优化
# ===============================================
# 极致精简: 移除不必要的语言包 (编译时已处理，此处留空)
# 所有配置完成
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-init-settings
echo "✓ 已创建 /etc/uci-defaults/99-init-settings"

# ------------------------------
# 3. 极致精简: 在 .config 中只保留中文和英文 (如果 .config 存在)
# ------------------------------
if [ -f ".config" ]; then
    sed -i 's/luci-i18n-.*-zh-cn/luci-i18n-base-zh-cn/g' .config
    echo "✓ 已精简语言包配置"
fi

# ===============================================
# 完成
# ===============================================
echo "diy-part2.sh 执行完成 - 所有预设已就绪"