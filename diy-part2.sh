#!/bin/bash

# 1. 修改默认 IP (可选，默认 192.168.1.1)
# sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# 2. 更加稳健的预设方式：使用 uci-defaults 脚本
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-custom-settings <<EOF
#!/bin/sh

# 预设 WiFi 名称、密码及区域 (自动匹配 radio0/radio1)
uci batch <<ABC
set wireless.radio0.disabled='0'
set wireless.radio0.country='US'
set wireless.radio0.channel='149'
set wireless.radio0.htmode='HT40'
set wireless.default_radio0.ssid='5G'
set wireless.default_radio0.encryption='psk2+ccmp'
set wireless.default_radio0.key='zld74502'

set wireless.radio1.disabled='0'
set wireless.radio1.country='US'
set wireless.radio1.channel='auto'
set wireless.radio1.htmode='HT20'
set wireless.default_radio1.ssid='5G'
set wireless.default_radio1.encryption='psk2+ccmp'
set wireless.default_radio1.key='zld74502'
commit wireless
ABC

# 设置管理密码为 12315555
(echo "12315555"; sleep 1; echo "12315555") | passwd > /dev/null

# 优化系统参数 (sysctl)
cat >> /etc/sysctl.conf <<ABC
net.netfilter.nf_conntrack_max=65535
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_fastopen=3
vm.swappiness=10
vm.vfs_cache_pressure=100
vm.min_free_kbytes=4096
ABC

# 提高文件句柄限制
sed -i '/ulimit -n/d' /etc/rc.local
sed -i '1i ulimit -n 65535' /etc/rc.local

exit 0
EOF

# 3. 修正默认 IP (可选)
# sed -i 's/192.168.1.1/192.168.1.1/g' package/base-files/files/bin/config_generate

# 预设 CPU 频率调节为 performance 模式
mkdir -p package/base-files/files/etc/config
cat > package/base-files/files/etc/config/cpufreq <<EOF
config cpufreq 'cpufreq'
	option governor 'performance'
	option min_freq '680000'
	option max_freq '680000'
EOF

# 预设 zRAM 虚拟内存 (针对 128MB 内存的救命稻草)
cat > package/base-files/files/etc/config/zram <<EOF
config zram
	option enabled '1'
	option size '64'
	option priority '100'
EOF

# 优化 Samba4 内存占用
sed -i 's/server multi channel support = yes/server multi channel support = no/g' package/network/services/samba4/files/smb.conf.template 2>/dev/null || true
echo "	smb encrypt = off" >> package/network/services/samba4/files/smb.conf.template
echo "	strict locking = no" >> package/network/services/samba4/files/smb.conf.template

# 预设 Turbo ACC 默认开启 SFE 和 DNS 加速
cat > package/base-files/files/etc/config/turboacc <<EOF
config turboacc 'config'
	option enabled '1'
	option sfe_flow '1'
	option hw_flow '0'
	option bbr_cca '0'
	option full_cone_nat '1'
	option dns_cache '1'
	option dns_cache_max '1024'
EOF

# 预设 Aria2 最优下载参数 (针对 128MB 内存)
cat > package/base-files/files/etc/config/aria2 <<EOF
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

# 极致精简：缩小系统日志缓冲区以节省内存
sed -i 's/log_size.*/log_size 16/g' package/base-files/files/etc/config/system 2>/dev/null || true

# 优化无线驱动参数：禁用 ath9k 频谱扫描以节省资源
echo "options ath9k spectral_scan=0" > package/base-files/files/etc/modprobe.d/ath9k.conf

# 预设 Samba4 共享配置 (NAS 功能)
cat > package/base-files/files/etc/config/samba4 <<EOF
config samba
	option workgroup 'WORKGROUP'
	option charset 'UTF-8'
	option description 'WNDR3800 NAS'
	option enable_v1 '1'

config share
	option name 'NAS'
	option path '/mnt/sda1'
	option read_only 'no'
	option guest_ok 'yes'
	option create_mask '0666'
	option dir_mask '0777'
EOF

# 禁用一些不必要的启动项
sed -i '/odhcpd/d' package/base-files/files/etc/rc.local

# 设置 Argon 为默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 预设 FTP (vsftpd) 优选配置
cat > package/base-files/files/etc/config/vsftpd <<EOF
config vsftpd 'main'
	option enabled '1'
	option local_enable '1'
	option write_enable '1'
	option local_umask '022'
	option check_vroot '0'
	option anonymous_enable '0'
	option root_login '1'
EOF

# 预设 eQoS (石像鬼) 默认配置 (针对 100M 宽带的保守预设)
cat > package/base-files/files/etc/config/eqos <<EOF
config eqos
	option enabled '1'
	option download '100000'
	option upload '20000'
EOF

# 预设 SSR-Plus 基础参数 (默认关闭开关，但预设好性能选项)
cat > package/base-files/files/etc/config/shadowsocksr <<EOF
config global
	option global_server 'nil'
	option udp_relay_server 'nil'
	option pdnsd_enable '1'
	option tunnel_forward '8.8.8.8:53'
	option run_mode 'router'
	option monitor_enable '1'
	option enable_switch '0'
EOF