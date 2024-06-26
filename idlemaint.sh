#!/vendor/bin/sh
# F2FS Urgent GC Trigger Scripts
# By Amktiao Date: 2024-02-28

mversion="20240526"
model_name=$(getprop ro.product.name)
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
    echo "[-] 版本: $mversion 机型: $model_name"

    check_run_context
    case $model_name in
        "munch"* | "pipa")
            start_run_urgent_gc;;
        *)
            start_run_idlemaint;;
    esac
}

function show_volume_info()
{
    target_free_segs=$(cat $get_f2fs_sysfs/free_segments)
    target_dirty_segs=$(cat $get_f2fs_sysfs/dirty_segments)
    echo "[-] [$get_data_dev] 目前脏段: $target_dirty_segs"
    echo "[-] [$get_data_dev] 目前空闲段: $target_free_segs"
}

function start_run_urgent_gc()
{
    show_volume_info
    # 当目标磁盘卷的脏段低于 256 跳过 GC
    if [ ! $(cat $get_f2fs_sysfs/dirty_segments) -ge 256 ]; then
        echo "[#] [$get_data_dev] 的脏段低于预设值 不需要 GC"
        exit 0
    fi

    echo "[-] [$get_data_dev] 紧急GC 已开始, 请耐心等待"
    echo 1 > $get_f2fs_sysfs/gc_urgent; start_time=$(date +%s)

    # 等待脏段数量低于 200 或 超时8分钟 停止紧急GC
    while [ $(cat $get_f2fs_sysfs/dirty_segments) -ge 200 ]; do
        cur_time=$(date +%s); run_time=$((cur_time - start_time))
        if [ $run_time -ge 480 ]; then
            echo "[#] [$get_data_dev] 紧急GC 超时 已强制停止"
            break
        fi
        echo -ne "[#] [$get_data_dev] 紧急GC 已运行 $run_time 秒\r"
        sleep 1 # 检查循环间隔 1秒
    done

    echo 0 > $get_f2fs_sysfs/gc_urgent
    echo "[-] [$get_data_dev] 磁盘 紧急GC 已结束, 共耗时 $run_time 秒"
    show_volume_info
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
