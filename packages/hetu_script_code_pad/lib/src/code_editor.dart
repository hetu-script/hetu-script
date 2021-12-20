import 'package:flutter/material.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
// import 'package:highlight/languages/dart.dart';

import 'hetu_mode.dart';

class CodeEditor extends StatefulWidget {
  static const _helloWorld = "print('Hello, world!')";

  const CodeEditor(
      {required this.interpreter, this.initialValue = _helloWorld, Key? key})
      : super(key: key);

  final Hetu interpreter;

  final String initialValue;

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  Hetu get interpreter => widget.interpreter;

  final _toolbarHeight = 60.0;
  final _outputPanelHeight = 300.0;
  final _resultPanelWidth = 300.0;

  String _result = '';

  String _errors = '';

  void _log(String message) {
    if (_result.isEmpty) {
      _result = message;
    } else {
      _result += '/n$message';
    }
  }

  void _error(String message) {
    if (_errors.isEmpty) {
      _errors = message;
    } else {
      _errors += '/n$message';
    }
  }

  late final CodeController _codeController;

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
    interpreter.bindExternalFunction('print', (HTEntity entity,
        {List<dynamic> positionalArgs = const [],
        Map<String, dynamic> namedArgs = const {},
        List<HTType> typeArgs = const []}) {
      setState(() {
        List args = positionalArgs.first;
        final result = args.join(' ');
        _log(result);
      });
    }, override: true);

    _codeController = CodeController(
      text: widget.initialValue,
      language: hetuscript,
      theme: monokaiSublimeTheme,
    );
  }

  @override
  Widget build(BuildContext context) {
    _textFieldFocusNode.requestFocus();
    return Container(
      color: const Color.fromARGB(255, 89, 96, 102),
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
                        'Hetu Script',
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
                            primary: Colors.white, // background
                            onPrimary: Colors.blue, // foreground
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
                          _result = '';
                          setState(() {
                            try {
                              interpreter.eval(_codeController.text);
                            } catch (e) {
                              final message = e.toString();
                              _error(message);
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
