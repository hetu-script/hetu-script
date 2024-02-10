# Identifier & keywords

Identifiers (sometimes called symbols) are the names of classes, functions, types, members and fields. In common situations, you can only use letters or characters from any language, plus underscore and dollor sign.

## Explicitly define an identifier

You can get a literal identifier with a pair grave accent mark. In this way, you can use any possible characters for its name.

```dart
var obj = {
  `name-#42🍎`: 'aleph' // it's legal for a field name.
}

print(obj.`name-#42🍎`) // 'aleph'
```

## Keywords

You cannot use reserved keywords as identifiers.

The full list of current keywords are:

**null, true, false, void<sup>1</sup>, type<sup>1</sup>, import<sup>1</sup>, export<sup>1</sup>, from<sup>1</sup>, any<sup>1</sup>, unknown<sup>12</sup>, never<sup>12</sup>, var, final, const, def<sup>2</sup>, delete<sup>2</sup>, type<sup>1</sup>, typeval, typeof, decltypeof, namespace, class, enum, function, struct, this, super, abstract, override<sup>2</sup>, external, static, extends<sup>1</sup>, implements<sup>12</sup>, with<sup>12</sup>, new, constructor, factory, get, set, async<sup>2</sup>, await<sup>2</sup>, break, continue, return, for, in, of<sup>1</sup>, if, else, while, do, switch, is, as, alias<sup>1</sup>**

1: These keywords are **contextual**. they only used in specific places, hence can be used as normal identifiers.

2: These keywords have no really effect for now, they are reserved for future development.
