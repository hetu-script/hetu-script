## Import

Use import statement to import from another source file.

You can specify a list to limit the symbols imported.

You can set an aliases for the imported namespace.

```javascript
import 'game.ht'
import { hello, calculator } from 'hello.ht' as h

fun main {
  h.greeting()
}
```

## Export

Use export in a source to specify the symbols you wish to let other source access when they import from you.

If there's no path provided, exported the symbols from the source contains this statement.

You can give a path after the export keyword, to export other source's content.

```javascript
export {
  hello,
  calculator,
}

export 'game.ht'
export { hello } from 'hello.ht'
```

Every top level symbol will be exported by default if you do not have any export statement.

## require

After 0.4.0, you can dynamically import a source, use `require` keyword in your functions or script.

```dart
final sourceContext = HTOverlayContext();
var hetu = Hetu(
  config: HetuConfig(
    normalizeImportPath: false,
  ),
  sourceContext: sourceContext,
);
hetu.init();
final source1 = HTSource(r'''
    final greeting = 'hello world!'
''', fullName: 'source1.ht');
sourceContext.addResource(source1.fullName, source1);
hetu.eval(r'''
    final nsp = require('source1.ht');
    print(nsp.greeting)
''');
```

You have to use it in the form of a variable declaration, otherwise the importing won't have any effect.

```javascript
require('source1.ht'); // this won't have any effect!
```

Because the file is loaded dynamically rather than statically before compile, you have to ensure that the source is loaded in the sourceContext before running the script contains the require keyword.
