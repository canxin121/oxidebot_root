//! Minimal application example for the OxideBot Root template.
//!
//! Replace `ExampleHandler` with your own handlers and add any Bot adapters or
//! application dependencies you need in `runner/Cargo.toml`.

mod example_handler;

use anyhow::Context;
use example_handler::ExampleHandler;
use telegram_bot_oxidebot::bot::TelegramBot;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let token = std::env::var("TELEGRAM_BOT_TOKEN")
        .context("TELEGRAM_BOT_TOKEN is not set; configure it in env.conf")?;
    let telegram = TelegramBot::try_new(token, Default::default()).await?;

    oxidebot::OxideBotManager::new()
        .bot(telegram)
        .await
        .handler(ExampleHandler)
        // Add your filters and handlers here:
        // .filter(MyFilter)
        // .handler(MyHandler::new(...).await?)
        .run_block()
        .await
}
