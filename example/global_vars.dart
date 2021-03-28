import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r''' 
  var globalVar
  class A {
    construct() {
      globalVar = 1
    }
    fun test() {
      print(globalVar)
    }
    
    static fun staticTest() {
      print(globalVar)
    }
    
  }

  fun main() {
    var a = A()
    a.test()    
    a.staticTest()
  }
  ''', style: ParseStyle.module, invokeFunc: 'main');
}
