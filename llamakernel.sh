#!/bin/bash
rm .version
# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image"
DTBIMAGE="dtb"

# Kernel Details

VER=".R7.1-STOCK.h815."

# Paths
KERNEL_DIR=`pwd`
REPACK_DIR="${HOME}/android_device_lge_msm8992"
PATCH_DIR="${HOME}/android_device_lge_msm8992/patch"
MODULES_DIR="${HOME}/android_device_lge_msm8992/modules"
ZIP_MOVE="${HOME}/"
ZIMAGE_DIR="${HOME}/stock/arch/arm64/boot/"
RAMFS="${HOME}/ramdisk/Imperium_ramdisk_${ramdisk}/"
# Functions
function clean_all {
		find -name '*.dtb' -exec rm -rf {} \;
    find -name '*.ko' -exec rm -rf {} \;
		cd ~/stock/out/kernel
		rm -rf $RAMFS/Imperium_ramdisk_${ramdisk}.cpio.gz 
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $config
		make $THREAD CONFIG_NO_ERROR_ON_MISMATCH=y
		
}

function make_dtb {
		DTB=`find . -name "*.dtb" | head -1`echo $DTB
    echo $DTB
      DTBDIR=`dirname $DTB`
    echo $DTBDIR
    [[ -z `strings $DTB | grep "qcom,board-id"` ]] || DTBVERCMD="--force-v3"
    echo $DTBVERCMD
    ./scripts/dtbtoolv3 $DTBVERCMD -o dt.img -s 4096 -p scripts/dtc/ $DTBDIR/
}



function make_ramdisk {
cd $RAMFS
chmod -R g-w *
chmod g-w *.rc default.prop sbin/*.sh
chmod 644 file_contexts
chmod 644 se*
chmod 644 default.prop
chmod 750 *.rc
chmod 750 *.sh
chmod 640 fstab*
chmod 644 ueventd*
chmod 644 lge.fo*
chmod 644 set_emmc_size.sh
chmod 771 data
chmod 755 dev
chmod 555 proc
chmod 755 res
chmod 644 res/images/charger/*
chmod 750 sbin
chmod 750 sbin/*
chmod 755 sbin/busybox
chmod 777 sbin/*.sh
chmod 555 sys
chmod 755 system
find . | cpio -o -H newc | gzip > ../ramdisk.img
cd $KERNEL_DIR
}

function make_modules {
  rm -rf module
  mkdir -p module
		make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} -j4 INSTALL_MOD_PATH=module INSTALL_MOD_STRIP=1 modules_install
    find module/ -name '*.ko' -type f -exec cp '{}' out/system/lib/modules/ \;
    rm out/system/lib/modules/texfat.ko
    sh ./tuxera_update.sh --target target/lg.d/mobile-msm8992-3.10.84 --use-cache --latest --max-cache-entries 2 --source-dir . --output-dir . -a --user lg-mobile --pass AumlTsj0ou
    tar -xzf tuxera-exfat*.tgz
    perl ./scripts/sign-file sha1 signing_key.priv signing_key.x509 tuxera-exfat*/exfat/kernel-module/texfat.ko
    cp tuxera-exfat*/exfat/kernel-module/texfat.ko  out/system/lib/modules/
}
function make_boot {
		./scripts/mkbootimg --kernel $ZIMAGE_DIR/Image --ramdisk ${HOME}/ramdisk/ramdisk.img --base 0x00000000 --pagesize 4096 --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --cmdline 'console=ttyHSL0,115200,n8 androidboot.console=ttyHSL0 user_debug=31 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 androidboot.selinux=enforcing msm_rtb.filter=0x37 androidboot.hardware=p1' --dt dt.img -o out/boot.img
}

function make_zip {
		cd ~/stock/out
		zip -r9 `echo $AK_VER`.zip *
		mv  `echo $AK_VER`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")


echo -e "${green}"
echo "-----------------"
echo "Making Llama Kernel:"
echo "-----------------"
echo -e "${restore}"

echo "Pick variant..."
select choice in h815 h811 
do
case "$choice" in
	"h815")
		variant="h815"
   ramdisk="H815"
		config="cyanogenmod_h815_defconfig"
		break;;
	"h811")
		variant="h811"
		config="cyanogenmod_h811_defconfig"
		break;;
esac
done

while read -p "Do you want to use UBERTC 4.9(1) or UBERTC 5.3(2)? " echoice
do
case "$echoice" in
	1 )
		export CROSS_COMPILE=${HOME}/aarch64-linux-android-4.9-kernel-old/bin/aarch64-linux-android-
    export PATH=${HOME}/aarch64-linux-android-4.9-kernel-old/bin:$PATH
		TC="UBER4.9"
		echo
		echo "Using UBERTC 4.9"
		break
		;;
	2 )
		export CROSS_COMPILE=${HOME}/aarch64-linux-android-5.2-kernel/bin/aarch64-linux-android-
		TC="UBER5.3"
		echo
		echo "Using UBERTC 5.3"
		break
		;;
	3 )
		export CROSS_COMPILE=${HOME}/aarch64-linux-android-4.9-kernel/bin/aarch64-linux-android-
		TC="LINARO4.9"
		echo
		echo "Using Linaro 4.9"
		break
		;;
	4 )
		export CROSS_COMPILE=${HOME}/aarch64-linux-android-5.3-kernel/bin/aarch64-linux-android-
		TC="LINARO5.3"
		echo
		echo "Using Linaro 5.3"
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

# Vars
BASE_AK_VER="LlamaSweet"
AK_VER="$BASE_AK_VER$VER$TC"
export LOCALVERSION=~`echo $AK_VER`
export LOCALVERSION=~`echo $AK_VER`
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=genesixxbf3
export KBUILD_BUILD_HOST=build

echo

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build?" dchoice
do
case "$dchoice" in
	y|Y )
		make_kernel
		make_dtb
    make_ramdisk
		make_boot
    make_modules
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done


echo -e "${green}"
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
