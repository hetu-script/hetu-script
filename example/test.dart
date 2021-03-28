import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class A {
        fun foo() {
          print('foo')
        }
        
        fun bar() {
              foo()
              print(foo)
        }
        
      }
      
      fun main() {
        var a = A()
        a.bar()
      }
    ''', invokeFunc: 'main');
}
