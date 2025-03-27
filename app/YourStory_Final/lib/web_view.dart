import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewPage extends StatefulWidget {
  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Learn More About Us"),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri("https://mellifluous-kelpie-914287.netlify.app/"), // Use WebUri here
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {
          print("Started loading: $url");
        },
        onLoadStop: (controller, url) async {
          print("Finished loading: $url");
        },
        onProgressChanged: (controller, progress) {
          print("Progress: $progress%");
        },
      ),
    );
  }
}
