## Import

Use import statement to import from another source file.

You can specify a list to limit the symbols imported.

You can set an aliases for the imported namespace.

```javascript
import 'game.ht'
import { hello, calculator } from 'hello.ht' as h

function main {
  h.greeting()
}
```

You have to specify the extention part (.ht or .json) of the path.

You can use relative key such as '../../filename.ht' in the path string (this also applies to export & require).

## Export

Use export in a source to specify the symbols you wish to let other source access when they import from you.

You can either export another source, or export the symbols within this source.

```javascript
export {
  hello,
  calculator,
}

export 'game.ht'
export { hello } from 'hello.ht'
```

Use export with a string literal as path, **you will first import the source by that path, then export it. So you can use those symbols of that source just like normal import statement.**

You cannot export symbols of imported namespaces without specify its path.

If no path is provided, there must be a '{}' list to indicate the symbols that you wish to export from this namespace.

By default, every top level symbol will be exported, if you do not have any kind of export statement.

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
    var name = 'Richard Byson'
    var age = 42
''', fullName: 'source1.ht');
sourceContext.addResource(source1.fullName, source1);
hetu.eval(r'''
    final { name, age } = require('source1.ht');
    print(name, age)
''');
```

You have to use it in the form of a variable declaration, otherwise the importing won't have any effect. This is to say, you have to explicitly list all symbols that you wish to import, or to give a alias name to the imported namespace when using this statement.

```javascript
require("source1.ht"); // this won't have any effect!
```

Because the file is loaded dynamically rather than statically before compile, you have to ensure that the source is loaded in the sourceContext before running the script contains the require keyword.
