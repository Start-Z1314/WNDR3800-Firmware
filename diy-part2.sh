#!/bin/bash

#!/bin/bash

# 移除默认 IP、主机名、密码预设，由用户自行配置
# 调整 WiFi 配置
# 设置国家为 US
echo "uci set wireless.radio0.country='US'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.radio1.country='US'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 设置 SSID 和密码
sed -i "s/ssid='WNDR3800_2.4G'/ssid='5G'/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh
echo "uci set wireless.@wifi-iface[0].ssid='5G'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[0].key='zld74502'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[0].encryption='psk2'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].ssid='5G'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].key='zld74502'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].encryption='psk2'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 调整信号强度到最优 (WNDR3800 2.4G 和 5G 频段最大功率)
# 对于 ath9k (WNDR3800 的 2.4G 和 5G 芯片)，最大功率通常是 20dBm (100mW) 或 23dBm (200mW)，具体取决于地区法规和驱动支持。
# 这里设置为 23dBm，如果编译后实际功率达不到，系统会自动降级到支持的最大值。
echo "uci set wireless.radio0.txpower='23'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.radio1.txpower='23'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit wireless" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 5. 极致精简：移除不必要的语言包 (只保留中文和英文)
sed -i 's/luci-i18n-.*-zh-cn/luci-i18n-base-zh-cn/g' .config

# 6. 预设 Turbo ACC 优化参数 (SFE 流转发引擎)
echo "uci set turboacc.config.sfe_flow='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set turboacc.config.dns_cache='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit turboacc" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 7. 预设 zRAM 优化 (开启 64M 交换内存)
echo "uci set zram.config.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set zram.config.zram_size='64'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit zram" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 8. 预设 eQoS 默认开启并优化参数
echo "uci set eqos.config.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 根据用户提供的带宽信息进行优化设置
# 上行 1.25Mbps = 1280 Kbps (留出一点余量，设置为 1200 Kbps)
echo "uci set eqos.config.upload_bandwidth='1200'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 下行 12.5Mbps = 12800 Kbps (留出一点余量，设置为 12000 Kbps)
echo "uci set eqos.config.download_bandwidth='12000'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 默认开启智能队列管理 (Smart Queue Management)
echo "uci set eqos.config.sqm_enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 默认使用 cake 队列规则，并设置为 piece_of_cake 脚本
echo "uci set eqos.config.sqm_qdisc='cake'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set eqos.config.sqm_script='piece_of_cake'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit eqos" >> package/base-files/files/etc/uci-defaults/99-init-settings


# 9. 预设 SSR Plus+ 默认开启并精简
echo "uci set ssrplus.global.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 默认开启 DNS 劫持，防止 DNS 污染
echo "uci set ssrplus.global.dns_hijack='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 默认使用 ChinaDNS-NG + DNS2Socks 模式
echo "uci set ssrplus.global.pdnsd_enable='0'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set ssrplus.global.chinadns_ng_enable='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set ssrplus.global.dns2socks_enable='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit ssrplus" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 10. 移除默认主题，强制使用 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile