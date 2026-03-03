#!/bin/bash

# 强制切换 ath79 架构内核为 4.14 (WNDR3800 性能巅峰内核)
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile

# 1. 添加额外的插件源 (可选)
# sed -i '$a src-git custom https://github.com/xiaorouji/openwrt-passwall' feeds.conf.default

# 2. 移除不必要的默认插件源 (可选)