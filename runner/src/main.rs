//! Minimal application example for the OxideBot Root template.
//!
//! Replace the example commands with your own modules and add application
//! dependencies in `runner/Cargo.toml`.

mod example_handler;

use anyhow::Context as _;
use oxidebot::prelude::*;
use oxidebot_adapter_telegram::TelegramAdapter;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt::init();

    let token = std::env::var("TELEGRAM_BOT_TOKEN")
        .context("TELEGRAM_BOT_TOKEN is not set; configure it in env.conf")?;
    let bot_id = std::env::var("TELEGRAM_BOT_ID").context(
        "TELEGRAM_BOT_ID is not set; use the stable numeric ID before the colon in the bot token",
    )?;

    OxideBot::new()
        .adapter(TelegramAdapter::new(token, bot_id)?)
        .add(example_handler::start)
        .add(example_handler::echo)
        .include(Module::new().help())
        .run()
        .await?;

    Ok(())
}
