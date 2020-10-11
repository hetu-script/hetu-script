#include <iostream>
#include <iterator>
#include <string>
#include <regex>

#include "lexer.h"

namespace hetu {
  void run()
  {
    std::string input = "fun main(): void {\n"
                        "  print('hello world')\n"
                        "}";

    std::regex regexp("([_]?[a-zA-Z]+[a-zA-Z_0-9]*)");

    // flag type for determining the matching behavior (in this case on string objects)
    std::smatch m;

    // regex_search that searches pattern regexp in the string mystr  
    std::regex_search(input, m, regexp);

    std::cout << "String that matches the pattern:" << std::endl;
    for (auto x : m) {
      std::cout << x << " ";
    }
  }
}