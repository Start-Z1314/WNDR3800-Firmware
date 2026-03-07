#!/bin/bash

# 1. 添加额外的插件源 (可选)
# sed -i '$a src-git custom https://github.com/xiaorouji/openwrt-passwall' feeds.conf.default

# 2. 强制锁定内核版本为 4.14 (物理修改 Makefile)
# 这是最底层的锁定方式，防止编译系统自动升级内核
sed -i 's/LINUX_VERSION-.*/LINUX_VERSION-4.14/g' target/linux/ath79/Makefile