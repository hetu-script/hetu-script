import 'package:hetu_script/hetu_script.dart';

class GlobalState {
  static final GlobalState _singleton = GlobalState._internal();

  factory GlobalState() {
    return _singleton;
  }

  GlobalState._internal();

  String state = 'nil';
}

extension GlobalStateBinding on GlobalState {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'state':
        return state;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

class GlobalStateClassBinding extends HTExternalClass {
  GlobalStateClassBinding() : super('GlobalState');

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'GlobalState':
        return () => GlobalState();
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String varName) {
    var i = instance as GlobalState;
    return i.htFetch(varName);
  }
}

class App {
  static final globalState = GlobalState();
}

class AppClassBinding extends HTExternalClass {
  AppClassBinding() : super('App');

  @override
  dynamic memberGet(String varName, {String from = HTLexicon.global}) {
    switch (varName) {
      case 'App.globalState':
        return App.globalState;
      default:
        throw HTErrorUndefined(varName);
    }
  }
}

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [AppClassBinding(), GlobalStateClassBinding()]);
  await hetu.eval('''
      external class GlobalState {
        static const state
      }
      external class App {
        static const globalState
      }
      fun main {
        print(App.globalState.state)
      }
      ''', invokeFunc: 'main');
}
