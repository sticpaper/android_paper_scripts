#!/vendor/bin/sh
# F2FS Urgent GC Trigger Scripts
# By Amktiao Date: 2024-02-28

mversion="20240526"
get_data_dev=$(getprop dev.mnt.dev.data)
get_f2fs_sysfs="/sys/fs/f2fs/$get_data_dev"

function check_run_context()
{
    PATH="/system/bin:$PATH"; export PATH
    if [ `whoami` != "root" ]; then
        echo "[!] 未使用Root模式运行, 已自动退出"
        echo "[#] 在运行前勾上Root再重试"; exit 0
    fi

    if [ ! -d "$get_f2fs_sysfs" ]; then
        echo "[!] 您的设备不是 F2FS 文件系统"
        echo "[#] 空闲维护仅支持 F2FS 环境"; exit 0
    fi
}

function amktiao_main()
{
    echo "[-] F2FS 触发 紧急GC 回收小工具"
    echo "[-] 版本: $mversion"

    check_run_context
}

function show_volume_info()
{
    target_free_segs=$(cat $get_f2fs_sysfs/free_segments)
    target_dirty_segs=$(cat $get_f2fs_sysfs/dirty_segments)
    echo "[-] [$get_data_dev] 目前脏段: $target_dirty_segs"
    echo "[-] [$get_data_dev] 目前空闲段: $target_free_segs"
}

# Software main
amktiao_main
