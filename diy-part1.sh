	#!/bin/bash
	set -e
	echo "Starting diy-part1.sh..."
	# Lock kernel to 4.14
	if [ -f "target/linux/ath79/Makefile" ]; then
	    sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=4.14/g' target/linux/ath79/Makefile
	    sed -i 's/KERNEL_TESTING_PATCHVER:=.*/KERNEL_TESTING_PATCHVER:=4.14/g' target/linux/ath79/Makefile
	    echo "Kernel version locked to 4.14"
	fi
	# Cleanup high version configs
	rm -f target/linux/ath79/config-5.* 2>/dev/null
	rm -f target/linux/ath79/config-6.* 2>/dev/null
	echo "Cleaned high version kernel configs"
	# Apply patches
	for pr in 13346 13368; do
	    echo "Checking PR #$pr ..."
	    if wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply --check 2>/dev/null; then
	        wget -qO- "https://github.com/coolsnowwolf/lede/pull/$pr.patch" | git apply 2>/dev/null
	        echo "Applied PR #$pr"
	    else
	        echo "PR #$pr skipped or already applied"
	    fi
	done
	echo "diy-part1.sh completed"
