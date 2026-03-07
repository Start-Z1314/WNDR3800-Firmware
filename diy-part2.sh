	#!/bin/bash
	set -e
	echo "开始执行 diy-part2.sh..."
	# 1. 强制修改默认主题
	if [ -f "feeds/luci/collections/luci/Makefile" ]; then
	    sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
	    echo "✓ 默认主题已修改为 Argon"
	else
	    echo "⚠️ 未找到 Luci Makefile，跳过主题修改"
	fi
	# 2. WiFi 物理修改（增加文件存在性检查，防止报错）
	WIFI_SCRIPT="package/kernel/mac80211/files/lib/wifi/mac80211.sh"
	if [ -f "$WIFI_SCRIPT" ]; then
	    sed -i 's/set wireless.radio${devidx}.disabled=1/set wireless.radio${devidx}.disabled=0/g' "$WIFI_SCRIPT"
	    sed -i 's/set wireless.default_radio${devidx}.ssid=OpenWrt/set wireless.default_radio${devidx}.ssid=5G/g' "$WIFI_SCRIPT"
	    echo "✓ WiFi 已强制开启，默认 SSID 改为 5G"
	else
	    echo "⚠️ 未找到 mac80211.sh，跳过 WiFi 修改"
	fi
	# 3. 写入 .config 配置文件
	cat > .config <<EOF
	CONFIG_TARGET_ath79=y
	CONFIG_TARGET_ath79_generic=y
	CONFIG_TARGET_ath79_generic_DEVICE_netgear_wndr3800=y
	CONFIG_USE_UPX=y
	CONFIG_STRIP_KERNEL_EXPORTS=y
	CONFIG_USE_MKLIBS=y
	# CONFIG_IPV6 is not set
	CONFIG_PACKAGE_luci-app-ssr-plus=y
	CONFIG_PACKAGE_luci-app-turbo-acc=y
	CONFIG_PACKAGE_luci-app-turbo-acc_INCLUDE_SHORTCUT_FE=y
	CONFIG_PACKAGE_luci-app-cpufreq=y
	CONFIG_PACKAGE_luci-app-zram=y
	CONFIG_PACKAGE_luci-app-vsftpd=y
	CONFIG_PACKAGE_luci-app-gargoyle-qos=y
	CONFIG_PACKAGE_luci-theme-argon=y
	CONFIG_PACKAGE_kmod-switch-rtl8366s=y
	CONFIG_PACKAGE_kmod-of-mdio=y
	CONFIG_PACKAGE_kmod-usb-ohci=y
	CONFIG_PACKAGE_kmod-usb2=y
	CONFIG_PACKAGE_kmod-usb-storage=y
	CONFIG_PACKAGE_kmod-fs-ext4=y
	CONFIG_PACKAGE_kmod-fs-vfat=y
	CONFIG_PACKAGE_kmod-nls-utf8=y
	CONFIG_PACKAGE_block-mount=y
	EOF
	echo "✓ .config 已写入"
	# 4. 创建 UCI 默认配置脚本
	mkdir -p package/base-files/files/etc/uci-defaults
	cat > package/base-files/files/etc/uci-defaults/99-init-settings <<'EOF'
	#!/bin/sh
	uci set system.@system[0].hostname='OpenWrt'
	uci commit system
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
	uci set qos.gargoyle.download_bandwidth='102400'
	uci set qos.gargoyle.upload_bandwidth='10240'
	uci set qos.class_1.percent_min='35'
	uci set qos.class_1.percent_max='95'
	uci set qos.class_2.percent_min='20'
	uci set qos.class_2.percent_max='80'
	uci set qos.class_3.percent_min='15'
	uci set qos.class_3.percent_max='60'
	uci set qos.class_4.percent_min='5'
	uci set qos.class_4.percent_max='40'
	uci commit qos
	exit 0
	EOF
	chmod +x package/base-files/files/etc/uci-defaults/99-init-settings
	echo "✓ UCI 默认配置脚本已创建"
	echo "diy-part2.sh 执行完成"
