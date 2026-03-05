#!/bin/bash

# ============================================================================
# WNDR3800 OpenWrt 方案 A (最大稳定性) - 详细参数预设脚本
# 基于 OpenWrt 22.03 + Kernel 4.14
# 所有功能预设为刷好即用的最佳状态
# ============================================================================

# 1. 修改默认 IP (192.168.1.1 - 保持默认)
# sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# ============================================================================
# 第一部分：系统级参数优化 (sysctl)
# ============================================================================

mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/99-custom-settings <<'EOF'
#!/bin/sh

# ============================================================================
# 一、系统参数优化 - 针对 128MB 内存的保守配置
# ============================================================================

# 添加到 /etc/sysctl.conf
cat >> /etc/sysctl.conf <<'SYSCTL'
# ===== 网络缓冲区优化 =====
net.core.rmem_max=16777216        # 接收缓冲区上限 16MB
net.core.wmem_max=16777216        # 发送缓冲区上限 16MB
net.core.netdev_max_backlog=5000  # 网卡驱动缓冲队列

# ===== TCP 参数优化 =====
net.ipv4.tcp_fastopen=3           # 启用 TCP 快速打开 (客户端+服务器)
net.ipv4.tcp_tw_reuse=1           # 快速回收 TIME_WAIT 连接
net.ipv4.tcp_fin_timeout=20       # FIN_WAIT2 超时时间 20s (默认 60s)
net.ipv4.tcp_keepalive_time=300   # TCP 保活时间 300s (5分钟)

# ===== 连接跟踪参数 =====
net.netfilter.nf_conntrack_max=65535       # 最大连接跟踪数
net.netfilter.nf_conntrack_tcp_timeout_established=432000  # TCP 连接超时 5 天

# ===== 内存管理参数 =====
vm.swappiness=10                  # 内存交换激进性 (保守)
vm.vfs_cache_pressure=100         # VFS 缓存压力
vm.min_free_kbytes=4096           # 保留最小可用内存 4MB
vm.overcommit_memory=1            # 允许过度申请内存

# ===== 文件系统参数 =====
fs.file-max=65535                 # 系统文件描述符总数
fs.inotify.max_user_watches=8192  # inotify 监视上限
SYSCTL

# ===== 提高文件句柄限制 =====
sed -i '/ulimit -n/d' /etc/rc.local 2>/dev/null || true
sed -i '$i ulimit -n 65535' /etc/rc.local

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-custom-settings

# ============================================================================
# 第二部分：设置管理密码
# ============================================================================

mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/98-set-password <<'EOF'
#!/bin/sh

# ===== 设置 root 密码为 12315555 =====
# 登录方式: 用户名 root, 密码 12315555
(echo "12315555"; sleep 1; echo "12315555") | passwd > /dev/null 2>&1

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/98-set-password

# ============================================================================
# 第三部分：CPU 频率调节 (performance 模式确保稳定性)
# ============================================================================

mkdir -p package/base-files/files/etc/config

cat > package/base-files/files/etc/config/cpufreq <<'EOF'
config cpufreq 'cpufreq'
	option enabled '1'
	option governor 'performance'
	option min_freq '680000'
	option max_freq '800000'
EOF

# ============================================================================
# 第四部分：虚拟内存配置 (zRAM) - 为 128MB 内存扩展
# ============================================================================

cat > package/base-files/files/etc/config/zram <<'EOF'
config zram
	option enabled '1'
	option size '64'
	option priority '100'
EOF

# ============================================================================
# 第五部分：网络加速配置 (Turbo ACC - SFE 加速)
# ============================================================================

cat > package/base-files/files/etc/config/turboacc <<'EOF'
config turboacc 'config'
	option enabled '1'
	option sfe_flow '1'
	option hw_flow '0'
	option bbr_cca '0'
	option full_cone_nat '1'
	option dns_cache '1'
	option dns_cache_max '1024'
EOF

# ============================================================================
# 第六部分：Aria2 下载配置 (NAS/下载功能预设)
# ============================================================================

cat > package/base-files/files/etc/config/aria2 <<'EOF'
config aria2 'main'
	option enabled '0'
	option user 'aria2'
	option dir '/mnt/sda1/download'
	option config_dir '/etc/aria2'
	option port '6800'
	option rpc_secret '12315555'
	option max_concurrent_downloads '2'
	option max_connection_per_server '5'
	option min_split_size '10M'
	option split '5'
	option disk_cache '2M'
