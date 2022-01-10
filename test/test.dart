import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  final result = hetu.eval(r'''
    // var a: {} = {
    //   name: 'jimmy',
    //   greeting: () {
    //     print('hi! I\'m ${this.name}')
    //   }
    // }
    // print(typeof a)

    // final list = [1,2,3,4,5]
    // final locationNumber = 4
    // var generatedIndexes = []
    // while (generatedIndexes.length < locationNumber) {
    //   var index
    //   do {
    //     index = list.random
    //   } while (generatedIndexes.contains(index))
    //   generatedIndexes.add(index)
    // }

    var a = 0
    do {
      var b = 0
      do {
        print(a, b++)
      } while (b < 2)
      a++
    } while (a < 2)

    print('done!')
    ''');

  print(result);
}
