DATA SEGMENT
WCMSTR    DB "Please input a simple expression(only contain +,-,*,\)",0AH,0DH,'$'
OUTSTR    DB "S=",'$'
ERRSTR    DB 0AH,0DH,"error",0AH,0DH,'$'
EXP       DB 'M'
          DW 20 DUP(0)
DIVISORS  DW 10000, 1000, 100, 10, 1
RESULT1   DB 0,0,0,0,0,"$"               ;存放整数部分五位数ASCII码 
RESULT    DW 0                           ;整数部分
RESULTP   DW 0                           ;小数部分
SWITCH    DW 0                           ;0为正,1为负
SIGNAL    DW 0                           ;0为正,1为负
ALLNUM    DW ?                           ;符号和数字的总数             
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
    MOV  ALLNUM,DI
    CALL OPERATE 
    DISP OUTSTR 
    MOV  DX,0
    CALL OUTPUT    
EXIT:
    MOV  AX,4C00H
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
    RET
SAVENUM ENDP

SAVESG PROC
    MOV  [DI],AL
    INC  DI
    RET
SAVESG ENDP

OPERATE PROC
    LEA  SI,EXP
    INC  SI
    LEA  DI,EXP
JUDGE:
    ADD  DI,3
    MOV  CL,[DI]
    CMP  CL,'*'
    JE   MPLY
    CMP  CL,'/'
    JE   DVS
    CMP  DI,ALLNUM
    JGE  P1
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
    MOV  RESULT,AX                       ;将结果保存到AX
P2:
    ADD  SI,2
    MOV  CL,[SI]
    CMP  CL,'+'
    JE   SWT0
    CMP  CL,'-'
    JE   SWT1
    JMP  JDS
SWT0:
    MOV  SWITCH,0
    JMP  JDS
SWT1:
    MOV  SWITCH,1
JDS:
    CMP  SWITCH,0
    JNE  SBTC
AD:
    CALL ADDITION
    CMP  SI,ALLNUM
    JB   P2
    JMP  EDO
SBTC:
    CALL SUBTRACTION
    CMP  SI,ALLNUM
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
    INC  DI
    MOV  [DI+2],AL
    MOV  [DI+1],AH    
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
    DIV  BL
    INC  DI 
    MOV  [DI+2],AL
    XCHG AL,AH
    XOR  AH,AH
    MOV  [DI+1],AH

    PUSH AX
    PUSH CX
    PUSH DI
    MOV  CX,100
    MUL  CL
    DIV  BL
    XOR  AH,AH
DAG:
    ADD  DI,3
    MOV  CL,[DI]
    CMP  CL,'*'
    JNE  DPP
    MOV  CL,[DI+2]
    MOV  CH,[DI+1]
    MUL  CX
    JMP  DAG    
DPP:
    POP   DI
    PUSH  DI  
AGD:
    SUB  DI,3
    MOV  CL,[DI]
    CMP  CL,'+'
    JE   EDD
    CMP  CL,'-'
    JE   NGD
    CMP  BYTE PTR[DI],'M'
    JE   EDD
    JMP  EDD
NGD:   
    NEG  AX
EDD:    
    ADD  RESULTP,AX
    POP  DI
    POP  CX
    POP  AX       
    RET
DIVISION ENDP

OUTPUT PROC
    CMP  RESULTP,0
    JE   NT
    CALL SORT
NT:
    MOV  SI,OFFSET DIVISORS
    MOV  DI,OFFSET RESULT1                    
    MOV  CX,5  
    CMP  RESULT,0
    JG   ON
    JE   JSG
    JL   NGO
JSG:
    CMP  SIGNAL,0
    JE   ON
NGO:
    NEG  RESULT
    MOV  DL,'-'
    MOV  AH,2                  
    INT  21H                             ;输出负号
ON:
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
    INT  21H
    MOV  DL,BYTE PTR RESULTP             ;输出小数点
    ADD  DL,30H
    MOV  AH,2
    INT  21H
    RET
OUTPUT ENDP

SORT PROC                               
    XOR  DX,DX 
    MOV  AX,RESULTP
    CMP  RESULTP,0 ;小数部分为正
    JL   S1
    MOV  CX,100
    DIV  CL
    XCHG AH,DL
    ADD  RESULT,AX
    XOR  DH,DH
    MOV  RESULTP,DX                      ;使小数部分为小于100的有符号数
    CMP  RESULT,0                        ;检查整数部分是否为负，为负，则用100减去小数部分
    JGE  FFR
    MOV  SIGNAL,1
    NEG  RESULT
    SUB  RESULT,1
    NEG  RESULT
    SUB  CX,RESULTP
    MOV  AX,CX
    MOV  RESULTP,AX
FFR:
    MOV  AX,RESULTP
    MOV  CX,10
    DIV  CL
    CMP  AH,5                            ;四舍五入
    JL   EDS
    INC  AL
EDS: 
    XOR  AH,AH
    MOV  RESULTP,AX
    RET
S1:                                      ;小数部分为负
    NEG  AX
    MOV  CX,100
    DIV  CL
    XCHG AH,DL
    SUB  RESULT,AX
    XOR  DH,DH
    MOV  RESULTP,DX                      ;使小数部分为小于100的有符号数,小数部分仍为负数
    MOV  SIGNAL,1
    CMP  RESULT,0                        ;检查整数部分是否为正，为正，则用100减去小数部分
    JLE  FFR
    MOV  SIGNAL,0
    SUB  RESULT,1
    SUB  CX,RESULTP
    MOV  AX,CX
    MOV  RESULTP,AX
    JMP  FFR 
SORT ENDP

CODE ENDS
END MAIN
