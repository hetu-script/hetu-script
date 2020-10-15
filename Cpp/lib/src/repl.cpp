#include <iostream>
#include <iterator>
#include <string>
#include <regex>


typedef std::basic_regex<char32_t> u32regex;
typedef std::match_results<const char32_t*> u32matches;

int main()
{
	std::u32string input = L"// main function entrance.\n"
		"// another comment.\n"
		"fun main(): void {\n"
		"  print('hello world', 6 * 7)\n"
		"}";

	std::regex reg_exp("(//.*)|([_]?[\\p{L}]+[\\p{L}_0-9]*)");

	// flag type for determining the matching behavior (in this case on string objects)
	std::smatch matches;

	// regex_search that searches pattern regexp in the string mystr  
	std::regex_search(input, matches, reg_exp);

	std::cout << "String that matches the pattern:" << std::endl;
	while (std::regex_search(input, matches, reg_exp)) {
		std::cout << '[' << matches.str() << ']' << std::endl;
		input = matches.suffix().str();
	}
}