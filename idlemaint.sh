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
    start_run_idlemaint
}

function show_volume_info()
{
    target_free_segs=$(cat $get_f2fs_sysfs/free_segments)
    target_dirty_segs=$(cat $get_f2fs_sysfs/dirty_segments)
    echo "[-] [$get_data_dev] 目前脏段: $target_dirty_segs"
    echo "[-] [$get_data_dev] 目前空闲段: $target_free_segs"
}

function start_run_idlemaint()
{
    show_volume_info
    # 当目标磁盘卷的脏段低于 256 跳过 GC
    if [ ! $(cat $get_f2fs_sysfs/dirty_segments) -ge 256 ]; then
        echo "[#] [$get_data_dev] 的脏段低于预设值 不需要 GC"
        exit 0
    fi

    sm idle-maint run; sleep 2; start_time=$(date +%s)
    echo "[-] [$get_data_dev] 空闲维护已开始, 请耐心等待"

    # 等待紧急GC节点为0 说明StartGc已完成
    while [ ! $(cat $get_f2fs_sysfs/gc_urgent) == 0 ]; do
        cur_time=$(date +%s); run_time=$((cur_time - start_time))
        echo -ne "[#] [$get_data_dev] 空闲维护 服务已运行 $run_time 秒\r"
        sleep 1 # 检查循环间隔 1秒
    done

    echo "[-] [$get_data_dev] 磁盘 空闲维护 已完成, 共耗时 $run_time 秒"
    show_volume_info
}

# Software main
amktiao_main
