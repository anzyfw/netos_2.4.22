
# ======================================================================
# Linux 2.4.22 绝对干净编译（源码零修改、零污染）
# 原理：复制源码到 build 目录编译，原始源码永远不动
# ======================================================================

TOPDIR         := $(CURDIR)
KERNEL_ORIG    := $(TOPDIR)/linux-2.4.22
BUILD_DIR      := $(TOPDIR)/build
KERNEL_BUILD   := $(BUILD_DIR)/linux-2.4.22
TARGET_DIR     := $(TOPDIR)/target
CONFIG_DIR     := $(TOPDIR)/config
ARCH           := i386
CONFIG         := config.i386

# 默认：完整编译
#all: build
all: install

# 1. 创建目录 + 复制干净源码（关键！只拷贝，不写原目录）
prepare:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(TARGET_DIR)/boot
	@mkdir -p $(TARGET_DIR)/lib/modules
	@if [ ! -d $(KERNEL_BUILD) ]; then \
		echo "Copy clean kernel source to build directory..."; \
		cp -a $(KERNEL_ORIG) $(BUILD_DIR)/; \
	fi

# 2. 清理编译目录（不碰原始源码）
mrproper: prepare
	@cd $(KERNEL_BUILD) && make mrproper

# 3. 使用默认配置
defconfig: mrproper
	#@cp $(KERNEL_BUILD)/arch/$(ARCH)/defconfig $(KERNEL_BUILD)/.config
	#@cd $(KERNEL_BUILD) && yes "" | make oldconfig
	@cp $(CONFIG_DIR)/$(CONFIG) $(KERNEL_BUILD)/.config

# 4. 生成依赖
dep: defconfig
	@cd $(KERNEL_BUILD) && make dep

# 5. 编译内核
bzImage: dep
	@cd $(KERNEL_BUILD) && make bzImage

# 6. 编译模块
modules: bzImage
	@cd $(KERNEL_BUILD) && make modules

# 7. 完整编译
build: modules

# 8. 安装到 target
install: build
	@cd $(KERNEL_BUILD) && make modules_install INSTALL_MOD_PATH=$(TARGET_DIR)
	@cp $(KERNEL_BUILD)/vmlinux $(TARGET_DIR)/boot/vmlinuz-2.4.22
	@cp $(KERNEL_BUILD)/System.map $(TARGET_DIR)/boot/System.map-2.4.22
	@cp $(KERNEL_BUILD)/arch/$(ARCH)/boot/bzImage $(TARGET_DIR)/boot/bzImage

# 9. 彻底清理
clean:
	rm -rf $(BUILD_DIR)
	rm -rf $(TARGET_DIR)
