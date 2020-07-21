num fib(num x) {
  
  if (x < 2) return x;
  else return fib(x - 2) + fib(x - 1);

}
  
void main(){

  var before = now();
	println(fib(15));
  var after = now();
  println(after - before);
  
  
}
