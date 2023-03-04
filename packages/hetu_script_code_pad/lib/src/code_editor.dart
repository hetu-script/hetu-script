import 'package:flutter/material.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';
import 'package:code_text_field/code_text_field.dart';
// import 'package:flutter_highlight/themes/monokai-sublime.dart';
// import 'package:highlight/languages/dart.dart';

import 'hetu_mode.dart';

const _kMiddleDot = '·';

class CodeEditor extends StatefulWidget {
  static const _helloWorld =
      r'''print(range(10).map((value) => 'hello, ${value}'))''';

  const CodeEditor({this.initialValue = _helloWorld, super.key});

  final String initialValue;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final Hetu hetu;

  final _toolbarHeight = 60.0;
  final _outputPanelHeight = 300.0;
  final _resultPanelWidth = 300.0;

  String _result = '';
  final _resultScrollController = ScrollController();

  String _errors = '';
  final _errorsScrollController = ScrollController();

  void _log(String message) {
    if (_result.isEmpty) {
      _result = message;
    } else {
      _result += '\n$message';
    }
    _resultScrollController
        .jumpTo(_resultScrollController.position.maxScrollExtent);
  }

  void _error(String message) {
    if (_errors.isEmpty) {
      _errors = message;
    } else {
      _errors += '\n$message';
    }
    _errorsScrollController
        .jumpTo(_resultScrollController.position.maxScrollExtent);
  }

  final CodeController _codeController = CodeController(language: hetuscript);

  final _textFieldFocusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _textFieldFocusNode.dispose();
    _codeController.dispose();
  }

  @override
  void initState() {
    super.initState();
    hetu = Hetu();
    hetu.initFlutter();

    hetu.interpreter.bindExternalFunction('_print', (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        List<HTType> typeArgs = const []}) {
      var result = positionalArgs.join('\n');

      /// On web, replace spaces with invisible dots “·” to fix the current issue with spaces
      ///
      /// https://github.com/flutter/flutter/issues/77929
      result = result.replaceAll(_kMiddleDot, ' ');
      _log(result);
    }, override: true);

    _codeController.text = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    _textFieldFocusNode.requestFocus();
    return Container(
      color: Colors.black26,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Stack(
            children: <Widget>[
              Positioned(
                height: _toolbarHeight,
                width: constraints.maxWidth,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: <Widget>[
                      const Text(
                        'Hetu Script Online REPL',
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.green,
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, // background
                            foregroundColor: Colors.blue, // foreground
                          ),
                          onPressed: () {
                            setState(() {
                              _result = '';
                              _errors = '';
                              _codeController.text = '';
                            });
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _errors = '';
                            try {
                              final result = hetu.eval(_codeController.text,
                                  type: HTResourceType.hetuScript);
                              _log(result.toString());
                            } catch (e) {
                              _error(e.toString());
                            }
                          });
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text(
                          'RUN',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: _toolbarHeight,
                child: GestureDetector(
                  onTap: () {
                    _textFieldFocusNode.requestFocus();
                  },
                  child: Container(
                    width: constraints.maxWidth - _resultPanelWidth - 2,
                    height: constraints.maxHeight - _toolbarHeight,
                    color: const Color(0xff23241f),
                    child: SingleChildScrollView(
                      child: CodeField(
                        controller: _codeController,
                        textStyle: const TextStyle(fontFamily: 'UbuntuMono'),
                        focusNode: _textFieldFocusNode,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: constraints.maxWidth - _resultPanelWidth + 2,
                top: _toolbarHeight,
                child: Container(
                  height: _outputPanelHeight,
                  width: _resultPanelWidth - 2,
                  padding: const EdgeInsets.all(10.0),
                  color: const Color(0xff23241f),
                  child: SingleChildScrollView(
                    controller: _resultScrollController,
                    child: Text(
                      _result,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'UbuntuMono',
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: constraints.maxWidth - _resultPanelWidth + 2,
                top: _toolbarHeight + _outputPanelHeight + 2,
                child: Container(
                  height: constraints.maxHeight -
                      _toolbarHeight -
                      _outputPanelHeight -
                      2,
                  width: _resultPanelWidth - 2,
                  padding: const EdgeInsets.all(10.0),
                  color: const Color(0xff23241f),
                  child: SingleChildScrollView(
                    controller: _errorsScrollController,
                    child: Text(
                      _errors,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'UbuntuMono',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
