import 'package:hetu_script/hetu_script.dart';

void main() {
  final hetu = Hetu();

  hetu.init();

  hetu.eval(r'''
type VoidCallback = () -> void

abstract class ChangeNotifier {
  var _listeners: List<VoidCallback> = []

  function addListener(listener: VoidCallback) {
    _listeners.add(listener);
  }

  function removeListener(listener: VoidCallback) {
    _listeners.remove(listener);
  }

  function notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

class Listenable extends ChangeNotifier {
  var _name = 'Jeff'
  
  get name -> str {
    return _name
  }
  
  set name(new_name: str) {
    //This is a workaround to double set calls
    //if (_name != new_name) {
      _name = new_name
      print('new name: ${new_name}')
      notifyListeners()
    //}
  }
}

function main() {
  var l = Listenable()
  print(l.name)
  
  l.addListener(() {
    print(l.name)
  })
  
  l.name = 'Jerry'
  
  l.name = 'Bob'
}

main()
''');
}
