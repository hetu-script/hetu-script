import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
    fun main {
      var funcTypedef: type = fun(str) -> num
      var numparse: funcTypedef = fun(value: str) -> num { return num.parse(value) }
      var getType = fun { return numparse.runtimeType }
      var funcTypedef2 = getType()
      var strlength: funcTypedef2 = fun(value: str) -> num { return value.length }
      print(strlength('hello world'))
    }
      ''', invokeFunc: 'main');
}
