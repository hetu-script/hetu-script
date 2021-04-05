import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class SuperClass {
        var name = 'Super'
        var age = 1
        fun addAge() {
          age = age + 1
        }
      }
      class ExtendClass extends SuperClass {
        var name = 'Extend'
        fun addAge() {
          age = age + 1
          super.addAge()
        }
      }
      fun superMember {
        var a = ExtendClass()
        a.addAge()
        return a.age
      }
      ''', invokeFunc: 'superMember');
}
