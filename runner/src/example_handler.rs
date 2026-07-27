//! A deliberately small example handler.
//!
//! `/start` explains that this is a template, while `/echo <text>` replies with
//! the supplied text. Delete this file when your own application handlers are
//! ready.

use anyhow::Result;
use async_trait::async_trait;
use oxidebot::{
    source::message::MessageSegment, EventHandlerTrait, Handler, Matcher,
};

pub struct ExampleHandler;

impl From<ExampleHandler> for Handler {
    fn from(handler: ExampleHandler) -> Self {
        Self {
            event_handler: Some(Box::new(handler)),
            active_handler: None,
        }
    }
}

#[async_trait]
impl EventHandlerTrait for ExampleHandler {
    async fn handle(&self, matcher: Matcher) -> Result<()> {
        let Some(message) = matcher.try_get_message() else {
            return Ok(());
        };
        let text = message.get_raw_text();

        if text == "/start" {
            matcher
                .try_reply_message(vec![MessageSegment::text(
                    "OxideBot Root template is running. Replace ExampleHandler with your own application. Try /echo hello.",
                )])
                .await?;
        } else if let Some(echo) = text.strip_prefix("/echo") {
            let echo = echo.trim();
            let response = if echo.is_empty() {
                "Usage: /echo <text>"
            } else {
                echo
            };
            matcher
                .try_reply_message(vec![MessageSegment::text(response)])
                .await?;
        }

        Ok(())
    }
}
