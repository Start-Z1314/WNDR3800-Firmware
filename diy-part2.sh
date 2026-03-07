#!/bin/bash
set -e

echo "开始 diy-part2.sh..."

# 强制修改默认主题为 Argon
if [ -f "feeds/luci/collections/luci/Makefile" ]; then
    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
fi

# WiFi 物理修改（强制开启）
sed -i 's/set wireless.radio${devidx}.disabled=1/set wireless.radio${devidx}.disabled=0/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh
sed -i 's/set wireless.default_radio${devidx}.ssid=OpenWrt/set wireless.default_radio${devidx}.ssid=5G/g' package/kernel/mac80211/files/lib/wifi/mac80211.sh

# 先运行 defconfig 生成默认配置（避免空配置）
make defconfig

# 使用 scripts/config 设置目标平台和各项配置
./scripts/config --enable CONFIG_TARGET_ath79
./scripts/config --enable CONFIG_TARGET_ath79_generic
./scripts/config --enable CONFIG_TARGET_ath79_generic_DEVICE_netgear_wndr3800
./scripts/config --set-str CONFIG_LINUX_KERNEL_VERSION "4.14"
./scripts/config --enable CONFIG_USE_UPX
./scripts/config --enable CONFIG_STRIP_KERNEL_EXPORTS
./scripts/config --enable CONFIG_USE_MKLIBS
./scripts/config --disable CONFIG_IPV6

# 开启插件
./scripts/config --enable CONFIG_PACKAGE_luci-app-ssr-plus
./scripts/config --enable CONFIG_PACKAGE_luci-app-turbo-acc
./scripts/config --enable CONFIG_PACKAGE_luci-app-turbo-acc_INCLUDE_SHORTCUT_FE
./scripts/config --enable CONFIG_PACKAGE_luci-app-cpufreq
./scripts/config --enable CONFIG_PACKAGE_luci-app-zram
./scripts/config --enable CONFIG_PACKAGE_luci-app-vsftpd
./scripts/config --enable CONFIG_PACKAGE_luci-app-gargoyle-qos
./scripts/config --enable CONFIG_PACKAGE_luci-theme-argon

# 开启驱动
./scripts/config --enable CONFIG_PACKAGE_kmod-switch-rtl8366s
./scripts/config --enable CONFIG_PACKAGE_kmod-of-mdio
./scripts/config --enable CONFIG_PACKAGE_kmod-usb-ohci
./scripts/config --enable CONFIG_PACKAGE_kmod-usb2
./scripts/config --enable CONFIG_PACKAGE_kmod-usb-storage
./scripts/config --enable CONFIG_PACKAGE_kmod-fs-ext4
./scripts/config --enable CONFIG_PACKAGE_kmod-fs-vfat
./scripts/config --enable CONFIG_PACKAGE_kmod-nls-utf8
./scripts/config --enable CONFIG_PACKAGE_block-mount

# 运行 olddefconfig 解析依赖（不会覆盖已设置选项）
make olddefconfig

# 再次强制锁定内核版本（确保）
sed -i 's/CONFIG_LINUX_KERNEL_VERSION=.*/CONFIG_LINUX_KERNEL_VERSION="4.14"/g' .config

# 精简语言包（只保留中文和英文）
sed -i 's/luci-i18n-.*-zh-cn/luci-i18n-base-zh-cn/g' .config

# 验证设备是否启用
if ! grep -q "CONFIG_TARGET_ath79_generic_DEVICE_netgear_wndr3800" .config; then
    echo "❌ 错误：设备 netgear_wndr3800 未在 .config 中启用"
    exit 1
fi

# 创建 UCI 默认配置脚本（用于第一次启动时应用设置）
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-init-settings <<'EOF'
#!/bin/sh
uci set system.@system[0].hostname='OpenWrt'
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
uci set turboacc.config.sfe_flow='1'
uci set turboacc.config.dns_cache='1'
uci commit turboacc
uci set zram.config.enabled='1'
uci set zram.config.zram_size='64'
uci commit zram
uci set cpufreq.default.governor='performance'
uci set cpufreq.default.min_freq='800000'
uci set cpufreq.default.max_freq='800000'
uci commit cpufreq
uci set ssrplus.@global[0].global_mode='1'
uci set ssrplus.@global[0].dns_hijack='1'
uci set ssrplus.@global[0].chinadns_ng_enable='1'
uci set ssrplus.@global[0].chinadns_ng_china_dns='114.114.114.114,223.5.5.5'
uci set ssrplus.@global[0].chinadns_ng_trust_dns='8.8.8.8'
uci set ssrplus.@global[0].udp_relay_server='1'
uci set ssrplus.@global[0].tcp_fast_open='1'
uci set ssrplus.@subscribe[0].enabled='1'
uci set ssrplus.@subscribe[0].subtype='0'
uci set ssrplus.@subscribe[0].cron_time='0 3 * * *'
uci set ssrplus.@subscribe[0].sub_url='https://example.com/your-subscribe-url'
uci commit ssrplus
uci set qos.gargoyle.enabled='1'
uci set qos.gargoyle.wan_iface='wan'
uci set qos.gargoyle.uplink_smart='1'
uci set qos.gargoyle.downlink_smart='1'
uci set qos.gargoyle.ack_priority='1'
uci set qos.gargoyle.default_class='4'
DOWNLOAD_TOTAL="102400"
UPLOAD_TOTAL="10240"
uci set qos.gargoyle.download_bandwidth="${DOWNLOAD_TOTAL}"
uci set qos.gargoyle.upload_bandwidth="${UPLOAD_TOTAL}"
uci set qos.class_1.percent_min='35'
uci set qos.class_1.percent_max='95'
uci set qos.class_2.percent_min='20'
uci set qos.class_2.percent_max='80'
uci set qos.class_3.percent_min='15'
uci set qos.class_3.percent_max='60'
uci set qos.class_4.percent_min='5'
uci set qos.class_4.percent_max='40'
uci add qos rule
uci set qos.@rule[-1].name='Game'
uci set qos.@rule[-1].priority='Highest'
uci set qos.@rule[-1].ports='7000-8000 27015-27030 3074 3478-3479 5060 5062 6000-6200 10000-20000 30000-40000'
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
uci set qos.@rule[-1].ports='80 443 1935 5223 8000-9000 10000-20000'
uci add qos rule
uci set qos.@rule[-1].name='Chat'
uci set qos.@rule[-1].priority='High'
uci set qos.@rule[-1].ports='53 80 443 5222 5223 5228 5229 5230 8000-8010 8080 8443'
uci add qos rule
uci set qos.@rule[-1].name='Download'
uci set qos.@rule[-1].priority='Normal'
uci set qos.@rule[-1].ports='6881-6889 1863 5190 5000-5010 8080 10000-20000'
uci commit qos
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-init-settings

echo "diy-part2.sh 执行完成 - 配置已生成"
