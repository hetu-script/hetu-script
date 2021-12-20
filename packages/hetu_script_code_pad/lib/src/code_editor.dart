import 'package:flutter/material.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

import 'hetu_mode.dart';

class CodeEditor extends StatefulWidget {
  const CodeEditor({required this.interpreter, Key? key}) : super(key: key);

  final Hetu interpreter;

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  Hetu get interpreter => widget.interpreter;

  final _toolbarHeight = 60.0;
  final _resultPanelWidth = 300.0;

  String? _result;

  final _codeController = CodeController(
    language: dart,
    // language: hetuscript,
    theme: monokaiSublimeTheme,
  );
  final _textFieldFocusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _textFieldFocusNode.dispose();
    _codeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _textFieldFocusNode.requestFocus();
    return LayoutBuilder(
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
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          try {
                            _result = interpreter.eval(_codeController.text);
                          } catch (e) {
                            _result = e.toString();
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
                  width: constraints.maxWidth - _resultPanelWidth,
                  height: constraints.maxHeight - _toolbarHeight,
                  color: const Color(0xff23241f),
                  child: SingleChildScrollView(
                    controller: ScrollController(),
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
              left: constraints.maxWidth - _resultPanelWidth,
              top: _toolbarHeight,
              height: constraints.maxHeight - _toolbarHeight,
              width: _resultPanelWidth,
              child: Container(
                padding: const EdgeInsets.all(10.0),
                color: Colors.blueGrey,
                // color: const Color(0xff23241f),
                child: Text(_result ?? ''),
              ),
            ),
          ],
        );
      },
    );
  }
}
