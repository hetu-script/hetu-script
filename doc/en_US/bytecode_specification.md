# Hetu bytecode specification

## OpCode

| Name          | Bytes length | type  | optional |
| :------------ | :----------- | :---- | :------- |
| HTOpCode.goto | 1            | byte  |          |
| distance      | 2            | int16 |          |

## Value

### Short utf8 string

| Name             | Bytes length | type     | optional |
| :--------------- | :----------- | :------- | :------- |
| length of string | 1            | byte     |          |
| utf8 string      | 255          | bytecode |          |

### TypeId

| Name               | Bytes length | type              | optional |
| :----------------- | :----------- | :---------------- | :------- |
| id                 | 256          | short utf8 string |          |
| length of arg list | 1            | byte              |          |
| arg1, arg2 ...     | ...          | bytecode list     |          |
| isNullable         | 1            | bool              |          |

### Anonymous funciton

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

| Name                 | Bytes Length | type                   | optional |
| :------------------- | :----------- | :--------------------- | :------- |
| id                   | 256          | short utf8 string      |          |
| declId               | 256          | short utf8 string      |          |
| type params length   | 1            | byte                   |          |
| type params list     | ...          | short utf8 string list |          |
| hasExternalTypedef   | 1            | bool                   |          |
| externalTypedef      | 256          | short utf8 string      |          |
| function type        | 1            | byte                   |          |
| extern type          | 1            | byte                   |          |
| isStatic             | 1            | bool                   |          |
| isConst              | 1            | bool                   |          |
| isVariadic           | 1            | bool                   |          |
| min arity            | 1            | byte                   |          |
| max arity\*          | 1            | byte                   |          |
| length of paramDecls | 1            | byte                   |          |
| list of param decls  | 255          | bytecode list          | true     |
| has return type      | 1            | bool                   |          |
| return type          | ...          | HTTypeId               |          |
| hasBody              | 1            | bool                   |          |
| length of body       | 2            | uint16                 | true     |
| body with endOfExec  | 65,535       | bytecode               | true     |

arity\*:

- 0 when there's only one variadic parameter
- 2 when there's 2 positional parameters and 1 optional parameter

## Class declaration

| Name                 | Bytes length | type              | optional |
| :------------------- | :----------- | :---------------- | :------- |
| id                   | 256          | short utf8 string |          |
| type params          | ...          |                   |          |
| class type           | 1            | byte              |          |
| super class id       | 256          | short utf8 string |          |
| length of func decls | 2            | uint16            |          |
| list of func decls   | 65,535       | bytecode list     |          |
| length of var decls  | 2            | uint16            |          |
| list of var decls    | 65,535       | bytecode list     |          |

## Enum declaration

| Name              | Bytes length | type                   | optional |
| :---------------- | :----------- | :--------------------- | :------- |
| id                | 256          | short utf8 string      |          |
| isExtern          | 1            | bool                   |          |
| length of id list | 2            | uint16                 |          |
| list of enum ids  | 65,535       | short utf8 string list |          |

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
| init               | ...          | bytecode |          |
| HTOpCode.loopPoint | 1            | byte     |          |
| length of loop     | 2            | uint16   |          |
| condition          | ...          | bytecode |          |
| HTOpCode.whileStmt | 1            | byte     |          |
| has condition      | 1            | bool     |          |
| loop               | ...          | bytecode |          |
| increment          | ...          | bytecode |          |
| HTOpCode.goto      | 1            | byte     |          |
| -(length of loop)  | 1            | int16    |          |

### ForIn & ForOf

| Name             | Bytes length | type              | optional |
| :--------------- | :----------- | :---------------- | :------- |
| object           | ...          | bytecode          |          |
| HTOpCode.forStmt | 1            | byte              |          |
| ForStmtType      | 1            | byte              |          |
| var decl keyword | 256          | short utf8 string |          |
| var name         | 256          | short utf8 string |          |
| length of loop   | 2            | uint16            |          |
| loop             | ...          | bytecode          |          |

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
