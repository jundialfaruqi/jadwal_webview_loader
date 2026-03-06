import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final VoidCallback? onChangeUrl;
  const WebViewPage({super.key, required this.url, this.onChangeUrl});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(desktopChromeUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            Future.delayed(
                const Duration(milliseconds: 300), () => _applySystemFonts());
            Future.delayed(const Duration(milliseconds: 600),
                () => _applyPrayerTimeFont());
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _changeUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyLastSavedUrl, widget.url);
    await prefs.remove(prefKeySavedUrl);
    widget.onChangeUrl?.call();
  }

  Future<void> _applyPrayerTimeFont() async {
    const js = """
      (function() {
        try {
          var id = 'prayer-time-font-style';
          if (document.getElementById(id)) return;
          var style = document.createElement('style');
          style.id = id;
          style.textContent = ".prayer-time-value { font-family: 'JetBrains Mono', 'Roboto Mono', 'Courier New', monospace !important; font-style: normal; }";
          (document.head || document.documentElement).appendChild(style);
        } catch (e) {
          console.log('PRAYER_FONT error', e);
        }
      })();
    """;
    await _controller.runJavaScript(js);
  }

  Future<void> _applySystemFonts() async {
    const js = """
      (function() {
        try {
          var id = 'system-fonts-style';
          if (document.getElementById(id)) return;
          var style = document.createElement('style');
          style.id = id;
          style.textContent = "html, body, input, textarea, button, select, code, pre, kbd, samp, .prayer-time-value { font-family: 'Poppins', system-ui, -apple-system, 'Segoe UI', Roboto, Arial, sans-serif !important; font-style: normal; }";
          (document.head || document.documentElement).appendChild(style);
        } catch (e) {
          console.log('SYSTEM_FONTS error', e);
        }
      })();
    """;
    await _controller.runJavaScript(js);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Sholat'),
        actions: [
          TextButton(
            onPressed: _changeUrl,
            child: const Text('Ubah URL'),
          )
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
