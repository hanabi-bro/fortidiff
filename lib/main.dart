import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:convert';
import 'package:desktop_window/desktop_window.dart';
import 'package:logger/logger.dart';
import 'package:flutter/rendering.dart';

var logger = Logger(
  printer: PrettyPrinter(),
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forti Diff',
      theme: ThemeData.dark(),
      home: const MyHomePage(title: 'Forti Diff'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
  var common = Common();
  var filepathCtrl1 = TextEditingController();
  var filepathCtrl2 = TextEditingController();
  var outputCtr = TextEditingController();

  var tmpMaskedFile1 = '';
  var tmpMaskedFile2 = '';

  bool diffButtonDisable = true;
  bool file1SelectDisable = false;
  bool file2SelectDisable = false;

  Map<String, String> errMessage = {
    'file1': '',
    'file2': '',
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(children: [
          Text(AppLocalizations.of(context)!.topMessage),
          Row(
            children: [
              Text(AppLocalizations.of(context)!.file1),
              Flexible(
                  child: TextField(
                controller: filepathCtrl1,
              )),
              LazyFutureBuilder(
                futureBuilder: () async {
                  String? filePath = await common.getPathFromDialog();
                  if (filePath != null && filePath != "") {
                    setState(() => filepathCtrl1.text = filePath);
                    Map check_configs = await common.getConfig(filePath);
                    if (check_configs['message'].length > 0) {
                      errMessage['file1'] =
                          "File1: ${check_configs['message']}";
                      setState(() => outputCtr.text =
                          "${errMessage['file1']}\n${errMessage['file2']}");
                    } else {
                      errMessage['file1'] = "";
                      setState(() => outputCtr.text =
                          "${errMessage['file1']}\n${errMessage['file2']}");
                      tmpMaskedFile2 =
                          await common.genTempFile(check_configs['configs']);
                      // file1 and file2 ok
                      if (tmpMaskedFile1 != "" &&
                          tmpMaskedFile2 != "" &&
                          errMessage['file1'] == "" &&
                          errMessage['file2'] == "") {
                        setState(() {
                          diffButtonDisable = false;
                        });
                      } else {
                        setState(() {
                          diffButtonDisable = true;
                        });
                      }
                    }
                  }
                },
                builder: (context, futureBuilder, isFutureBuilding) =>
                    ElevatedButton(
                  onPressed: futureBuilder,
                  child: Text('browse'),
                ),
              ),
                },
                builder: (context, futureBuilder, isFutureBuilding) =>
                    ElevatedButton(
                  onPressed: futureBuilder,
                  child: Text('browse'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(AppLocalizations.of(context)!.file2),
              Flexible(
                  child: TextField(
                controller: filepathCtrl2,
              )),
              LazyFutureBuilder(
                futureBuilder: () async {
                  String? filePath = await common.getPathFromDialog();
                  if (filePath != null && filePath != "") {
                    setState(() => filepathCtrl2.text = filePath);
                    Map check_configs = await common.getConfig(filePath);
                    if (check_configs['message'].length > 0) {
                      errMessage['file2'] =
                          "File2: ${check_configs['message']}";
                      setState(() => outputCtr.text =
                          "${errMessage['file1']}\n${errMessage['file2']}");
                    } else {
                      errMessage['file2'] = "";
                      setState(() => outputCtr.text =
                          "${errMessage['file1']}\n${errMessage['file2']}");
                      tmpMaskedFile1 =
                          await common.genTempFile(check_configs['configs']);
                      // file1 and file2 ok
                      if (tmpMaskedFile1 != "" &&
                          tmpMaskedFile2 != "" &&
                          errMessage['file1'] == "" &&
                          errMessage['file2'] == "") {
                        setState(() {
                          diffButtonDisable = false;
                        });
                      } else {
                        setState(() {
                          diffButtonDisable = true;
                        });
                      }
                    }
                  }
                },
                builder: (context, futureBuilder, isFutureBuilding) =>
                    ElevatedButton(
                  onPressed: futureBuilder,
                  child: Text('browse'),
                ),
              ),
                },
                builder: (context, futureBuilder, isFutureBuilding) =>
                    ElevatedButton(
                  onPressed: futureBuilder,
                  child: Text('browse'),
                ),
              ),
            ],
          ),
          Row(children: [
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.diff),
              onPressed: diffButtonDisable
                  ? null
                  : () async {
                      common.winmerge(tmpMaskedFile1, tmpMaskedFile2);
                    },
            ),
          ]),
          Row(children: [
            Flexible(
                child: TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              minLines: 3,
              readOnly: true,
              showCursor: true,
              controller: outputCtr,
              style: TextStyle(color: Colors.red),
            )),
          ]),
        ]),
      ),
    );
  }
}

