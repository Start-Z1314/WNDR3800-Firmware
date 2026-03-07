	#!/bin/bash
	set -e
	echo "开始执行 diy-part1.sh..."
	# 1. 锁定内核版本为 4.14
	if [ -f "target/linux/ath79/Makefile" ]; then
	    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile
	    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ath79/Makefile
	    echo "✓ 内核版本已锁定为 4.14"
	fi
	# 2. 合并安全补丁（如果适用）
	# 注意：如果补丁因内核版本差异失败，脚本会继续执行
	for pr in 13346 13368; do
	    wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply --check 2>/dev/null && {
	        wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply 2>/dev/null
	        echo "✓ 应用补丁 PR #$pr 成功"
	    } || {
	        echo "⚠️ 补丁 PR #$pr 应用失败或已存在，跳过"
	    }
	done
	# 3. 删除高版本内核配置文件，防止干扰
	rm -f target/linux/ath79/config-5.* 2>/dev/null
	rm -f target/linux/ath79/config-6.* 2>/dev/null
	rm -f target/linux/ath76/config-5.* 2>/dev/null
	echo "✓ 已清理高版本内核配置"
	echo "diy-part1.sh 执行完成"