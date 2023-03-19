import 'package:flutter/material.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hetu Script Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Hetu Script Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Hetu hetu;

  bool _isHetuReady = false;

  String _scriptResult = '';

  void init() async {
    const root = 'scripts/';
    final filterConfig = HTFilterConfig(root, extension: [
      HTResource.hetuModule,
      HTResource.hetuScript,
      HTResource.json,
    ]);
    final sourceContext =
        HTAssetResourceContext(root: root, includedFilter: [filterConfig]);
    hetu = Hetu(sourceContext: sourceContext);
    await hetu.initFlutter();
    _isHetuReady = true;
  }

  void _runScript() {
    if (!_isHetuReady) {
      return;
    }
    setState(() {
      _scriptResult = hetu.evalFile('main.ht', invoke: 'hello');
    });
  }

  @override
  void initState() {
    super.initState();

    init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Push the button to run a script.',
            ),
            Text(
              _scriptResult,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _runScript,
        tooltip: 'Run Script',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