EOF

# ============================================================================
# 第七部分：Samba4 NAS 共享配置 (内存优化版)
# ============================================================================

mkdir -p package/base-files/files/etc/config

cat > package/base-files/files/etc/config/samba4 <<'EOF'
config samba
	option workgroup 'WORKGROUP'
	option charset 'UTF-8'
	option description 'WNDR3800'
	option enable_v1 '1'

config share
	option name 'NAS'
	option path '/mnt/sda1'
	option read_only 'no'
	option guest_ok 'yes'
	option create_mask '0666'
	option dir_mask '0777'
EOF

# Samba4 内存优化补丁
sed -i 's/server multi channel support = yes/server multi channel support = no/g' package/network/services/samba4/files/smb.conf.template 2>/dev/null || true
echo "	smb encrypt = off" >> package/network/services/samba4/files/smb.conf.template 2>/dev/null || true
echo "	strict locking = no" >> package/network/services/samba4/files/smb.conf.template 2>/dev/null || true

# ============================================================================
# 第八部分：vsftpd FTP 配置 (轻量级)
# ============================================================================

cat > package/base-files/files/etc/config/vsftpd <<'EOF'
config vsftpd 'main'
	option enabled '1'
	option local_enable '1'
	option write_enable '1'
	option local_umask '022'
	option check_vroot '0'
	option anonymous_enable '0'
	option root_login '1'
EOF

# ============================================================================
# 第九部分：eQoS 流量管理配置 (QoS)
# ============================================================================

cat > package/base-files/files/etc/config/eqos <<'EOF'
config eqos
	option enabled '1'
	option download '100000'
	option upload '20000'
EOF

# ============================================================================
# 第十部分：无线驱动优化 (ath9k 频谱扫描禁用)
# ============================================================================

mkdir -p package/base-files/files/etc/modprobe.d

cat > package/base-files/files/etc/modprobe.d/ath9k.conf <<'EOF'
options ath9k spectral_scan=0
EOF

# ============================================================================
# 第十一部分：WiFi 无线配置 (详细参数预设 - 最优状态)
# ============================================================================

mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/97-wireless-config <<'EOF'
#!/bin/sh

# ===== WiFi 配置详解 =====
# WNDR3800 双频 WiFi: 2.4GHz (radio1) + 5GHz (radio0)
# 每个频段都有 1x1 天线，最高 150Mbps

# 2.4GHz WiFi 配置 (radio1)
uci batch <<'UCI'
# 基础配置
set wireless.radio1=wifi-device
set wireless.radio1.type='mac80211'
set wireless.radio1.hwmode='11g'
set wireless.radio1.disabled='0'
set wireless.radio1.country='US'
set wireless.radio1.channel='6'
set wireless.radio1.tx_power='20'

# 性能优化
set wireless.radio1.htmode='HT20'
set wireless.radio1.noscan='1'
set wireless.radio1.diversity='1'

# 网络接口配置 (2.4GHz)
set wireless.default_radio1=wifi-iface
set wireless.default_radio1.device='radio1'
set wireless.default_radio1.network='lan'
set wireless.default_radio1.mode='ap'
set wireless.default_radio1.ssid='5G'
set wireless.default_radio1.encryption='psk2'
set wireless.default_radio1.cipher='ccmp'
set wireless.default_radio1.key='zld74502'
set wireless.default_radio1.isolate='0'
set wireless.default_radio1.wmm='1'

# 5GHz WiFi 配置 (radio0)
set wireless.radio0=wifi-device
set wireless.radio0.type='mac80211'
set wireless.radio0.hwmode='11a'
set wireless.radio0.disabled='0'
set wireless.radio0.country='US'
set wireless.radio0.channel='149'
set wireless.radio0.tx_power='20'

# 性能优化
set wireless.radio0.htmode='HT40'
set wireless.radio0.noscan='1'
set wireless.radio0.diversity='1'

# 网络接口配置 (5GHz)
set wireless.default_radio0=wifi-iface
set wireless.default_radio0.device='radio0'
set wireless.default_radio0.network='lan'
set wireless.default_radio0.mode='ap'
set wireless.default_radio0.ssid='5G'
set wireless.default_radio0.encryption='psk2'
set wireless.default_radio0.cipher='ccmp'
set wireless.default_radio0.key='zld74502'
set wireless.default_radio0.isolate='0'
set wireless.default_radio0.wmm='1'