class Common {
  Future<String?> getPathFromDialog() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // withData: true,
    );

    PlatformFile file;
    String? filePath = '';

    if (result != null) {
      file = result.files.single;
      filePath = file.path;
      // filePath = utf8.decode(file.bytes!);
    }

    return filePath;
  }

  Future<Map> getConfig(filePath) async {
    File file = File(filePath);
    Map result = {'message': "", 'configs': []};

    try {
      result['configs'] = await file.readAsLines();
    } on FileSystemException catch (e, stacktrace) {
      RegExp notUtf8 = RegExp(r"Failed to decode data using encoding 'utf-8'");
      if (e.message.contains(notUtf8)) {
        result['message'] = 'File is not utf-8[$filePath]';
      } else {
        result['message'] = e.message;
      }
    } on Exception catch (e, stacktrace) {
      result['message'] = stacktrace;
    }

    return result;
  }

  Future<String> genTempFile(List configs) async {
    List<String> tmpConfigs = [];
    bool private_key = false;
    bool cert = false;
    configs.forEach((line) {
      String? maskedLine = line;

      // config file version
      RegExp reg = RegExp(r'(#conf_file_ver=)(.*)$');
      var match = reg.firstMatch(line);
      if (match != null) {
        maskedLine = '${match.group(1)}***************';
      }

      // Encripted words
      reg = RegExp(
          r'(\s+(set password[\d]? ENC|set passwd[\d]? ENC|set wifi-passphrase ENC|set .*key ENC|set public-key|set md5-key|set psksecret ENC)\s)(.*)$');
      match = reg.firstMatch(line);
      if (match != null) {
        maskedLine = '${match.group(1)}************************';
      }

      // uuid
      reg = RegExp(r'(\s+(set uuid)\s)(.*)$');
      match = reg.firstMatch(line);
      if (match != null) {
        maskedLine = '${match.group(1)}********-****-****-****-************';
      }

      // snmp-index
      reg = RegExp(r'(\s+(set snmp-index)\s)(.*)$');
      match = reg.firstMatch(line);
      if (match != null) {
        maskedLine = '${match.group(1)}*';
      }

      // Skip Private Key
      if (private_key) {
        maskedLine = null;
        reg = RegExp(r'"');
        match = reg.firstMatch(line);
        if (match != null) {
          private_key = false;
        }
        // Skip Cert Key
      } else if (cert) {
        maskedLine = null;
        reg = RegExp(r'"');
        match = reg.firstMatch(line);
        if (match != null) {
          cert = false;
        }
      }

      // check private-key
      reg = RegExp(r'(\s+(set private-key)\s)(.*)$');
      match = reg.firstMatch(line);
      if (match != null) {
        maskedLine = '${match.group(1)} "*********"';
        private_key = true;
      }
      // check cert
      reg = RegExp(r'(\s+(set certificate)\s)(.*)$');
      match = reg.firstMatch(line);
      if (match != null) {
        maskedLine = '${match.group(1)} "*********"';
        cert = true;
      }

      // add masked config
      if (maskedLine != null) {
        tmpConfigs.add(maskedLine);
      }
    });

    var tmpDir = await Directory.systemTemp.createTemp();

    // 一時ファイ作成
    int smallStart = 97;
    int smallcount = 26;

    var words = [];
    for (var i = 0; i < 10; i++) {
      int num = Random().nextInt(smallcount);
      int randNum = num + smallStart;
      words.add(String.fromCharCode(randNum));
    }
    String tmpFileName = words.join('');
    String tmpFilePath;
    tmpFilePath = '${tmpDir.path}\\${tmpFileName}';
    // print(tmpDir);
    // print(tmpFileName);
    var tmpFile = File(tmpFilePath);
    // 一時ファイルに書き込み
    // コンフィグ文字列に
    String configStr = tmpConfigs.join('\n');
    tmpFile.writeAsString(configStr);

    return tmpFile.path;
  }

  void winmerge(file1, file2) async {
    String diffCmd = 'WinMergeU.exe';
    List<String> diffOpts = [
      file1,
      file2,
      '-wl',
      '-wr',
      '-u',
      '-e',
      '-cp',
      '65001',
      '-noprefs',
      '-ignorews',
      '-ignoreblanklines',
      '-ignoreeol',
      '-ignorecodepage',
    ];
    var result = await Process.run(diffCmd, diffOpts);
  }
}

class LazyFutureBuilder extends StatefulWidget {
  final Future Function() futureBuilder;
  final Widget Function(BuildContext context, Future Function() futureBuilder,
      bool isFutureBuilding) builder;

  const LazyFutureBuilder({
    required this.futureBuilder,
    required this.builder,
  });

  @override
  State<StatefulWidget> createState() => _State();
}

class _State extends State<LazyFutureBuilder> {
  var _isFutureBuilding = false;

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      () async {
        if (_isFutureBuilding) {
          return;
        }
        setState(() {
          _isFutureBuilding = true;
        });
        try {
          await widget.futureBuilder();
        } finally {
          setState(() {
            _isFutureBuilding = false;
          });
        }
      },
      _isFutureBuilding,
    );
  }
}
