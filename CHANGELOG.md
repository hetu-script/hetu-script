## 0.0.5

- Refactor: Migrate to null safety.

## 0.0.4

- Feature: External class.
- Refactor: Build-in dart types.

## 0.0.3

- Feature: Literal function expression (anonymous function). Usage:

```typescript
fun main {
  var func = fun (name: String) {
    return name + '_postfix'
  }

  print(func())
}
```

- Feature: Named function parameters.
- Feature: Support literal hexadecimal numbers.
- Fixed class extends, member override and inheritance.
- Fixed import statement.

## 0.0.2+4

- Fixed bug in method calling of instances.
- Fixed bug of optional function parameters.
- Fixed bug of import statement.
- Fixed bug of member get from super classes.
- Fixed bug of method expression resolving.

## 0.0.2+1

- Added some comments in the dart source file.
- Added some test for error handling.
- Added multiline comment.
- Changed 'HetuEnv' into 'Hetu'.
- Fixed bugs in method calling of instances.

## 0.0.2

- Fixed core library loading issue, no longer use outside source files.
- Changed lisence from GNU GPLv3 to MIT.

## 0.0.1

- Initial version, hello world!
