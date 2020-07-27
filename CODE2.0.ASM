DATA SEGMENT
WCMSTR    DB "Please input a simple expression(only contain +,-,*,\)",0AH,0DH,'$'
OUTSTR    DB 0AH,0DH,"The result is",0AH,0DH,'$'
ERRSTR    DB 0AH,0DH,"error",0AH,0DH,'$'
DIVISORS  DW 10000, 1000, 100, 10, 1
RESULT    DW ?                          ;存放整数部分五位数ASCII码
EXP       DB 'M'
          DW  20 DUP(0)
DATA ENDS
DISP MACRO STR
    LEA  DX,STR
    MOV  AH,9
    INT  21H
ENDM
CODE SEGMENT
ASSUME CS:CODE, DS:DATA
MAIN PROC
    MOV  AX, DATA
    MOV  DS, AX  

    LEA  DI,EXP
    INC  DI
    DISP WCMSTR                          ;输出提示信息
    
AGAIN: 

    MOV  AH,1
    INT  21H                             ;输入一个字符
    CMP  AL,0DH
    JE   OP                              ;如果是回车，就输出结果
    CMP  AL,'+'
    JE   SAVE
    CMP  AL,'-'
    JE   SAVE
    CMP  AL,'*'
    JE   SAVE 
    CMP  AL,'/'
    JE   SAVE
    CMP  AL,'0'
    JL   ERROR
    CMP  AL,'9'
    JG   ERROR
    XOR  AH,AH
    SUB  AL,30H
    XCHG AX,DX
    MOV  CL,10
    MUL  CL
    ADD  AX,DX
    XCHG AX,DX                           ;计算整个数字的大小并存在DX中
    JMP  AGAIN
OP:
    CALL SAVENUM
    CALL OUTPUT    
EXIT:
    MOV  AX, 4C00H
    INT  21H
ERROR:
    LEA  DX,ERRSTR
    MOV  AH,9
    INT  21H
    JMP  EXIT
SAVE:
    CALL SAVENUM
    CALL SAVESG
    MOV  DX,0
    JMP  AGAIN
RET
MAIN ENDP

SAVENUM PROC
    MOV  [DI],AL
    INC  DI
    INC  CX
RET
SAVENUM ENDP

SAVESG PROC
    MOV  [DI],AL
    INC  DI
    INC  CX
RET
SAVESG ENDP



OUTPUT PROC
    CALL OPERATE
    CMP  RESULT,0
    JGE  NEXT
    NEG  RESULT
    MOV  DL,'-'
    MOV  AH,2                  
    INT  21H                        ;输出负号
NEXT:
    
RET
OUTPUT ENDP
CODE ENDS
END MAIN
