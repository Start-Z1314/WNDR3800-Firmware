#!/bin/bash

# 移除默认 IP、密码预设，由用户自行配置
# 调整 WiFi 配置

# 重新预设主机名
echo "uci set system.@system[0].hostname='OpenWrt'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit system" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 设置国家为 US
echo "uci set wireless.radio0.country='US'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.radio1.country='US'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 预设 WiFi 信道以获得最佳效率
# 2.4GHz 频段 (radio0) - 建议使用非重叠信道 1, 6, 11。这里预设为 6。
echo "uci set wireless.radio0.channel='4'" >> package/base-files/files/etc/uci-defaults/99-init-settings
# 5GHz 频段 (radio1) - 建议选择干扰较少的信道。这里预设为 149。
echo "uci set wireless.radio1.channel='149'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 设置 SSID 和密码
echo "uci set wireless.@wifi-iface[0].ssid='5G'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[0].key='zld74502'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[0].encryption='psk2'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].ssid='5G'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].key='zld74502'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.@wifi-iface[1].encryption='psk2'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 调整信号强度到最优 (WNDR3800 2.4G 和 5G 频段最大功率)
# 对于 ath9k (WNDR3800 的 2.4G 和 5G 芯片)，最大功率通常是 20dBm (100mW) 或 23dBm (200mW)，具体取决于地区法规和驱动支持。
# 这里设置为 23dBm，如果编译后实际功率达不到，系统会自动降级到支持的最大值。
echo "uci set wireless.radio0.txpower='20'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set wireless.radio1.txpower='20'" >> package/base-files/files/etc/uci-defaults/99-init-settings
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

# 预设 CPUFreq 到 800MHz
echo "uci set cpufreq.default.governor='performance'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set cpufreq.default.min_freq='800000'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set cpufreq.default.max_freq='800000'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci commit cpufreq" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 8. 石像鬼 QoS (Gargoyle QoS) 预设
# 根据用户需求，预设石像鬼 QoS 的基本参数。
# 注意：石像鬼 QoS 的高级规则和优先级设置高度依赖于用户环境和具体应用，
# 编译时只能进行通用预设，用户仍可能需要在路由器启动后通过 LuCI 界面进行微调。

# 启用 QoS 并选择 WAN 口
echo "uci set qos.gargoyle.enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.gargoyle.wan_iface='wan'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 设置上传和下载带宽 (用户提供：下载 100 Mbps，上传 10 Mbps)
# 注意：石像鬼 QoS 通常使用 Kbit/s 作为单位，所以需要转换。
# 100 Mbps = 100 * 1024 Kbit/s = 102400 Kbit/s
# 10 Mbps = 10 * 1024 Kbit/s = 10240 Kbit/s
echo "uci set qos.gargoyle.upload_bandwidth='10240'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.gargoyle.download_bandwidth='102400'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 启用 QoS
echo "uci set qos.gargoyle.qos_enabled='1'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 预设优先级规则 (根据用户需求：下载、游戏、视频、聊天、网页)
# 石像鬼 QoS 默认有几个优先级类别：Highest, High, Normal, Low, Lowest
# 这里尝试将常见服务映射到这些类别。
# 由于 UCI 命令直接创建复杂规则比较繁琐，这里只设置一些基础的全局优先级。
# 用户仍需在 LuCI 界面根据实际应用添加具体的规则。

# 默认优先级设置 (示例，可能需要用户在界面微调)
# 游戏 (通常需要低延迟，高优先级)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Game'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='Highest'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].proto='tcp udp'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='7000-8000 27015-27030 3074 3478-3479 5060 5062 6000-6200'" >> package/base-files/files/etc/uci-defaults/99-init-settings # 常见游戏端口

# 视频 (需要稳定带宽，高优先级)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Video'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='High'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].proto='tcp'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='80 443 1935 5223'" >> package/base-files/files/etc/uci-defaults/99-init-settings # HTTP/HTTPS, RTMP, HLS等

# 聊天 (实时性要求高，高优先级)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Chat'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='High'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].proto='tcp udp'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='53 80 443 5222 5223 5228 5229 5230 8000-8010'" >> package/base-files/files/etc/uci-defaults/99-init-settings # DNS, HTTP/HTTPS, XMPP, 微信等

# 下载 (带宽占用大，中等优先级)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Download'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='Normal'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].proto='tcp'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='6881-6889 1863 5190 5000-5010 8080'" >> package/base-files/files/etc/uci-defaults/99-init-settings # BT, P2P, HTTP下载等

# 网页浏览 (一般优先级)
echo "uci add qos rule" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].name='Web Browsing'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].priority='Normal'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].proto='tcp'" >> package/base-files/files/etc/uci-defaults/99-init-settings
echo "uci set qos.@rule[-1].ports='80 443'" >> package/base-files/files/etc/uci-defaults/99-init-settings

# 提交 QoS 配置
echo "uci commit qos" >> package/base-files/files/etc/uci-defaults/99-init-settings


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