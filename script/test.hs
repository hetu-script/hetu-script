class Person {
	String name;
	
	Person(String name) {
		this.name = name;
	}
	
	void greeting() {
		println(name);
	}
}
  
void main(){

  var p = Person('aleph42');
  
	p.greeting();
  
  
}
