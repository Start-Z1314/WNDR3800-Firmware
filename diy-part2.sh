#!/bin/bash

# 1. 物理修改 WiFi 默认设置 (比 uci-defaults 更强力)
# 修改 mac80211.sh 脚本，使 WiFi 默认开启，并设置默认 SSID 和信道
# 这是解决 "WiFi 默认关闭" 问题的最底层方案
sed -i 's/set wireless.radio${devidx}.disabled=1/set wireless.radio${devidx}.disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i 's/set wireless.default_radio${devidx}.ssid=OpenWrt/set wireless.default_radio${devidx}.ssid=5G/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 2. 重新预设主机名
echo "uci set system.@system[0].hostname='OpenWrt'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit system" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 3. 预设 WiFi 详细参数 (SSID, 密码, 功率, 信道)
# 设置国家为 US 以获得更好的功率支持
echo "uci set wireless.radio0.country='US'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.radio1.country='US'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 2.4GHz 频段 (radio0) - 预设为信道 4
echo "uci set wireless.radio0.channel='4'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 5GHz 频段 (radio1) - 预设为信道 149
echo "uci set wireless.radio1.channel='149'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 设置 SSID 和密码 (zld74502)
echo "uci set wireless.@wifi-iface[0].ssid='5G'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[0].key='zld74502'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[0].encryption='psk2'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].ssid='5G'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].key='zld74502'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].encryption='psk2'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 调整信号强度到 20dBm (100mW)
echo "uci set wireless.radio0.txpower='20'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.radio1.txpower='20'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit wireless" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "wifi up" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 4. 极致精简：移除不必要的语言包 (只保留中文和英文)
sed -i 's/luci-i18n-.*-zh-cn/luci-i18n-base-zh-cn/g' .config

# 5. 预设 Turbo ACC 优化参数 (SFE 流转发引擎)
echo "uci set turboacc.config.sfe_flow='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set turboacc.config.dns_cache='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit turboacc" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 6. 预设 zRAM 优化 (开启 64M 交换内存)
echo "uci set zram.config.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set zram.config.zram_size='64'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit zram" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 7. 预设 CPUFreq 到 800MHz (锁定性能模式)
echo "uci set cpufreq.default.governor='performance'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set cpufreq.default.min_freq='800000'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set cpufreq.default.max_freq='800000'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit cpufreq" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 8. 石像鬼 QoS (Gargoyle QoS) 预设
# 设置上传和下载带宽 (下载 100 Mbps, 上传 10 Mbps)
echo "uci set qos.gargoyle.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.gargoyle.wan_iface='wan'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.gargoyle.upload_bandwidth='10240'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.gargoyle.download_bandwidth='102400'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.gargoyle.qos_enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 预设优先级规则 (游戏, 视频, 聊天, 下载, 网页)
# 游戏 (Highest)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Game'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='Highest'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='7000-8000 27015-27030 3074 3478-3479 5060 5062 6000-6200'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 视频 (High)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Video'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='High'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='80 443 1935 5223'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 聊天 (High)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Chat'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='High'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='53 80 443 5222 5223 5228 5229 5230 8000-8010'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 下载 (Normal)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Download'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='Normal'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='6881-6889 1863 5190 5000-5010 8080'" >> package/base-files/files/etc/uci-defaults/99-init-settings

echo "uci commit qos" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 9. 预设 SSR Plus+ 默认开启
echo "uci set ssrplus.global.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set ssrplus.global.dns_hijack='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set ssrplus.global.chinadns_ng_enable='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit ssrplus" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 10. 强制使用 Argon 主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile