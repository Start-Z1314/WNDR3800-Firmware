#!/bin/bash

# 1. 添加额外的插件源 (可选)
# sed -i '$a src-git custom https://github.com/xiaorouji/openwrt-passwall' feeds.conf.default

# 2. 强制锁定内核版本为 4.14 (物理修改 Makefile)
# 这是最底层的锁定方式，防止编译系统自动升级内核
# 针对 Lean 源码，需要修改 KERNEL_PATCHVER
sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile
sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ath79/Makefile