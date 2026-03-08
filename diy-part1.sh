#!/bin/bash
set -e

echo "开始执行 diy-part1.sh (深度探索版)..."

# 1. 删除或清空 Python 依赖检查脚本（永久禁用 Python 版本检查）
PYTHON_CHECK_SCRIPT="scripts/prereq-build/00-python"
if [ -f "$PYTHON_CHECK_SCRIPT" ]; then
    # 备份原脚本（可选）
    cp "$PYTHON_CHECK_SCRIPT" "$PYTHON_CHECK_SCRIPT.bak"
    # 清空脚本内容，使其永远返回成功
    echo -e "#!/bin/sh\nexit 0" > "$PYTHON_CHECK_SCRIPT"
    chmod +x "$PYTHON_CHECK_SCRIPT"
    echo "✓ 已禁用 Python 版本检查"
else
    echo "⚠️ 未找到 $PYTHON_CHECK_SCRIPT，跳过"
fi

# 2. 锁定内核版本为 4.14
if [ -f "target/linux/ar71xx/Makefile" ]; then
    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    echo "✓ 内核版本已锁定为 4.14"
fi

# 3. 删除高版本内核配置文件，防止干扰
rm -f target/linux/ar71xx/config-5.* 2>/dev/null
rm -f target/linux/ar71xx/config-6.* 2>/dev/null
echo "✓ 已清理高版本内核配置"

echo "diy-part1.sh 执行完成"
