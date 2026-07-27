package io.github.canxin121.oxidebotroot;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.graphics.Color;
import android.os.Bundle;
import android.net.Uri;
import android.view.View;
import android.webkit.JavascriptInterface;
import android.webkit.WebResourceRequest;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Pattern;

public final class MainActivity extends Activity {
    private WebView webView;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();

    @Override
    @SuppressLint("SetJavaScriptEnabled")
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.TRANSPARENT);
        getWindow().setNavigationBarColor(Color.rgb(7, 17, 15));
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);

        webView = new WebView(this);
        webView.setBackgroundColor(Color.rgb(7, 17, 15));
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(false);
        settings.setAllowFileAccessFromFileURLs(false);
        settings.setAllowUniversalAccessFromFileURLs(false);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                Uri uri = request.getUrl();
                return !("file".equals(uri.getScheme()) && "/android_asset/index.html".equals(uri.getPath()));
            }
        });
        webView.setWebChromeClient(new WebChromeClient());
        webView.addJavascriptInterface(new RootBridge(), "OxideNative");
        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    @Override
    protected void onDestroy() {
        webView.removeJavascriptInterface("OxideNative");
        webView.destroy();
        executor.shutdownNow();
        super.onDestroy();
    }

    public final class RootBridge {
        private static final String CONTROLLER =
                "/data/adb/modules/" + BuildConfig.MODULE_ID + "/scripts/oxidebotctl";
        private final Pattern allowed = Pattern.compile(
                "^" + Pattern.quote(CONTROLLER)
                        + " (?:status --properties|start|stop|restart|enable|disable|logs [0-9]{1,4}|clear-logs|config-export|config-import [A-Za-z0-9+/=]{1,65536})$");

        @JavascriptInterface
        public void exec(String command, String callback) {
            if (command == null || callback == null || !allowed.matcher(command).matches()
                    || !callback.matches("[A-Za-z_$][A-Za-z0-9_$]{0,100}")) {
                sendResult(callback, 126, "", "命令被安全策略拒绝");
                return;
            }
            executor.execute(() -> runRootCommand(command, callback));
        }

        private void runRootCommand(String command, String callback) {
            int errno = 1;
            StringBuilder output = new StringBuilder();
            try {
                Process process = new ProcessBuilder("su", "-c", command)
                        .redirectErrorStream(true)
                        .start();
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                        process.getInputStream(), StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        if (output.length() < 1_048_576) output.append(line).append('\n');
                    }
                }
                errno = process.waitFor();
            } catch (Exception exception) {
                output.append("Root 命令执行失败：").append(exception.getMessage());
            }
            String text = output.toString();
            sendResult(callback, errno, errno == 0 ? text : "", errno == 0 ? "" : text);
        }

        private void sendResult(String callback, int errno, String stdout, String stderr) {
            if (callback == null || !callback.matches("[A-Za-z_$][A-Za-z0-9_$]{0,100}")) return;
            String script = "if(typeof window[" + JSONObject.quote(callback) + "]==='function'){window["
                    + JSONObject.quote(callback) + "](" + errno + ","
                    + JSONObject.quote(stdout) + "," + JSONObject.quote(stderr) + ");}";
            runOnUiThread(() -> webView.evaluateJavascript(script, null));
        }
    }
}
