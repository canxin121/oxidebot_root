//! Deliberately small OxideBot 1.0 command examples.
//!
//! `/start` explains that this is a template, while `/echo <text>` replies with
//! the supplied text. Delete this file when your own application handlers are
//! ready.

#[oxidebot::command("start")]
/// Explains that the template runner is ready.
pub async fn start() -> &'static str {
    "OxideBot Root template is running. Replace these example commands with your application. Try /echo hello."
}

#[oxidebot::command("echo")]
/// Repeats the supplied text.
pub async fn echo(#[arg(rest)] text: Vec<String>) -> String {
    let text = text.join(" ");
    if text.trim().is_empty() {
        "Usage: /echo <text>".to_owned()
    } else {
        text
    }
}
