# Hetu bytecode specification

## Declaration

### TypeId

| Name               | Bytes length | type       | optional |
| :----------------- | :----------- | :--------- | :------- |
| length of id       | 1            | byte       |          |
| id utf8 string     | 255          | uint8 list |          |
| length of arg list | 1            | byte       |          |
| arg1, arg2 ...     | ...          | uint8 list |          |
| isNullable         | 1            | bool       |          |

### General declaration

| Name                  | Bytes length | type       | optional |
| :-------------------- | :----------- | :--------- | :------- |
| length of id          | 1            | byte       |          |
| id utf8 string        | 255          | uint8 list |          |
| isDynamic             | 1            | bool       |          |
| isExtern              | 1            | bool       |          |
| isImmutable           | 1            | bool       |          |
| isMember              | 1            | bool       |          |
| isStatic              | 1            | bool       |          |
| hasType               | 1            | bool       |          |
| TypeId                | ...          | TypeId     |          |
| hasInitializer        | 1            | bool       |          |
| length of initializer | 2            | uint16     | true     |
| initializer           | 65,535       | uint8 list | true     |

### Parameter declaration

Parameter declaration have no opcode marker at the start since it's always part of a function declaration.

| Name                  | Bytes Length | type       | optional |
| :-------------------- | :----------- | :--------- | :------- |
| length of id          | 1            | byte       |          |
| id utf8 string        | 255          | uint8 list |          |
| isOptional            | 1            | bool       |          |
| isNamed               | 1            | bool       |          |
| isVariadic            | 1            | bool       |          |
| hasType               | 1            | bool       |          |
| TypeId                | ...          | TypeId     |          |
| hasInitializer        | 1            | bool       |          |
| length of initializer | 2            | uint16     | true     |
| initializer           | 65,535       | uint8 list | true     |

### Declaration block

| Name                       | Bytes Length | type       | optional |
| :------------------------- | :----------- | :--------- | :------- |
| HTOpCode.declTable         | 1            | byte       |          |
| length of func decls list  | 2            | uint16     |          |
| func decls list            | 65,535       | uint8 list |          |
| length of class decls list | 2            | uint16     |          |
| class decls list           | 65,535       | uint8 list |          |
| length of var decls list   | 2            | uint16     |          |
| var decls list             | 65,535       | uint8 list |          |

### Function declaration

FunctionTypeId is not included in bytecode, the vm has to
create the typeid according to the param types and return value type.

| Name                 | Bytes Length | type       | optional |
| :------------------- | :----------- | :--------- | :------- |
| length of id         | 1            | byte       |          |
| id utf8 string       | 255          | uint8 list |          |
| type params          | ...          |            |          |
| function type        | 1            | byte       |          |
| isExtern             | 1            | bool       |          |
| isStatic             | 1            | bool       |          |
| isConst              | 1            | bool       |          |
| isVariadic           | 1            | bool       |          |
| min arity            | 1            | byte       |          |
| max arity\*          | 1            | byte       |          |
| length of paramDecls | 1            | byte       |          |
| list of param decls  | 255          | uint8 list | true     |
| has return type      | 1            | bool       |          |
| return type          | ...          | HTTypeId   |          |
| hasBody              | 1            | bool       |          |
| length of body       | 2            | uint16     | true     |
| definition body      | 65,535       | uint8 list | true     |

arity\*:

- 0 when there's only one variadic parameter
- 2 when there's 2 positional parameters and 1 optional parameter

## Class declaration

| Name                       | Bytes length | type       | optional |
| :------------------------- | :----------- | :--------- | :------- |
| length of id               | 1            | byte       |          |
| id utf8 string             | 255          | uint8 list |          |
| type params                | ...          |            |          |
| class type                 | 1            | byte       |          |
| length of super class id   | 1            | byte       |          |
| super class id utf8 string | 255          | uint8 list |          |
| length of func decls       | 2            | uint16     |          |
| list of func decls         | 65,535       | uint8 list |          |
| length of var decls        | 2            | uint16     |          |
| list of var decls          | 65,535       | uint8 list |          |

## Value

### Anonymous funciton

## Statement

### If

| Name                  | Bytes length | type       | optional |
| :-------------------- | :----------- | :--------- | :------- |
| HTOpCode.ifStmt       | 1            | byte       |          |
| then branch length \* | 2            | uint16     |          |
| else branch length \* | 2            | uint16     |          |
| condition             | ...          | uint8 list |          |
| then branch           | ...          | uint8 list |          |
| else branch           | ...          | uint8 list | true     |

else branch ip \*:

If there's no else branch, then this ip is 0.

### While

| Name                | Bytes length | type          | optional |
| :------------------ | :----------- | :------------ | :------- |
| HTOpCode.whileStmt  | 1            | byte          |          |
| length of condition | 2            | uint16 & bool |          |
| length of loop      | 2            | uint16        |          |
| condition           | ...          | uint8 list    | true     |
| loop                | ...          | uint8 list    |          |

loop ip \*:

If there's no else branch, then this ip is 0.

### Do

| Name            | Bytes length | type          | optional |
| :-------------- | :----------- | :------------ | :------- |
| HTOpCode.doStmt | 1            | byte          |          |
| condition ip \* | 2            | uint16 & bool |          |
| loop            | ...          | uint8 list    |          |
| condition       | ...          | uint8 list    | true     |

condition ip \*:

If there's no else branch, then this ip is 0.

### For

| Name                 | Bytes length | type          | optional |
| :------------------- | :----------- | :------------ | :------- |
| HTOpCode.blockStart  | 1            | byte          |          |
| HTOpCode.forStmt     | 1            | byte          |          |
| HTForStmtType.normal | 1            | byte          |          |
| condition ip \*      | 2            | uint16 & bool |          |
| loop                 | ...          | uint8 list    |          |
| condition            | ...          | uint8 list    | true     |

### When

| Name                | Bytes length | type          | optional |
| :------------------ | :----------- | :------------ | :------- |
| HTOpCode.whenStmt   | 1            | byte          |          |
| length of condition | 2            | uint16 & bool |          |
| condition           | ...          | uint8 list    |          |
| length of cases     | 2            | uint16 & bool |          |
| case                | ...          | uint8 list    |          |
| case block          | ...          | uint8 list    |          |
