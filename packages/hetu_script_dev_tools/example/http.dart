import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

void main() {
  final sourceContext = HTFileSystemResourceContext();
  final hetu = Hetu(sourceContext: sourceContext);
  hetu.init();

  hetu.eval(r'''
    import 'https://random-data-api.com/api/internet_stuff/random_internet_stuff' as json

    print(json.username)
  ''');
}
