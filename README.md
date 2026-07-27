# OxideBot Root App Template

这是一个用于创建“自己的 OxideBot Android Root 应用”的 GitHub Template Repository，
不是一个预先实现好业务功能的通用机器人。

OxideBot 本身是 Rust Bot 框架。你需要选择 Bot 适配器、编写 Handler，并把自己的应用代码
放进 `runner/`。本模板负责把这份代码交叉编译成 Android ELF，再打包成兼容 Magisk、
KernelSU、SukiSU Ultra 和 APatch 的模块，同时生成模块 WebUI 和配套 Android 管理 App。

## 从模板开始

1. 点击 GitHub 仓库页面上的 **Use this template**。
2. 创建你自己的仓库，不要直接 fork 后沿用本模板的模块 ID。
3. 首先编辑 [`template.properties`](template.properties)：

   ```properties
   moduleId=my_oxidebot
   moduleName=My OxideBot
   moduleAuthor=your-github-name
   moduleDescription=My custom OxideBot application for Android Root
   versionName=0.1.0
   versionCode=1
   applicationId=dev.example.myoxidebot
   appName=My OxideBot
   requiredEnv=TELEGRAM_BOT_TOKEN
   repository=your-name/your-repository
   ```

4. 编辑 `runner/Cargo.toml`，加入你的 Bot 适配器、Handler 或业务 crate。
5. 用你自己的实现替换 `runner/src/example_handler.rs`，并在 `runner/src/main.rs` 注册。
6. 推送到 `main`。GitHub Actions 会构建四种 ABI、模块 ZIP 和测试 APK。
7. 测试完成并配置正式 Android 签名后，推送与 `versionName` 一致的 `v*` tag 发布。

## 模板配置

| 配置 | 用途 | 约束 |
|---|---|---|
| `moduleId` | Root 模块 ID、数据目录名 | 字母开头，只使用字母、数字、`.`、`_`、`-` |
| `moduleName` | Root 管理器和 WebUI 显示名称 | 建议保持简短、唯一 |
| `moduleAuthor` | `module.prop` 作者 | GitHub 用户名或组织名 |
| `moduleDescription` | 模块简介 | 不要换行 |
| `versionName` | 模块、APK 和 Release 版本 | 推荐 SemVer，例如 `0.1.0` |
| `versionCode` | Android/Root 数字版本 | 每次发布递增的整数 |
| `applicationId` | Android APK 唯一包名 | 例如 `io.github.alice.mybot` |
| `appName` | Android 桌面名称 | 可以与 `moduleName` 相同 |
| `requiredEnv` | 启动前必须非空的环境变量 | 逗号分隔，例如 `BOT_TOKEN,API_KEY`；可留空 |
| `repository` | 本地构建生成的 Release URL | `owner/repository`；Actions 中会自动使用当前仓库 |

构建时会根据这些值生成 `module.prop`、`update.json`、APK BuildConfig、WebUI 控制器路径和
独立数据目录。不要只修改根目录里的示例 `module.prop`；发布产物以
`template.properties` 为准。

## 示例应用

模板内的 runner 只是最小示例：

- 使用 `telegram_bot_oxidebot` 接收 Telegram 事件；
- 从 `TELEGRAM_BOT_TOKEN` 环境变量读取 Token；
- `/start` 返回模板说明；
- `/echo <text>` 回复输入内容。

入口在 [`runner/src/main.rs`](runner/src/main.rs)，示例 Handler 在
[`runner/src/example_handler.rs`](runner/src/example_handler.rs)。

典型的应用接线方式是：

```rust
oxidebot::OxideBotManager::new()
    .bot(my_bot_adapter)
    .await
    .filter(MyFilter)
    .handler(MyHandler::new(...).await?)
    .run_block()
    .await
```

你可以：

- 换成 `onebot_v11_oxidebot` 或其他 Bot 适配器；
- 引入自己发布的 Handler crate；
- 直接在 `runner/src/` 编写业务模块；
- 注册多个 Bot、Filter、Event Handler 和 Active Handler；
- 从 `env.conf` 读取数据库地址、Token、API Key 或其他运行配置。