commit wireless
UCI

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/97-wireless-config

# ============================================================================
# 第十二部分：网络接口配置 (LAN/WAN 预设)
# ============================================================================

cat > package/base-files/files/etc/uci-defaults/96-network-config <<'EOF'
#!/bin/sh

uci batch <<'UCI'
# LAN 口配置 - 默认 DHCP 服务器模式
set network.lan=interface
set network.lan.ifname='eth0.1'
set network.lan.proto='static'
set network.lan.ipaddr='192.168.1.1'
set network.lan.netmask='255.255.255.0'

# LAN 口 DHCP 服务
set dhcp.lan=dhcp
set dhcp.lan.interface='lan'
set dhcp.lan.start='100'
set dhcp.lan.limit='150'
set dhcp.lan.leasetime='12h'
set dhcp.lan.dhcpv6='off'

# 禁用 IPv6
set network.lan.ipv6='off'

# DNS 设置
set dhcp.@dnsmasq[0].cachesize='1024'
set dhcp.@dnsmasq[0].logqueries='0'

commit network
commit dhcp
UCI

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/96-network-config

# ============================================================================
# 第十三部分：系统时间和日志配置
# ============================================================================

cat > package/base-files/files/etc/uci-defaults/95-system-config <<'EOF'
#!/bin/sh

uci batch <<'UCI'
# 系统基本设置
set system.@system[0]=system
set system.@system[0].hostname='WNDR3800'
set system.@system[0].timezone='CST-8'
set system.@system[0].zonename='Asia/Shanghai'

# 日志配置 (极致节省空间)
set system.@system[0].log_size='16'
set system.@system[0].log_type='file'

# 自动重启配置 (可选)
set system.@system[0].log_remote='0'

commit system
UCI

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/95-system-config

# ============================================================================
# 第十四部分：防火墙配置 (默认启用，保证安全)
# ============================================================================

cat > package/base-files/files/etc/uci-defaults/94-firewall-config <<'EOF'
#!/bin/sh

uci batch <<'UCI'
# 防火墙默认配置
set firewall.@defaults[0]=defaults
set firewall.@defaults[0].syn_flood='1'
set firewall.@defaults[0].drop_invalid='1'
set firewall.@defaults[0].tcp_syncookies='1'
set firewall.@defaults[0].input='ACCEPT'
set firewall.@defaults[0].output='ACCEPT'
set firewall.@defaults[0].forward='REJECT'

commit firewall
UCI

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/94-firewall-config

# ============================================================================
# 第十五部分：Argon 主题预设为默认
# ============================================================================

sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# ============================================================================
# 第十六部分：极致精简 - 系统优化脚本
# ============================================================================

mkdir -p package/base-files/files/etc/rc.d

cat > package/base-files/files/etc/rc.d/S99-system-optimize <<'EOF'
#!/bin/sh
# 开机启动的系统优化脚本

# 应用 sysctl 参数
sysctl -p > /dev/null 2>&1

# 清理页面缓存 (保留最少必要内存)
sync
echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true

# 启用 BBR 拥塞控制算法 (如果内核支持)
echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || true

# 关闭不必要的日志级别
echo 3 > /proc/sys/kernel/printk 2>/dev/null || true

exit 0
EOF

chmod +x package/base-files/files/etc/rc.d/S99-system-optimize

# ============================================================================
# 第十七部分：禁用不必要的启动服务 (节省内存)
# ============================================================================

cat > package/base-files/files/etc/uci-defaults/93-disable-services <<'EOF'
#!/bin/sh

# 禁用 UPnP (如果已安装，节省 ~5MB 内存)
uci set upnp.upnp.enabled='0' 2>/dev/null || true

# 禁用 mDNS 广播 (节省资源)
uci set avahi.main.enable_dbus='0' 2>/dev/null || true

uci commit upnp 2>/dev/null || true
uci commit avahi 2>/dev/null || true

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/93-disable-services

echo "==================================================================="
echo "WNDR3800 方案 A 参数预设完成"
echo "==================================================================="
echo "✓ 编译架构: OpenWrt 22.03 + Kernel 4.14"
echo "✓ 目标稳定性: 最大稳定性优先"
echo "✓ 网络加速: SFE + DNS 缓存"
echo "✓ WiFi 配置: 已预设最优参数"
echo "✓ 默认密码: 12315555 (root 用户)"
echo "✓ 网络地址: 192.168.1.1"
echo "==================================================================="
