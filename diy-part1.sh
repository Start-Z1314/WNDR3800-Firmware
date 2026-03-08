#!/bin/bash
set -e

echo "开始执行 diy-part1.sh (旧版源码)..."

# 1. 锁定内核版本为 4.14（旧版源码默认可能已是4.14，但为确保安全仍执行）
if [ -f "target/linux/ar71xx/Makefile" ]; then
    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    echo "✓ 内核版本已锁定为 4.14"
else
    echo "⚠️ 警告：未找到 target/linux/ar71xx/Makefile"
fi

# 2. 安全补丁（仅当补丁与旧版源码兼容时应用）
for pr in 13346 13368; do
    if wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply --check 2>/dev/null; then
        wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply 2>/dev/null
        echo "✓ 应用补丁 PR #$pr 成功"
    else
        echo "⚠️ 补丁 PR #$pr 与当前源码不兼容，跳过"
    fi
done

# 3. 删除高版本内核配置文件（清理可能残留的5.x/6.x配置）
rm -f target/linux/ar71xx/config-5.* 2>/dev/null
rm -f target/linux/ar71xx/config-6.* 2>/dev/null
echo "✓ 已清理高版本内核配置"

echo "diy-part1.sh 执行完成"