请不要把真实 Token、Cookie 或 API Key 写进 Rust 源码、`template.properties` 或 GitHub
仓库。运行密钥应在安装后的 WebUI/App 中配置。

## Android 上的环境变量

安装后，在 Root 管理器 WebUI 或配套 App 中编辑：

```properties
TELEGRAM_BOT_TOKEN=123456:your-token
RUST_LOG=info
MY_API_URL=https://example.com/api
MY_API_KEY=secret
```

所有 `KEY=value` 会原样作为环境变量传给 runner。配置文件不是 Shell 脚本，不会执行
`$()` 或反引号。

每个模板项目使用独立目录：

```text
/data/adb/modules/<moduleId>/          模块、WebUI、控制器和 Android ELF
/data/adb/<moduleId>/env.conf          环境变量（0600）
/data/adb/<moduleId>/data/             应用工作目录和数据库
/data/adb/<moduleId>/logs/             日志和轮换日志
/data/adb/<moduleId>/run/              PID、锁和运行状态
```

## 本地构建

需要 Rust 1.97、Android SDK、Android NDK 29 和 Java 17。

```sh
bash runner/scripts/build-android.sh
bash build.sh

cd manager-app
./gradlew assembleDebug
```

也可以指定已有的 Android ELF 目录：

```sh
BINARY_DIR=/path/to/target bash build.sh
```

`build.sh` 会生成：

```text
build/<moduleId>-v<versionName>.zip
build/update.json
```

## CI

每次 `main` push、Pull Request 或手动运行都会执行：

1. 控制器、配置安全和模板渲染测试；
2. 四种 Android ABI 并行编译；
3. Android Debug 管理 App 构建；
4. 模块 ZIP 打包和完整性检查；
5. 生成包含模块、`update.json` 和 Debug APK 的 `oxidebot-root` artifact。

四种目标是：

- `aarch64-linux-android`
- `armv7-linux-androideabi`
- `x86_64-linux-android`
- `i686-linux-android`

普通 CI 不会创建 GitHub Release。

## 配置正式发布

正式 APK 必须使用你自己长期保存的签名证书。在仓库的
**Settings → Secrets and variables → Actions** 中配置：

- `ANDROID_SIGNING_KEY_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

例如：

```sh
base64 < my-release.jks | gh secret set ANDROID_SIGNING_KEY_BASE64
gh secret set ANDROID_KEYSTORE_PASSWORD
gh secret set ANDROID_KEY_ALIAS
gh secret set ANDROID_KEY_PASSWORD
```

然后确保 `template.properties` 中的 `versionName`、`versionCode` 已更新并提交，再发布：

```sh
git tag -a v0.1.0 -m "v0.1.0"
git push origin v0.1.0
```

tag 必须严格等于 `v<versionName>`。CD 会发布：

- `<moduleId>-v<versionName>.zip`
- `<moduleId>-manager-v<versionName>.apk`
- `update.json`

缺少签名 Secret 或 tag/版本不一致时，发布会安全失败，不会上传 Debug APK。

## 运行架构

```text
你的 Rust 代码 + OxideBot 框架 + Bot/Handler crates
                         │
                         ▼
                 Android ELF runner
                         │
             oxidebotctl / supervisor
                 ┌───────┴────────┐
                 ▼                ▼
       Root 管理器模块 WebUI    Android 管理 App
```

WebUI 是 KernelSU、SukiSU Ultra、APatch 的标准模块入口；Android App 为 Magisk 等场景提供
图形入口。两者复用同一套离线页面，但最终都只控制你的 runner，不包含远程 Web 服务。

## Root 兼容性

- Magisk
- KernelSU
- SukiSU Ultra
- APatch
- Android API 24+
- `arm64-v8a`、`armeabi-v7a`、`x86_64`、`x86`

## 许可证

模板本身使用 `GPL-3.0-only`。你加入的 OxideBot 适配器、Handler 和业务依赖可能有不同的
许可证；发布应用前请检查并遵守所有依赖的许可证要求。
