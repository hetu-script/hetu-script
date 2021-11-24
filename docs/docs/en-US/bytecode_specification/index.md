# Hetu bytecode specification

## OpCode

### OpCode.goto

| Name          | Bytes length | type  | optional |
| :------------ | :----------- | :---- | :------- |
| HTOpCode.goto | 1            | byte  |          |
| distance      | 2            | int16 |          |

### OpCode.logicalAnd

| Name                 | Bytes length | type     | optional |
| :------------------- | :----------- | :------- | :------- |
| HTOpCode.logicalAnd  | 1            | byte     |          |
| length of right expr | 2            | uint16   |          |
| right expr           | 65,535       | bytecode |          |

## Value

### Short utf8 string

| Name             | Bytes length | type     | optional |
| :--------------- | :----------- | :------- | :------- |
| length of string | 1            | byte     |          |
| utf8 string      | 255          | bytecode |          |

### Local value symbol

| Name                   | Bytes length | type              | optional |
| :--------------------- | :----------- | :---------------- | :------- |
| HTOpCode.local         | 1            | byte              |          |
| HTValueTypeCode.symbol | 1            | byte              |          |
| id                     | 256          | short utf8 string |          |
| isGetKey               | 1            | bool              |          |
| has type args          | 1            | bool              |          |
| length of type args    | 1            | byte              |          |
| arg1, arg2 ...         | ...          | bytecode list     |          |

### Type

| Name                | Bytes length | type              | optional |
| :------------------ | :----------- | :---------------- | :------- |
| type: normal typeid | 1            | enum              |          |
| id                  | 256          | short utf8 string |          |
| length of arg list  | 1            | byte              |          |
| arg1, arg2 ...      | ...          | bytecode list     |          |
| isNullable          | 1            | bool              |          |

### ParameterType

| Name                | Bytes length | type              | optional |
| :------------------ | :----------- | :---------------- | :------- |
| type: normal typeid | 1            | enum              |          |
| id                  | 256          | short utf8 string |          |
| length of arg list  | 1            | byte              |          |
| arg1, arg2 ...      | ...          | bytecode list     |          |
| isNullable          | 1            | bool              |          |
| isOptional          | 1            | bool              |          |
| isNamed             | 1            | bool              |          |
| isVariadic          | 1            | bool              |          |

### FunctionType

| Name                       | Bytes length | type        | optional |
| :------------------------- | :----------- | :---------- | :------- |
| type: function typeid      | 1            | enum        |          |
| length of param type list  | 1            | byte        |          |
| paramType1, paramType2 ... | ...          | TypeId list |          |
| minarity                   | 1            | byte        |          |
| return type                | 1            | TypeId      |          |

### Anonymous funciton

## Control flow

### If

| Name                   | Bytes length | type     | optional |
| :--------------------- | :----------- | :------- | :------- |
| condition              | ...          | bytecode |          |
| HTOpCode.ifStmt        | 1            | byte     |          |
| then branch length + 2 | 2            | uint16   |          |
| then branch            | ...          | bytecode |          |
| HTOpCode.goto          | 1            | byte     |          |
| else branch length     | ...          | int16    |          |
| else branch            | ...          | bytecode | true     |

### While

| Name               | Bytes length | type     | optional |
| :----------------- | :----------- | :------- | :------- |
| HTOpCode.loopPoint | 1            | byte     |          |
| length of loop     | 2            | uint16   |          |
| condition          | ...          | bytecode | true     |
| HTOpCode.whileStmt | 1            | byte     |          |
| has condition      | 1            | bool     |          |
| loop               | ...          | bytecode |          |
| HTOpCode.goto      | 1            | byte     |          |
| -(length of loop)  | 1            | int16    |          |

### Do

| Name               | Bytes length | type     | optional |
| :----------------- | :----------- | :------- | :------- |
| HTOpCode.loopPoint | 1            | byte     |          |
| length of loop     | 2            | uint16   |          |
| loop               | ...          | bytecode |          |
| condition          | ...          | bytecode |          |
| HTOpCode.doStmt    | 1            | byte     |          |

has condition \*:
This option is always true in Do statement.

### For

| Name               | Bytes length | type     | optional |
| :----------------- | :----------- | :------- | :------- |
| init               | ...          | bytecode | true     |
| HTOpCode.loopPoint | 1            | byte     |          |
| length of loop     | 2            | uint16   |          |
| condition          | ...          | bytecode | true     |
| HTOpCode.whileStmt | 1            | byte     |          |
| has condition      | 1            | bool     |          |
| loop               | ...          | bytecode |          |
| increment          | ...          | bytecode | true     |
| HTOpCode.goto      | 1            | byte     |          |
| -(length of loop)  | 1            | int16    |          |

### When

| Name                 | Bytes length | type          | optional |
| :------------------- | :----------- | :------------ | :------- |
| condition            | ...          | uint8 list    |          |
| HTOpCode.whenStmt    | 1            | byte          |          |
| has condition        | 1            | bool          |          |
| length of cases      | 1            | byte          |          |
| ip of case as list   | ...          | uint16 list   |          |
| ip of branch as list | ...          | uint16 list   |          |
| list of cases        | ...          | bytecode list |          |
| list branchese       | ...          | bytecode list |          |
| ip of else           | 2            | uint16        |          |
| length of else       | 2            | uint16        |          |
| else                 | ...          | uint8 list    |          |

