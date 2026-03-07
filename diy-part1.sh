	#!/bin/bash
	set -e
	echo "开始执行 diy-part1.sh..."
	# 1. 锁定内核版本为 4.14
	if [ -f "target/linux/ath79/Makefile" ]; then
	    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile
	    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ath79/Makefile
	    echo "✓ 内核版本已锁定为 4.14"
	else
	    echo "⚠️ 警告：未找到 ath79 Makefile"
	fi
	# 2. 清理高版本内核配置
	rm -f target/linux/ath79/config-5.* 2>/dev/null
	rm -f target/linux/ath79/config-6.* 2>/dev/null
	echo "✓ 已清理高版本内核配置"
	# 3. 尝试应用安全补丁（如果失败则跳过，不中断编译）
	for pr in 13346 13368; do
	    echo "正在检查补丁 PR #$pr ..."
	    if wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply --check 2>/dev/null; then
	        wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply 2>/dev/null
	        echo "✓ 应用补丁 PR #$pr 成功"
	    else
	        echo "⚠️ 补丁 PR #$pr 不适用或已合并，跳过"
	    fi
	done
	echo "diy-part1.sh 执行完成"
