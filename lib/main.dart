import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_linux_webview/flutter_linux_webview.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

enum GfDashboard {
  all,
  voltage,
  temp,
  humidity;

  final String allDarkUrl = 'http://localhost:3000/d/blLmWjtVz/demo-dashboard?orgId=1&from=1719330207347&to=1719351807347&theme=dark&kiosk=true';
  final String voltageDarkUrl =
      "http://localhost:3000/d/blLmWjtVz/demo-dashboard?orgId=1&from=1719324049660&to=1719345649660&theme=dark&viewPanel=6&kiosk=true";
  final String tempDarkUrl =
      "http://localhost:3000/d/blLmWjtVz/demo-dashboard?orgId=1&from=1719324145243&to=1719345745243&theme=dark&viewPanel=4&kiosk=true";
  final String humidityDarkUrl =
      "http://localhost:3000/d/blLmWjtVz/demo-dashboard?orgId=1&from=1719324173601&to=1719345773601&theme=dark&viewPanel=2&kiosk=true";

  String getUrl() {
    switch (this) {
      case GfDashboard.voltage:
        return voltageDarkUrl;
      case GfDashboard.temp:
        return tempDarkUrl;
      case GfDashboard.humidity:
        return humidityDarkUrl;
      case GfDashboard.all:
        return allDarkUrl;
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux) {
    WebViewCookieManagerPlatform.instance = WebViewLinuxCookieManager();
    WebView.platform = LinuxWebView();
    LinuxWebViewPlugin.initialize();
    // Logger.root.level = Level.ALL;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grafana Linux WebView Prototype',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

bool _darkMode = true;

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final Map<GfDashboard, WebViewController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await LinuxWebViewPlugin.terminate();
    return AppExitResponse.exit;
  }

  void onButtonTapped(bool isLeft) {
    if (isLeft != _darkMode) {
      setState(() {
        _darkMode = isLeft;
      });
      for (int i = 0; i < GfDashboard.values.length; i++) {
        if (_controllers.containsKey(GfDashboard.values[i])) {
          GfDashboard tmp = GfDashboard.values[i];
          _controllers[tmp]?.loadUrl(setModeInUrl(tmp.getUrl()));
        }
      }
    }
  }

  String setModeInUrl(String url) {
    if (!_darkMode) {
      url = url.replaceAll('&theme=dark', '&theme=light');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkMode ? Colors.black : Colors.white,
      body: LayoutBuilder(builder: (context, windowConstraints) {
        return ConstrainedBox(
          constraints: windowConstraints,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                //Dark/light mode selector
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ButtonSwitch(
                        leftText: 'DARK',
                        rightText: 'LIGHT',
                        leftSelected: _darkMode,
                        onTap: (isLeft) => onButtonTapped(isLeft),
                        selectedColor: _darkMode ? Colors.black : Colors.white,
                        unselectedColor: _darkMode
                            ? const Color(0xFF4F4C4D)
                            : const Color(0xFFD1D1D1),
                        borderColor: Colors.grey,
                        textColor: _darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              //Shows all dashboards in a single webview, doesn't size great
              // Expanded(
              //   child: GrafanaWebView(
              //     toShow: GfDashboard.all,
              //     onCreate: (c, db) {
              //       _controllers[db] = c;
              //     },
              //   ),
              // ),
              // Container(
              //   height: 8,
              // ),

              Expanded(
                child: GrafanaWebView(
                  toShow: GfDashboard.voltage,
                  onCreate: (c, db) {
                    _controllers[db] = c;
                  },
                ),
              ),
              Container(
                height: 8,
              ),
              Expanded(
                child: GrafanaWebView(
                  toShow: GfDashboard.temp,
                  onCreate: (c, db) {
                    _controllers[db] = c;
                  },
                ),
              ),
              Container(
                height: 8,
              ),
              Expanded(
                child: GrafanaWebView(
                  toShow: GfDashboard.humidity,
                  onCreate: (c, db) {
                    _controllers[db] = c;
                  },
                ),
              ),
              Container(
                height: 8,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ButtonSwitch extends StatefulWidget {
  static const double _borderRadius = 6;
  static const double _borderWidth = 2;

  final String leftText;
  final String rightText;
  final bool leftSelected;
  final Function(bool) onTap; // true = leftTapped
  final Color unselectedColor;
  final Color selectedColor;
  final Color borderColor;
  final Color textColor;

  const ButtonSwitch({
    super.key,
    required this.leftText,
    required this.rightText,
    required this.leftSelected,
    required this.onTap,
    required this.unselectedColor,
    required this.selectedColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  State<ButtonSwitch> createState() => _ButtonSwitchState();
}

class _ButtonSwitchState extends State<ButtonSwitch> {
  Widget _buildText(String txt) {
    return Text(
      txt,
      style: TextStyle(
        fontSize: 18,
        color: widget.textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 60,
        minHeight: 25,
      ),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                width: ButtonSwitch._borderWidth, color: widget.borderColor),
            borderRadius: BorderRadius.circular(ButtonSwitch._borderRadius)),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTap(true),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(ButtonSwitch._borderRadius),
                      bottomLeft: Radius.circular(ButtonSwitch._borderRadius),
                    ),
                    color: widget.leftSelected
                        ? widget.selectedColor
                        : widget.unselectedColor,
                  ),
                  child: Center(
                    child: _buildText(
                      widget.leftText,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              //Middle divider
              width: ButtonSwitch._borderWidth,
              color: widget.borderColor,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTap(false),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(ButtonSwitch._borderRadius),
                      bottomRight: Radius.circular(ButtonSwitch._borderRadius),
                    ),
                    color: !widget.leftSelected
                        ? widget.selectedColor
                        : widget.unselectedColor,
                  ),
                  child: Center(
                    child: _buildText(
                      widget.rightText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GrafanaWebView extends StatelessWidget {
  GrafanaWebView({super.key, required this.onCreate, required this.toShow});

  final GfDashboard toShow;
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  final Function(WebViewController, GfDashboard) onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
      ),
      child: WebView(
        initialUrl: toShow.getUrl(),
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
          onCreate(webViewController, toShow);
        },
      ),
    );
  }
}
