## Hello world：脚本写法简单示例

河图脚本语言的文件可以使用三种不同的代码组织形式：脚本、库和程序

脚本：解释后立即执行的语句块，可能包含变量和函数的声明语句、表达式语句和控制语句。

```
print('hello world!')
```

库：解释后不一定立即执行的文件，可能包含导入语句、变量、函数和类的声明语句。

```
func greeting {
  print(string('hello world! ', 42))
}
```

程序：和库的结构一样，但一定会包含一个名为main的函数，作为程序入口。

```
import 'greeting.ht'

func main {
  greeting()
}
```









## 关键词

Hetu运算符优先级
Description     Operator       Associativity   Precedence
Unary postfix   e()            None            16
Unary prefix    -e, !e         None            15
Multiplicative  *, /, %        Left            14
Additive        +, -           Left            13
Relational      <, >, <=, >=   None            8
Equality        ==, !=         None            7
Logical AND     &&             Left            6
Logical Or      ||             Left            5
Assignment      =              Right           1