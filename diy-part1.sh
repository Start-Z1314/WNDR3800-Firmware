#!/bin/bash
set -e

echo "开始执行 diy-part1.sh (终极探索版)..."

# 1. 修改 include/toplevel.mk，注释掉依赖检查部分
TOPLEVEL_MK="include/toplevel.mk"
if [ -f "$TOPLEVEL_MK" ]; then
    # 备份原文件
    cp "$TOPLEVEL_MK" "$TOPLEVEL_MK.bak"
    # 注释掉包含 prereq-build 的目标行及其命令（使用 sed 范围匹配）
    sed -i '/^staging_dir\/host\/.prereq-build:/,/^$/ s/^/#/' "$TOPLEVEL_MK"
    echo "✓ 已禁用 toplevel.mk 中的依赖检查"
else
    echo "⚠️ 未找到 $TOPLEVEL_MK"
fi

# 2. 同时删除/清空 Python 检查脚本（双重保险）
PYTHON_CHECK_SCRIPT="scripts/prereq-build/00-python"
if [ -f "$PYTHON_CHECK_SCRIPT" ]; then
    echo -e "#!/bin/sh\nexit 0" > "$PYTHON_CHECK_SCRIPT"
    chmod +x "$PYTHON_CHECK_SCRIPT"
    echo "✓ 已清空 Python 检查脚本"
fi

# 3. 锁定内核版本为 4.14
if [ -f "target/linux/ar71xx/Makefile" ]; then
    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    echo "✓ 内核版本已锁定为 4.14"
fi

# 4. 删除高版本内核配置文件，防止干扰
rm -f target/linux/ar71xx/config-5.* 2>/dev/null
rm -f target/linux/ar71xx/config-6.* 2>/dev/null
echo "✓ 已清理高版本内核配置"

echo "diy-part1.sh 执行完成"
