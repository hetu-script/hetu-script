extension Binary on int {
  int get b {
    return int.parse(toRadixString(10), radix: 2);
  }
}
