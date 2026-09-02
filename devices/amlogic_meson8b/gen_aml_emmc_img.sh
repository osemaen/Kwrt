#!/bin/bash

set -Eeuo pipefail

# 检查参数数量
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <output_image> <boot_partition_image> <rootfs_image>"
    exit 1
fi

OUTPUT_IMAGE=$1
BOOT_PARTITION_IMAGE=$2
ROOTFS_IMAGE=$3

command -v img2simg >/dev/null
test -s "$BOOT_PARTITION_IMAGE"
test -s "$ROOTFS_IMAGE"


# 下载并准备工具
ver="v0.3.1"
[ -f AmlImg ] || curl -fL -o ./AmlImg "https://github.com/hzyitc/AmlImg/releases/download/$ver/AmlImg_${ver}_linux_amd64"
chmod +x ./AmlImg
[ -f uboot.img ] || curl -fL -o ./uboot.img https://github.com/hzyitc/u-boot-onecloud/releases/download/build-20221028-0940/eMMC.burn.img
rm -rf burn
trap 'rm -rf burn' EXIT
./AmlImg unpack ./uboot.img burn/

# 转换镜像格式
img2simg "$BOOT_PARTITION_IMAGE" burn/boot.simg
img2simg "$ROOTFS_IMAGE" burn/rootfs.simg
test -s burn/boot.simg
test -s burn/rootfs.simg

# 创建命令文件
cat <<EOF >>burn/commands.txt
PARTITION:boot:sparse:boot.simg
PARTITION:rootfs:sparse:rootfs.simg
EOF

# 打包生成最终镜像
./AmlImg pack "$OUTPUT_IMAGE" burn/
test -s "$OUTPUT_IMAGE"

# 清理临时文件夹
rm -rf burn
trap - EXIT
