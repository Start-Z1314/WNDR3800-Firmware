#!/bin/bash
# 锁定内核版本为 4.14
if [ -f "target/linux/ath79/Makefile" ]; then
    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ath79/Makefile
fi

# 合并安全补丁（如果存在）
for pr in 13346 13368; do
    wget -qO- https://github.com/coolsnowwolf/lede/pull/$pr.patch | git apply 2>/dev/null || true
done

# 删除高版本内核配置
rm -f target/linux/ath79/config-5.* target/linux/ath79/config-6.* 2>/dev/null
