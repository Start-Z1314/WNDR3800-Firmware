#!/bin/bash

# 1. 添加额外的插件源 (可选)
# sed -i '$a src-git custom https://github.com/xiaorouji/openwrt-passwall' feeds.conf.default

# 2. 移除不必要的默认插件源 (可选)

# 强制锁定内核版本为 4.14
sed -i 's/LINUX_VERSION-.*/LINUX_VERSION-4.14/g' target/linux/ath79/Makefile