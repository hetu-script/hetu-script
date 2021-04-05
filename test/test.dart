import 'package:hetu_script/hetu_script.dart';

void main() async {
  var hetu = Hetu();
  await hetu.init();
  await hetu.eval(r'''
      class SuperClass {
        var name = 'Super'
      }
      class ExtendClass extends SuperClass {
        var name = 'Extend'
      }
      fun superMember {
        var a = ExtendClass()
        var b = a as SuperClass
        b.name = 'changed super name'

        return a.name
      }
      ''', invokeFunc: 'superMember');
}
