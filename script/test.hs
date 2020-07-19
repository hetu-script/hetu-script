class calculator {
  num x;
  num y;

  calculator(num x, num y) {
    this.x = x;
    this.y = y;
  }

  num meaning() {
    return x * y;
  }
  
  num get5(num x) {
    return x * 5;
  }
}
  
void main(){

  var cal = calculator(6, 7);
  
  println('the meaning of life, universe and everything is ' + cal.meaning());
  
  
}
