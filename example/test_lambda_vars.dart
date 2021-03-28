import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = Hetu();

  await hetu.init();

  await hetu.eval(r''' 
  class A {
    var age = 10
   
    fun m() {
      var b = B(fun(n) {
        this.age = n
      })
      b.exec()
    }
  }
  
  class B {
    var f 
    construct(f) {
      this.f = f
    }
    fun exec () {
      f(5)
    }
  }

  fun main() {
    var a = A()
    print(a.age)
    a.m()
    print(a.age)
    
  }
  ''', style: ParseStyle.module, invokeFunc: 'main');
}
