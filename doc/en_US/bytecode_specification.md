# Hetu bytecode specification

## Declaration

### General declaration

| Name                  | Length | type       | optional |
| :-------------------- | :----- | :--------- | :------- |
| HTOpCode.varDecl      | 1      | byte       |          |
| length of id          | 1      | byte       |          |
| id utf8 string        | ...    | uint8 list |          |
| typeInference         | 1      | bool       |          |
| isExtern              | 1      | bool       |          |
| isStatic              | 1      | bool       |          |
| isImmutable           | 1      | bool       |          |
| HTTypeId              |        |            |          |
| HTOpCode.varInit      | 1      | bool       |          |
| length of initializer | 1      | byte       | true     |
| initializer           | ...    | uint8 list | true     |
| HTOpCode.returnVal    | 1      | byte       | true     |

### Parameter declaration

Parameter declaration have no opcode marker at the start since it's always part of a function declaration.

| Name                  | Length | type       | optional |
| :-------------------- | :----- | :--------- | :------- |
| length of id          | 1      | byte       |          |
| id utf8 string        | ...    | uint8 list |          |
| isOptional            | 1      | bool       |          |
| isNamed               | 1      | bool       |          |
| isVariadic            | 1      | bool       |          |
| HTTypeId              |        |            |          |
| HTOpCode.varInit      | 1      | bool       |          |
| length of initializer | 1      | byte       | true     |
| initializer           | ...    | uint8 list | true     |
| HTOpCode.returnVal    | 1      | byte       | true     |

### Named Function declaration

FunctionTypeId is not included in bytecode, the vm has to
create the typeid according to the param types and return value type.

| Name                | Length | type       | optional |
| :------------------ | :----- | :--------- | :------- |
| HTOpCode.funcDecl   | 1      | byte       |          |
| length of id        | 1      | byte       |          |
| id utf8 string      | ...    | uint8 list |          |
| function type       | 1      | byte       |          |
| isExtern            | 1      | bool       |          |
| isStatic            | 1      | bool       |          |
| isConst             | 1      | bool       |          |
| isVariadic          | 1      | bool       |          |
| return type         | ...    | HTTypeId   |          |
| arity               | 1      | byte       |          |
| list of param decls | ...    | uint8 list | true     |
| length of body      | ...    | uint16     | true     |
| definition body     | ...    | uint8 list | true     |

## Value

### Anonymous funciton
