# OxideBot for Root

面向现代 Android Root 生态重新设计的 OxideBot 后台运行模块。一个安装包支持
Magisk、KernelSU、SukiSU Ultra 和 APatch；同时提供模块 WebUI、Root 管理器中的动作按钮、
命令行控制器，以及使用同一界面的原生 Android 管理 App。

## 功能

- 支持 `arm64-v8a`、`armeabi-v7a`、`x86_64`、`x86` 四种 Android ABI。
- 开机延迟启动和轻量 supervisor；进程异常退出后带退避策略自动恢复。
- 启动、停止、重启、启用/关闭开机启动、实时状态、运行时长和日志查看。
- 现代响应式 WebUI，可直接在 KernelSU、SukiSU Ultra、APatch 等兼容管理器中打开。
- 原生 Android 管理 App，为 Magisk 等场景提供完整图形界面；App 只允许调用模块控制器。
- 环境变量使用持久化的 `env.conf`，模块更新不会覆盖 Token、数据库或日志。
- 配置按纯 `KEY=value` 解析，不执行 shell 命令替换；默认权限为 `0600`。
- 日志达到 2 MiB 时轮换，保留三份历史日志。

## 安装和首次运行

1. 从 Releases 下载 `oxidebot-root-v*.zip`，在 Root 管理器中选择“从本地安装”。
2. 重启 Android。
3. KernelSU / SukiSU / APatch 用户可在模块卡片中打开 WebUI；其他用户安装配套 APK。
4. 在「配置」页填写：

   ```properties
   TELEGRAM_BOT_TOKEN=123456:your-token
   RUST_LOG=info
   ```

5. 保存后回到首页点击「启动服务」。

数据与模块本体分离：

```text
/data/adb/modules/oxidebot_root/       模块、控制器和当前 ABI 二进制
/data/adb/oxidebot/env.conf            环境变量（0600）
/data/adb/oxidebot/data/               OxideBot 工作目录与数据库
/data/adb/oxidebot/logs/oxidebot.log   当前日志
/data/adb/oxidebot/run/                PID 和运行状态
```

卸载模块默认保留 `/data/adb/oxidebot`，便于重装。若确实需要随卸载一并清除，在卸载前把
`REMOVE_DATA_ON_UNINSTALL=1` 写入 `env.conf`。该操作不可恢复。

## 控制器

所有 UI 都通过同一个控制器工作，也可以直接在终端中使用：

```sh
su -c /data/adb/modules/oxidebot_root/scripts/oxidebotctl status
su -c /data/adb/modules/oxidebot_root/scripts/oxidebotctl start
su -c /data/adb/modules/oxidebot_root/scripts/oxidebotctl stop
su -c /data/adb/modules/oxidebot_root/scripts/oxidebotctl restart
su -c /data/adb/modules/oxidebot_root/scripts/oxidebotctl logs 200
```

模块管理器里的动作按钮会在“启用并启动”和“停止并关闭自动启动”之间切换。

## 本地构建

仓库内的 `runner` 是可公开构建的 OxideBot 运行程序入口。先构建它的四种 Android 目标：

```sh
bash runner/scripts/build-android.sh
bash build.sh
```

默认从 `runner/target` 打包，也可以用 `BINARY_DIR=/path/to/target bash build.sh` 指定其他
二进制目录。模块产物位于
`build/oxidebot-root-v*.zip`。

构建原生管理 App：

```sh
cd manager-app
./gradlew assembleDebug
```

WebUI 会在 Android 构建前自动同步到 App assets，因此两种入口不会产生两套交互逻辑。

## 验证

控制器测试不需要 Android 或 Root：

```sh
bash tests/controller_test.sh
```

项目的发布工作流会构建四种 ABI、运行控制器测试、生成模块 ZIP 和可侧载的管理 APK。

## 安全说明

- 不要把 Telegram Token 写入源码、Issue 或公开日志。
- 原生 App 的 JavaScript Root 桥只接受 `oxidebotctl` 的固定命令集合。
- 原生 App 不申请网络权限，也禁止 WebView 离开内置页面。
- WebUI 不依赖远程 CDN，不会把配置发送到网络。
- Root 环境本身拥有完整设备权限，请只安装来自可信 Release、且校验过的构建产物。

## 开源许可证

本仓库使用 `GPL-3.0-only`。OxideBot 核心及适配器各自的许可证与来源见其上游仓库。
