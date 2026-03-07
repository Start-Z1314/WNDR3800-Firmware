#!/bin/bash
# ===============================================
# diy-part1.sh - 编译前源码预处理
# 主要任务: 锁定内核版本 + 合并安全补丁 + 可选添加插件源
# ===============================================

# 1. 添加额外的插件源 (根据需要取消注释)
# echo "添加 passwall 源"
# sed -i '$a src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git' feeds.conf.default
# sed -i '$a src-git passwall https://github.com/xiaorouji/openwrt-passwall.git' feeds.conf.default
# echo "✓ 已添加 passwall 源"

# 2. 强制锁定内核版本为 4.14
echo "正在锁定 ath79 内核版本为 4.14..."

if [ -f "target/linux/ath79/Makefile" ]; then
    cp target/linux/ath79/Makefile target/linux/ath79/Makefile.bak
    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ath79/Makefile
    echo "✓ 内核版本修改完成，当前配置："
    grep "KERNEL_PATCHVER" target/linux/ath79/Makefile | sed 's/^/  /'
else
    echo "⚠️ 错误：找不到 target/linux/ath79/Makefile"
    ls -la target/linux/ 2>/dev/null || echo "  target/linux/ 不存在"
    exit 1
fi

# 3. 合并安全补丁 (CVE-2026-24803 / CVE-2026-24804)
echo "正在合并安全补丁..."
if [ -d "package/lean/mt/drivers/mt7615d" ]; then
    echo "应用 mt7615d 驱动补丁 (CVE-2026-24803)..."
    wget -qO- https://github.com/coolsnowwolf/lede/pull/13346.patch | git apply || echo "警告: mt7615d 补丁应用失败，继续编译"
fi
if [ -d "package/lean/mt/drivers/mt7603e" ]; then
    echo "应用 mt7603e 驱动补丁 (CVE-2026-24804)..."
    wget -qO- https://github.com/coolsnowwolf/lede/pull/13368.patch | git apply || echo "警告: mt7603e 补丁应用失败，继续编译"
fi

# 4. 清理高版本内核配置
rm -f target/linux/ath79/config-5.* 2>/dev/null
rm -f target/linux/ath79/config-6.* 2>/dev/null
echo "✓ 已清理 5.x/6.x 内核配置文件"

# 5. 显示当前 feeds.conf.default 内容（用于调试）
echo "当前 feeds.conf.default 内容："
head -5 feeds.conf.default 2>/dev/null || echo "  feeds.conf.default 不存在"

echo "=================================="
echo "diy-part1.sh 执行完成"
