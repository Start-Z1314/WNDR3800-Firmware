#!/bin/bash
set -e
echo "开始执行 diy-part1.sh..."
if [ -f "target/linux/ar71xx/Makefile" ]; then
    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ar71xx/Makefile
    echo "✓ 内核版本已锁定为 4.14"
fi
rm -f target/linux/ar71xx/config-5.* 2>/dev/null
rm -f target/linux/ar71xx/config-6.* 2>/dev/null
echo "diy-part1.sh 执行完成"
