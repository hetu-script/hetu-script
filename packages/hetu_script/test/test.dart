import 'package:hetu_script/hetu_script.dart';

void main() {
  var hetu = Hetu();
  hetu.init();
  hetu.eval(r'''
      const ticksPerDay = 4; //每天的回合数 morning, afternoon, evening, night
      const daysPerMonth = 30; //每月的天数
      const ticksPerMonth = 120; //每月的回合数 120
      const monthsPerYear = 12; //每年的月数
      const ticksPerYear = 1440; //每年的回合数 1440

      fun getYear(timestamp) => (timestamp / ticksPerYear).truncate()
      fun getMonth(timestamp) =>
          ((timestamp % ticksPerYear) / ticksPerMonth).truncate()
      fun getDay(timestamp) =>
          ((timestamp % ticksPerMonth) / ticksPerDay).truncate()

      print(getYear(288000))
    ''', isScript: true);
}
