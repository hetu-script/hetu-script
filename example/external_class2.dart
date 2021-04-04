import 'package:hetu_script/hetu_script.dart';

class GlobalState {
  static final GlobalState _singleton = GlobalState._internal();

  factory GlobalState() {
    return _singleton;
  }

  GlobalState._internal();

  static final state = {'meaning': 'nil'};
}

extension GlobalStateBinding on GlobalState {
  dynamic htFetch(String varName) {
    switch (varName) {
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
      case 'GlobalState.state':
        return GlobalState.state;
      default:
        throw HTErrorUndefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as GlobalState;
    return i.htFetch(varName);
  }
}

void main() async {
  var hetu = Hetu();
  await hetu.init(externalClasses: [GlobalStateClassBinding()]);
  await hetu.eval('''
      external class GlobalState {
        static const state
      }
      class Tags {
        static const meaning = 'meaning'
      }
      fun main {
        GlobalState.state[Tags.meaning] = 'nada'
        print(GlobalState.state)
      }
      ''', invokeFunc: 'main');
}
