import 'package:hetu_script/hetu_script.dart';

void main() async {
  final hetu = HTVM();

  await hetu.init(coreModule: false, coreExternalClasses: false);

  await hetu.eval(r'''
  external fun print(... arg)
  
  fun main {
    
    
  }
  

  ''', invokeFunc: 'main');
}
