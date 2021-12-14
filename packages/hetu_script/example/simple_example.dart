import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
    struct Person {
      var _name
      get name => this._name
      set name(newName) => this._name = newName
      
    }
    fun main {
      Person.name = 'jimmy'
      print(Person.name)
    }
    ''', invokeFunc: 'main');
}
