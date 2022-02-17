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

If you have at least one export statement that is not export from other sources (export 'path'), you wont' inexplicitly export the members of this namespace.

Otherwise, every top level symbol will be exported by default.
