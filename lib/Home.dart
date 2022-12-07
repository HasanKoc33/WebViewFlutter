import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  const Home({
    Key? key,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey webViewKey = GlobalKey();
  PullToRefreshController? pullToRefreshController;
  InAppWebViewController? webViewController;

  // interet kontrol
  Future<bool> connect(BuildContext context) async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print("*******************************************************");
        print('connected');
        return true;
      } else {
        return false;
      }
    } on SocketException catch (_) {
      print("*******************************************************");
      print('not connected');
      return false;
    }
  }

  Future<bool> back(BuildContext context) async {
    return await showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            content: const Text(
              "Uygulamadan çıkmak istediginize emin misiniz?",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text("İptal")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text("Çık"))
            ],
          ),
          barrierDismissible: true,
        ) ??
        false;
  }

  double progress = 0;

  @override
  void initState() {
    super.initState();

    connect(context);

    pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                webViewController?.loadUrl(
                    urlRequest:
                        URLRequest(url: await webViewController?.getUrl()));
              }
            },
          );
  }

  bool arama = false;
  var searchFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xff23D3D3),
      bottomNavigationBar: Container(
          height: 55,
          color: Colors.white,
          child: Column(
            children: [
              Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[

                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.grey,
                    ),
                    onPressed: () async {
                      bool? a = await webViewController?.canGoBack();
                      if (a!) {
                        await webViewController?.goBack();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios_sharp,
                      color: Colors.grey,
                    ),
                    onPressed: () async {
                      bool? a = await webViewController?.canGoForward();
                      if (a!) {
                        await webViewController?.goForward();
                      }
                    },
                  ),
                ],
              )),
            ],
          )),
      body: WillPopScope(
        onWillPop: () async {
          arama = false;
          setState(() {

          });
          bool? a = await webViewController?.canGoBack();
          if (a!) {
            await webViewController?.goBack();
            return false;
          } else {
            return await back(context);
          }


        },
        child: SafeArea(
          child: FutureBuilder(
            future: connect(context),
            builder: (context, snap) {
              if (snap.hasData) {
                if (snap.data!) {
                  return Stack(
                    children: [
                      GestureDetector(

                        child: InAppWebView(
                          key: webViewKey,
                          initialUrlRequest:
                              URLRequest(url: Uri.parse('https://flutter.dev')),
                          initialUserScripts:
                              UnmodifiableListView<UserScript>([]),
                          initialOptions: InAppWebViewGroupOptions(
                              crossPlatform: InAppWebViewOptions(
                            supportZoom: false,
                          )),
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated: (controller) async {
                            webViewController = controller;
                            print(await controller.getUrl());
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            var uri = navigationAction.request.url!;

                            if (![
                              "http",
                              "https",
                              "file",
                              "chrome",
                              "data",
                              "javascript",
                              "about"
                            ].contains(uri.scheme)) {
                              if (await canLaunchUrl(uri)) {
                                // Launch the App
                                await launchUrl(
                                  uri,
                                );
                                // and cancel the request
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStop: (controller, url) async {
                            pullToRefreshController?.endRefreshing();
                            setState(() {});
                          },
                          onProgressChanged: (controller, progress) {
                            if (progress == 100) {
                              pullToRefreshController?.endRefreshing();
                            }
                            setState(() {
                              this.progress = progress / 100;
                            });
                          },
                          onUpdateVisitedHistory: (controller, url, isReload) {
                            setState(() {});
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            print(consoleMessage);
                          },
                        ),
                      ),
                      progress < 1.0
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xff23D3D3)))
                          : Container(),
                      progress < 1.0
                          ? LinearProgressIndicator(value: progress)
                          : Container(),
                    ],
                  );
                } else {
                  return SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.signal_wifi_connected_no_internet_4,
                            size: 60,
                            color: Colors.red,
                          ),
                        ),
                        const Center(
                          child: Text(
                            "İnternet yok\n\nLütfen internet erişiminizi kontrol edin",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton(
                            onPressed: () {
                              setState(() {});
                            },
                            child: const Text("Tekrar Dene"))
                      ],
                    ),
                  );
                }
              } else {
                return Center(
                    child: CircularProgressIndicator(
                  color: Colors.green,
                ));
              }
            },
          ),
        ),
      ),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }
}
