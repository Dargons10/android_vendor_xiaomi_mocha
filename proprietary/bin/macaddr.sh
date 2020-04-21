#!/system/bin/sh

TAG="mac_generator"
WIFI_FILE="/data/mocha_macaddr.txt"
BT_FILE="/data/mocha_btmacaddr.txt"

bkbIsBroken=0
#for Android
Serialno=$(getprop ro.serialno)
#for big Linux systems
#Serialno=$(echo $(dmesg | grep -i androidboot.serialno) | sed 's|.*serialno=||' | awk '{print $1}')
md5serialno=$(echo -n $Serialno | md5sum)

checkBkbPartition() {
	echo "$TAG: attempt to read BKB partition"
	local BKB=$(cat /dev/block/platform/sdhci-tegra.3/by-name/BKB | grep -a XIAOMI)
	if [ "$BKB" = "" ]; then
		bkbIsBroken=1
	fi;
}

generateBtMac() {
	echo "$TAG: generating bt mac address"
	local btMac="${md5serialno:3:2}:${md5serialno:16:2}:${md5serialno:17:2}:${md5serialno:9:2}:${md5serialno:11:2}:${md5serialno:13:2}"
	echo $btMac > ${BT_FILE}
	chown bluetooth:bluetooth ${BT_FILE}
	chmod 644 ${BT_FILE}
	setprop ro.bt.bdaddr_path ${BT_FILE}
	setprop persist.service.bdroid.bdaddr $btMac
	setprop ro.boot.btmacaddr $btMac
}

generateWifiMac() {
	echo "$TAG: generating wifi mac address"
	local wifiMac="0c:1d:${md5serialno:7:2}:${md5serialno:9:2}:${md5serialno:11:2}:${md5serialno:14:2}"
	echo $wifiMac > ${WIFI_FILE}
	chmod 644 ${WIFI_FILE}
}

main() {
	if [ -f ${BT_FILE} ] && [ -f ${WIFI_FILE} ]; then
		echo "$TAG: mac address file exist"
		btMac=`cat ${BT_FILE}`
		setprop ro.bt.bdaddr_path ${BT_FILE}
		setprop persist.service.bdroid.bdaddr $btMac
		setprop ro.boot.btmacaddr $btMac
		chown bluetooth:bluetooth ${BT_FILE}
		chmod 644 ${BT_FILE}
		chmod 644 ${WIFI_FILE}
		exit
	fi
	checkBkbPartition

	if [ "$bkbIsBroken" = 1 ]; then
		generateBtMac
		generateWifiMac
	else
		echo "$TAG: BKB partion is not broken"
	fi;
}

main
