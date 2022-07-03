import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:flutter/material.dart';
import 'package:currency_picker/currency_picker.dart';

void main() {
  runApp(const MyApp());

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    doWhenWindowReady(() {
      const initialSize = Size(600, 450);
      appWindow.minSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick Currency Calculator',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'app',
      theme: ThemeData(
        primaryColor: Colors.red[800],
      ),
      home: const MyHomePage(title: 'Quick Currency Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  /// exchange rate from API
  double _exchangeRate = 0;

  /// Amount of the from currency
  double _amount = 0;

  /// resualt of the calcualtion
  double _resault = 0;

  /// The code of the currency which the app will convert to
  String toCode = 'EGP';

  /// The code of the currency which the app will convert from
  String fromCode = 'USD';

  /// get The rate from google finance
  Future getDataFromWebsite() async {
    final url =
        Uri.parse('https://www.google.com/finance/quote/$fromCode-$toCode');
    final response = await http.get(url);
    final html = dom.Document.html(response.body);
    final rate = html
        .querySelectorAll(
            'div > div > div > div > div > div > span > div > div')
        .map((e) => e.innerHtml.trim())
        .toList();
    ;

    setState(() {
      _exchangeRate = rate.isNotEmpty ? double.tryParse(rate.first)! : 0.0;
    });
  }

  /// Calculates the exchange for the entered amount
  void calculateExchange() {
    setState(() {
      _resault = _amount * _exchangeRate;
    });
  }

  @override
  void initState() {
    getDataFromWebsite();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var mediaQuery = MediaQuery.of(context);
    return GestureDetector(
      onPanUpdate: (details) {
        if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
          setState(() {
            appWindow.position = appWindow.position
                .translate(details.localPosition.dx, details.localPosition.dy);
          });
        }
      },
      onTap: () {
        if (Platform.isAndroid || Platform.isIOS) {
          FocusScope.of(context).unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: theme.primaryColor,
          actions: (Platform.isLinux || Platform.isMacOS || Platform.isWindows)
              ? [
                  IconButton(
                    onPressed: () {
                      appWindow.minimize();
                    },
                    hoverColor: Colors.green,
                    splashRadius: 16,
                    icon: const Icon(
                      Icons.minimize,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      appWindow.isMaximized
                          ? appWindow.restore()
                          : appWindow.maximize();
                    },
                    hoverColor: Colors.orange,
                    splashRadius: 16,
                    icon: Icon(
                      appWindow.isMaximized
                          ? Icons.margin_outlined
                          : Icons.desktop_windows_rounded,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      appWindow.close();
                    },
                    splashRadius: 16,
                    hoverColor: Colors.red,
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ]
              : [],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 0.8),
                    child: Text(
                      '1 $fromCode = ${_exchangeRate.toStringAsFixed(3)} $toCode',
                      style: theme.textTheme.headline6,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: SizedBox(
                      width: Platform.isAndroid || Platform.isIOS
                          ? mediaQuery.size.width
                          : mediaQuery.size.width * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Exchange from:',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                fromCode,
                                style: theme.textTheme.bodyText1,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                showCurrencyPicker(
                                  context: context,
                                  showFlag: true,
                                  showCurrencyName: true,
                                  showCurrencyCode: true,
                                  favorite: ['EGP', 'USD', 'EUR', 'SAR'],
                                  onSelect: (Currency currency) {
                                    setState(() {
                                      fromCode = currency.code;
                                    });
                                    getDataFromWebsite()
                                        .then((value) => calculateExchange());
                                  },
                                );
                              },
                              child: Container(
                                width: mediaQuery.size.width * 0.1,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 5, color: Colors.black12),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Text(
                                  'Change',
                                  style: theme.textTheme.button!.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: SizedBox(
                      width: Platform.isAndroid || Platform.isIOS
                          ? mediaQuery.size.width
                          : mediaQuery.size.width * 0.6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Exchange To:',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                toCode,
                                style: theme.textTheme.bodyText1,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () {
                                showCurrencyPicker(
                                  context: context,
                                  showFlag: true,
                                  showCurrencyName: true,
                                  showCurrencyCode: true,
                                  favorite: ['EGP', 'USD', 'EUR', 'SAR'],
                                  onSelect: (Currency currency) {
                                    setState(() {
                                      toCode = currency.code;
                                    });
                                    getDataFromWebsite()
                                        .then((value) => calculateExchange());
                                  },
                                );
                              },
                              child: Container(
                                width: mediaQuery.size.width * 0.1,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                        blurRadius: 5, color: Colors.black12),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                child: Text(
                                  'Change',
                                  style: theme.textTheme.button!.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Platform.isAndroid || Platform.isIOS
                        ? mediaQuery.size.width
                        : mediaQuery.size.width * 0.6,
                    child: CupertinoTextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        FilteringTextInputFormatter.deny(RegExp('[a-zA-Z]')),
                      ],
                      textAlign: TextAlign.center,
                      placeholder: 'Amount',
                      placeholderStyle: theme.textTheme.bodyLarge,
                      style: theme.textTheme.bodyText1,
                      cursorColor: theme.primaryColor,
                      prefix: IconButton(
                        onPressed: () {
                          calculateExchange();
                        },
                        icon: const Icon(
                          Icons.currency_exchange_outlined,
                        ),
                      ),
                      suffix: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Text(
                          fromCode,
                          style: theme.textTheme.headline6,
                        ),
                      ),
                      suffixMode: OverlayVisibilityMode.editing,
                      onEditingComplete: () {
                        calculateExchange();
                      },
                      onChanged: (value) {
                        setState(() {
                          _amount = double.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  if (_resault != 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                      child: FadeIn(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeIn,
                        child: SizedBox(
                          width: Platform.isAndroid || Platform.isIOS
                              ? mediaQuery.size.width
                              : mediaQuery.size.width * 0.6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                'Resault:',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                _resault.toStringAsFixed(2).toString(),
                                style: theme.textTheme.headline6,
                              ),
                              Text(
                                toCode,
                                style: theme.textTheme.headline6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
