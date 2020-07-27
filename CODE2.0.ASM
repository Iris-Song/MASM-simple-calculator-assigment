DATA SEGMENT
WCMSTR    DB "Please input a simple expression(only contain +,-,*,\)",0AH,0DH,'$'
OUTSTR    DB 0AH,0DH,"The result is",0AH,0DH,'$'
ERRSTR    DB 0AH,0DH,"error",0AH,0DH,'$'
DIVISORS  DW 10000, 1000, 100, 10, 1
RESULT1   DB 0,0,0,0,0,'$'               ;存放整数部分五位数ASCII码
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
    JE                            ;如果是回车，就
    
    CMP  AL,'0'
    JL   
    CMP  AL,'9'
    JG   
    XOR  AH,AH
    SUB  AL,30H
    XCHG AX,DX
    MOV  CL,10
    MUL  CL
    ADD  AX,DX
    XCHG AX,DX                           ;计算整个数字的大小并存在DX中
    JMP  AGAIN
OP:
    CALL OUTPUT    
EXIT:
    MOV  AX, 4C00H
    INT  21H
ERROR:
    LEA  DX,ERRSTR
    MOV  AH,9
    INT  21H
    JMP  EXIT
RET
MAIN ENDP

SAVENUM PROC
    MOV  [DI],AL
    INC  DI
    INC  CX
SAVENUM ENDP

OUTPUT PROC
    MOV  AX,DX
    MOV  SI,OFFSET DIVISORS
    MOV  DI,OFFSET RESULT1                    
    MOV  CX,5  
ONE:
    MOV  DX,0           
    DIV  WORD PTR [SI]                   ;除法指令的被除数是隐含操作数，此处为dx:ax，商ax,余数dx
    ADD  AL,30H                          ;得到相应数字的ASCII码
    MOV  BYTE PTR [DI],AL                ;存入result1中
    INC  DI                               
    ADD  SI,2                          
    MOV  AX,DX                       
    LOOP ONE
    MOV  CX,4       
    MOV  DI, OFFSET RESULT1
TWO:
    CMP  BYTE PTR [DI],'0'               ;不输出前面的0字符   
    JNE  PRINT                           
    INC  DI                          
    LOOP TWO 
PRINT:                                   ;输出整数部分
    MOV  DX,DI                      
    MOV  AH,9
    INT  21H
    MOV  DL,'.'
    MOV  AH,2
    INT  21H                             ;输出小数点
    RET
OUTPUT ENDP
CODE ENDS
END MAIN
