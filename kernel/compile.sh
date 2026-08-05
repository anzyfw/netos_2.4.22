#!/bin/bash
set -e

# ====================== 路径配置 ======================
# 根目录
TOP_DIR=$(pwd)
# 原始纯净内核源码（不做任何修改）
KERNEL_SRC_ORIG="${TOP_DIR}/linux-2.4.22"
# 编译工作目录（源码副本）
BUILD_DIR="${TOP_DIR}/build"
KERNEL_BUILD="${BUILD_DIR}/linux-2.4.22"
# 最终安装目录
TARGET_DIR="${TOP_DIR}/target"
CONFIG_DIR="${TOP_DIR}/config"
# 架构
ARCH="i386"
CONFIG="config.i386"
#CONFIG="config.debug"

# ====================== 函数定义 ======================
# 打印日志
log_info() {
    echo "[INFO] $1"
}
log_warn() {
    echo "[WARN] $1"
}
log_error() {
    echo "[ERROR] $1"
}

# 1. 初始化目录 & 拷贝源码副本
prepare_env() {
    log_info "开始初始化编译环境..."
    mkdir -p "${BUILD_DIR}"
    mkdir -p "${TARGET_DIR}/boot"
    mkdir -p "${TARGET_DIR}/lib/modules"

    # 拷贝原始源码到编译目录（原源码保持纯净）
    if [ ! -d "${KERNEL_BUILD}" ]; then
        log_info "拷贝内核源码至编译目录: ${KERNEL_BUILD}"
        cp -a "${KERNEL_SRC_ORIG}" "${BUILD_DIR}/"
    else
        log_info "编译目录源码已存在，跳过拷贝"
    fi
}

# 2. 清理编译目录
clean_build() {
    log_info "清理编译目录残留文件..."
    cd "${KERNEL_BUILD}"
    make mrproper
    cd "${TOP_DIR}"
}

# 3. 加载内核默认配置 + 补全配置
gen_config() {
    log_info "加载内核默认 i386 配置..."
    # 使用现成的配置文件config.xyz
    cp ${CONFIG_DIR}/${CONFIG} ${KERNEL_BUILD}/.config
    cd "${KERNEL_BUILD}"
    # 自动确认所有新增配置项（无交互）
    yes "" | make oldconfig
    cd "${TOP_DIR}"
}

# 4. 2.4内核必备：生成依赖
make_dep() {
    log_info "生成内核编译依赖..."
    cd "${KERNEL_BUILD}"
    make dep
    cd "${TOP_DIR}"
}

# 5. 编译内核镜像 bzImage
compile_bzImage() {
    log_info "开始编译内核镜像 bzImage..."
    cd "${KERNEL_BUILD}"
    make bzImage
    cd "${TOP_DIR}"
    log_info "内核镜像编译完成"
}

# 6. 编译内核模块
compile_modules() {
    log_info "开始编译内核模块..."
    cd "${KERNEL_BUILD}"
    make modules
    cd "${TOP_DIR}"
    log_info "内核模块编译完成"
}

# 7. 安装模块到 target
install_modules() {
    log_info "安装内核模块至 ${TARGET_DIR}"
    cd "${KERNEL_BUILD}"
    make modules_install INSTALL_MOD_PATH="${TARGET_DIR}"
    cd "${TOP_DIR}"
}

# 8. 拷贝内核镜像与符号表到 target
install_kernel() {
    log_info "拷贝内核镜像与符号表至 ${TARGET_DIR}/boot"
    # Linux 2.4.22 镜像路径：arch/i386/bzImage
    cp "${KERNEL_BUILD}/vmlinux" "${TARGET_DIR}/boot/vmlinuz-2.4.22"
    cp "${KERNEL_BUILD}/System.map" "${TARGET_DIR}/boot/System.map-2.4.22"
    cp "${KERNEL_BUILD}/arch/${ARCH}/boot/bzImage" "${TARGET_DIR}/boot/bzImage"
}

# 9. 完全清理（build + target）
full_clean() {
    log_info "执行全量清理 build/ + target/"
    rm -rf "${BUILD_DIR}"
    rm -rf "${TARGET_DIR}"
}

# ====================== 主逻辑 & 入口 ======================
usage() {
    echo "用法: $0 [命令]"
    echo "  无参数    : 完整编译 + 安装"
    echo "  clean     : 仅清理编译目录 build"
    echo "  distclean : 完全清理 build + target"
    exit 1
}

# 分支判断
case "$1" in
    "")
        # 完整流程：编译 + 安装
        prepare_env
        clean_build
        gen_config
        make_dep
        compile_bzImage
        compile_modules
        install_modules
        install_kernel
        log_info "========================================"
        log_info "编译&安装全部完成！"
        #log_info "内核镜像: ${TARGET_DIR}/boot/vmlinuz-2.4.22"
        log_info "内核镜像: ${TARGET_DIR}/boot/bzImage"
        log_info "模块目录: ${TARGET_DIR}/lib/modules/"
        log_info "========================================"
        ;;
    clean)
        full_clean
        ;;
    *)
        log_error "未知参数: $1"
        usage
        ;;
esac
