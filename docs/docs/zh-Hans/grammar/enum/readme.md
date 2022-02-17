# 枚举

枚举的声明方法和 Dart 相同：

```javascript
enum Country {
  unitedStates,
  japan,
  iraq,
  ukraine,
}
```

但目前 IDE Tool 尚未提供代码补全功能，因此 enum 可能并不太好用。目前主要是通过 external 关键字来兼容 Dart 代码中的 enum 对象。
