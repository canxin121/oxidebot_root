# Application runner

这个目录是模板用户真正编写 OxideBot 应用的地方。

- `Cargo.toml`：添加 Bot 适配器、Handler 和业务依赖；
- `src/main.rs`：初始化适配器并注册 Filter/Handler；
- `src/example_handler.rs`：最小 `/start`、`/echo` 示例，可直接删除替换；
- `scripts/build-android.sh`：将当前 crate 交叉编译到四种 Android ABI；
- `Cargo.lock`：必须提交，保证 GitHub Actions 可复现构建。

修改依赖后运行：

```sh
cd runner
cargo check
cargo generate-lockfile
```

不要在这里硬编码 Token。使用 Android 模块的 `env.conf`，然后通过 `std::env::var` 读取。
runner 的 Cargo 包名固定为 `oxidebot_app`，模块/App 的用户可见身份由根目录
`template.properties` 控制，通常无需修改包名。
