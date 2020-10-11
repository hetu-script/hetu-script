#include <iostream>
#include <iterator>
#include <string>
#include <regex>

int main()
{
  //hetu::run();

  std::string s = "fun main(): void {\n"
    "  print('hello world')\n"
    "}";

  std::regex e("(//.*)|" // 注释 group(1)
    "([_]?[a-zA-Z]+[a-zA-Z_0-9]*)|" // 标识符 group(2)
    "(...|\|\||&&|==|!=|<=|>=|[></=%\+\*\-\?!,:;{}\[\]\)\(\.])|" // 标点符号和运算符号 group(3)
    "(\d+(\.\d+)?)|" // 数字字面量 group(4)
    "(('(\\'|[^'])*')|" // 字符串字面量 group(6)
    "(\"(\\\"|[^\"])*\"))");

  // flag type for determining the matching behavior (in this case on string objects)
  std::smatch m;

  // regex_search that searches pattern regexp in the string mystr  

  std::cout << "String that matches the pattern:" << std::endl;
  while (std::regex_search(s, m, e)) {
    for (auto x : m) {
      std::cout << x << " ";
    }
    std::cout << std::endl;
    s = m.suffix().str();
  }
}