## Statement

### General declaration

| Name                  | Bytes length | type              | optional |
| :-------------------- | :----------- | :---------------- | :------- |
| id                    | 256          | short utf8 string |          |
| isDynamic             | 1            | bool              |          |
| isExtern              | 1            | bool              |          |
| isImmutable           | 1            | bool              |          |
| isMember              | 1            | bool              |          |
| isStatic              | 1            | bool              |          |
| hasType               | 1            | bool              |          |
| TypeId                | ...          | TypeId            |          |
| hasInitializer        | 1            | bool              |          |
| initializer line      | 2            | uint16            |          |
| initializer column    | 2            | uint16            |          |
| length of initializer | 2            | uint16            | true     |
| init with endOfExec   | 65,535       | bytecode          | true     |

### Parameter declaration

Parameter declaration have no opcode marker at the start since it's always part of a function declaration.

| Name                  | Bytes Length | type              | optional |
| :-------------------- | :----------- | :---------------- | :------- |
| id                    | 256          | short utf8 string |          |
| isOptional            | 1            | bool              |          |
| isNamed               | 1            | bool              |          |
| isVariadic            | 1            | bool              |          |
| hasType               | 1            | bool              |          |
| TypeId                | ...          | TypeId            |          |
| hasInitializer        | 1            | bool              |          |
| initializer line      | 2            | uint16            |          |
| initializer column    | 2            | uint16            |          |
| length of initializer | 2            | uint16            | true     |
| init with endOfExec   | 65,535       | bytecode          | true     |

### Declaration block

| Name                       | Bytes Length | type          | optional |
| :------------------------- | :----------- | :------------ | :------- |
| HTOpCode.declTable         | 1            | byte          |          |
| length of enum decls list  | 2            | uint16        |          |
| enum decls list            | 65,535       | bytecode list |          |
| length of func decls list  | 2            | uint16        |          |
| func decls list            | 65,535       | bytecode list |          |
| length of class decls list | 2            | uint16        |          |
| class decls list           | 65,535       | bytecode list |          |
| length of var decls list   | 2            | uint16        |          |
| var decls list             | 65,535       | bytecode list |          |

### Function declaration

FunctionTypeId is not included in bytecode, the vm has to
create the typeid according to the param types and return value type.

| Name                                              | Bytes Length | type                   | optional |
| :------------------------------------------------ | :----------- | :--------------------- | :------- |
| id                                                | 256          | short utf8 string      |          |
| declId                                            | 256          | short utf8 string      |          |
| type params length                                | 1            | byte                   |          |
| type params list                                  | ...          | short utf8 string list |          |
| hasExternalTypedef                                | 1            | bool                   |          |
| externalTypedef                                   | 256          | short utf8 string      |          |
| function type                                     | 1            | byte                   |          |
| isExtern                                          | 1            | bool                   |          |
| isStatic                                          | 1            | bool                   |          |
| isConst                                           | 1            | bool                   |          |
| isVariadic                                        | 1            | bool                   |          |
| min arity                                         | 1            | byte                   |          |
| max arity\*                                       | 1            | byte                   |          |
| has paramDecls                                    | 1            | bool                   |          |
| length of paramDecls                              | 1            | byte                   |          |
| list of param decls                               | 255          | bytecode list          | true     |
| return type or super constructor                  | 1            | enum                   |          |
| (return type)<br><br>(has ctor name<br>ctor args) | ...          | HTType                 |          |
| has body                                          | 1            | bool                   |          |
| body line                                         | 2            | uint16                 |          |
| body column                                       | 2            | uint16                 |          |
| length of body                                    | 2            | uint16                 | true     |
| body with endOfExec                               | 65,535       | bytecode               | true     |

arity\*:

- 0 when there's only one variadic parameter
- 2 when there's 2 positional parameters and 1 optional parameter

## Class declaration

| Name                         | Bytes length | type              | optional |
| :--------------------------- | :----------- | :---------------- | :------- |
| id                           | 256          | short utf8 string |          |
| type params                  | ...          |                   |          |
| isExtern                     | 1            | bool              |          |
| isAbstract                   | 1            | bool              |          |
| has super class              | 1            | bool              |          |
| super class typeid           | ...          | HTTypeId          |          |
| has implements class         | 1            | bool              |          |
| implements class typeid list | ...          | HTTypeId list     |          |
| has mixin class              | 1            | bool              |          |
| mixin class typeid           | ...          | HTTypeId list     |          |
| has body                     | 1            | bool              |          |
| length of func decls         | 2            | uint16            |          |
| list of func decls           | 65,535       | bytecode list     |          |
| length of var decls          | 2            | uint16            |          |
| list of var decls            | 65,535       | bytecode list     |          |

## Enum declaration

| Name              | Bytes length | type                   | optional |
| :---------------- | :----------- | :--------------------- | :------- |
| id                | 256          | short utf8 string      |          |
| isExtern          | 1            | bool                   |          |
| length of id list | 2            | uint16                 |          |
| list of enum ids  | 65,535       | short utf8 string list |          |
