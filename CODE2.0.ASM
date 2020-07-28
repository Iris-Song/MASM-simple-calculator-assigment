DATA SEGMENT
WCMSTR    DB "Please input a simple expression(only contain +,-,*,\)",0AH,0DH,'$'
OUTSTR    DB 0AH,0DH,"S=",'$'
ERRSTR    DB 0AH,0DH,"error",0AH,0DH,'$'
RESULT    DW ?                          
EXP       DB  'M'
          DW  20 DUP(0)
DIVISORS  DW 10000, 1000, 100, 10, 1
RESULT1   DB 0,0,0,0,0,"$"               ;存放整数部分五位数ASCII码 
RESULTP   DW 0
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
    MOV  RESULTP,0
    LEA  DI,EXP
    INC  DI
    DISP WCMSTR                          ;输出提示信息
    MOV  DX,0
AGAIN: 
    MOV  AH,1
    INT  21H                             ;输入一个字符
    CMP  AL,0DH
    JE   OP                              ;如果是回车，就输出结果
    CMP  AL,'S'
    JE   AGAIN
    CMP  AL,'='
    JE   AGAIN
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
    CALL OPERATE  
    CALL OUTPUT    
EXIT:
    MOV  AX, 4C00H
    INT  21H
ERROR:
    DISP ERRSTR
    JMP  EXIT
SAVE:
    CALL SAVENUM
    CALL SAVESG
    MOV  DX,0
    JMP  AGAIN
    RET
MAIN ENDP

SAVENUM PROC
    XOR  AH,AH
    MOV  [DI],AH
    INC  DI
    MOV  [DI],DL
    INC  DI
    ADD  CX,2
    RET
SAVENUM ENDP

SAVESG PROC
    MOV  [DI],AL
    INC  DI
    INC  CX
    RET
SAVESG ENDP

OPERATE PROC
    LEA  SI,EXP
    INC  SI
JUDGE:
    SUB  DI,3
    MOV  CL,[DI]
    CMP  CL,'*'
    JE   MPLY
    CMP  CL,'/'
    JE   DVS
    CMP  BYTE PTR[DI],'M'
    JE   P1
    JMP  JUDGE
MPLY:
    CALL MULTIPLY
    JMP  JUDGE
DVS:
    CALL DIVISION
    JMP  JUDGE
P1:
    MOV  AH,[SI]
    MOV  AL,[SI+1]
    MOV  RESULT,AX                ;将结果保存到AX
P2:
    ADD  SI,2
    MOV  CL,[SI]
    CMP  CL,'+'
    JE   AD
    CMP  CL,'-'
    JE   SBTC
AD:
    CALL ADDITION
    CMP  SI,OFFSET EXP+11
    JB   P2
    JMP  EDO
SBTC:
    CALL SUBTRACTION
    CMP  SI,OFFSET EXP+11
    JB   P2
EDO:
    RET
OPERATE ENDP

ADDITION PROC
    XOR  AX,AX
    XOR  BX,BX
    MOV  AX,RESULT
    INC  SI
    XCHG BH,[SI]
    XCHG BL,[SI+1]
    ADD  AX,BX
    MOV  RESULT,AX
    RET
ADDITION ENDP

SUBTRACTION PROC
    XOR  AX,AX
    XOR  BX,BX
    MOV  AX,RESULT
    INC  SI
    XCHG BH,[SI]
    XCHG BL,[SI+1]
    SUB  AX,BX
    MOV  RESULT,AX
    RET
SUBTRACTION ENDP

MULTIPLY PROC
    XOR  AX,AX
    XOR  BX,BX
    INC  DI
    XCHG BH,[DI]
    XCHG BL,[DI+1]
    SUB  DI,2
    XCHG AL,[DI]
    XCHG AH,[DI-1]
    MUL  BX
    MOV  [DI],AL
    MOV  [DI-1],AH
    INC  DI
    RET
MULTIPLY ENDP
   
DIVISION PROC
    XOR  AX,AX
    XOR  BX,BX
    INC  DI
    XCHG BH,[DI]
    XCHG BL,[DI+1]
    SUB  DI,2
    XCHG AL,[DI]
    XCHG AH,[DI-1]
    DIV  BX
    MOV  [DI],AL
    MOV  [DI-1],AH
    INC  DI
    
    PUSH AX
    PUSH CX
    PUSH DI
    MOV  AX,DX
    MOV  CX,100
    MUL  CX
    DIV  BX
    SUB  DI,3
    CMP  [DI],'+'
    JE   EDD
    CMP  [DI],'-'
    JE   NGD
    CMP  [DI],'*'
    JE   MLD
    CMP  BYTE PTR[DI],'M'
    JE   EDD
NGD:
    NEG  AX
    JMP  EDD
MLD:
    MUL  [DI-1]
EDD:
    ADD  RESULTP,AX
    POP  DI
    POP  CX
    POP  AX
    RET
DIVISION ENDP

OUTPUT PROC
    CALL SORT
    MOV  SI,OFFSET DIVISORS
    MOV  DI,OFFSET RESULT1                    
    MOV  CX,5  
    CMP  RESULT,0
    JGE  ONE
    NEG  RESULT
    MOV  DL,'-'
    MOV  AH,2                  
    INT  21H                             ;输出负号
    MOV  AX,RESULT
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
    MOV  DX,RESULTP
    ADD  DL,30H
    MOV  AH,2
    INT  21H                             ;输出一位小数
    RET
OUTPUT ENDP

SORT PROC
SORT ENDP

CODE ENDS
END MAIN
