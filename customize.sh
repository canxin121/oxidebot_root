#!/system/bin/sh

SKIPUNZIP=1
SKIPMOUNT=true
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

if [ "$BOOTMODE" != "true" ]; then
  abort "! 请从 Root 管理器安装；不支持 Recovery 安装"
fi

# customize.sh 会在模块主体自动解压前执行，因此在这里统一展开安装内容。
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

module_name=$(sed -n 's/^name=//p' "$MODPATH/module.prop")
module_version=$(sed -n 's/^version=//p' "$MODPATH/module.prop")
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ui_print "  $module_name $module_version"
ui_print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$ARCH" in
  arm64) module_abi="arm64-v8a" ;;
  arm) module_abi="armeabi-v7a" ;;
  x64) module_abi="x86_64" ;;
  x86) module_abi="x86" ;;
  *) abort "! 不支持的设备架构：$ARCH" ;;
esac

if [ ! -f "$MODPATH/bin/$module_abi/oxidebot" ]; then
  abort "! 安装包中缺少 $module_abi 的 OxideBot 二进制"
fi

if [ "$KSU" = "true" ]; then
  ui_print "- Root 环境：KernelSU / SukiSU ($KSU_VER)"
elif [ "$APATCH" = "true" ]; then
  ui_print "- Root 环境：APatch"
else
  ui_print "- Root 环境：Magisk ($MAGISK_VER)"
fi
ui_print "- 设备架构：$module_abi"

DATA_DIR=${OXIDEBOT_DATA_DIR:-/data/adb/__MODULE_ID__}
mkdir -p "$DATA_DIR/run" "$DATA_DIR/logs" "$DATA_DIR/data"

if [ ! -f "$DATA_DIR/env.conf" ]; then
  cp "$MODPATH/env.example" "$DATA_DIR/env.conf"
  ui_print "- 已创建环境变量配置"
else
  ui_print "- 已保留现有环境变量配置"
fi

if [ ! -f "$DATA_DIR/enabled" ] && [ ! -f "$DATA_DIR/disabled" ]; then
  : > "$DATA_DIR/enabled"
fi

set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0755
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$DATA_DIR" 0 0 0700 0600

# KernelSU/SukiSU/APatch 会为 webroot 自动设置正确的权限和 SELinux 标签。
ui_print "- WebUI：受支持的管理器可直接点击“打开”"
ui_print "- 配置：$DATA_DIR/env.conf"
ui_print "- 首次启动前请在 WebUI 配置应用所需的环境变量"
ui_print "- 安装完成，请重启设备"
