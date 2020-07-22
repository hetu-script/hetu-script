
// 类的定义
class calculator {
  // 成员变量
  num x;
  num y;

  // 带有参数的构造函数
  calculator(num x, num y) {
    // this关键字、get取值和赋值、语句块中同名变量的覆盖
    this.x = x;
    this.y = y;
  }

  // 带有返回类型的成员函数
  num meaning() {
    // 不通过this直接使用成员变量
    return x * y;
  }
}

// 程序入口 
void main(){
  // 带有初始化语句的变量定义
  // 从类的构造函数获得对象的实例
  var cal = calculator(6, 7);
  
  // 调用外部函数，调用外部成员函数，字符串类型检查
  println('the meaning of life, universe and everything is ' + cal.meaning().toString());
}
