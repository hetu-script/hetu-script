import 'package:hetu_script/hetu_script.dart';

void main() async {
  final typeid = 'List<Map<String, dynamic>>';

  final type = HTTypeId.parseBaseTypeId(typeid);

  print(type);

  // final hetu = Hetu();
  // await hetu.init();
  // await hetu.eval(r'''
  //     fun main {
  //       let value = ['', 'hello', 'world']
  //       let item = ''
  //       for (let val in value) {
  //         if (val != '') {
  //           item = val
  //           break
  //         }
  //       }
  //       return item
  //     }
  // ''', invokeFunc: 'main');
}
