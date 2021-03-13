abstract class HT_Operator {
  static const endOfFile = 0;
  static const constInt64Table = 1; // length, int64 list
  static const constFloat64Table = 2; // length, float64 list
  static const constUtf8StringTable = 3; // length, string_length, utfstring
  static const boolean = 4;
}
