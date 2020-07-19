## Usage

A simple usage example:

```dart
import 'package:hetu_script/hetu_script.dart';

main() {
  Hetu.init();
  Hetu.eval('test.hs');
}
```

Content of 'test.hs':

```dart
class calculator {
  num x;
  num y;
  
  calculator(num x, num y) {
    this.x = x;
    this.y = y;
  }
  
  num meaning() {
    return x * y;
  }
}

void main(){
  var cal = calculator(6, 7);
  println('the meaning of life, universe and everything is ' + cal.meaning());
}
```


## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hythl0day/HetuScript/issues
