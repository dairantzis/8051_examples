;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
; CRC calculation routines 
; Current version: 30/03/2020
;
; Subroutines available:
;                                                       ; refer to Dallas Semi databook for details.
;                                                       ;
;CRC16:                                                 ;Calculate new CRC16 with incoming byte in the accumulator
;                                                       ;
;CRC8:                                                  ;Calculate new CRC8 with incoming byte in the accumulator
;                                                       ; refer to Dallas Semi databook for details.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;
CRC_HI                  EQU 20H                         ;High byte of CRC16 calculation (must be bit addressable)
CRC_LO                  EQU 21H                         ;Low byte of CRC16 calculation (must be bit addressable)
CRC                     EQU 22H                         ;CRC8 byte
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;
; CRC16 subroutine.
; - accumulator is assumed to have byte to be crc’ed
; - two direct variables are used crc_hi and crc_lo
; - crc_hi and crc_lo contain the CRC16 result
;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
CRC16:                                                  ;Calculate new CRC16 with incoming byte in the accumulator
                                                        ; refer to Dallas Semi databook for details.
                        PUSH B                          ;Save the value of B
                        MOV B,#08h                      ;Number of bits to crc.
CRC_GET_BIT:            RRC A                           ;Get low order bit into carry
                        PUSH ACC                        ;Save A for later use
                        JC CRC_IN_1                     ;Got a 1 input to crc
                        MOV C,CRC_LO.0                  ;XOR with a 0 input bit is bit
                        SJMP CRC_CONT                   ;continue
                                                        ;
CRC_IN_1:               MOV C,CRC_LO.0                  ;XOR with a 1 input bit
                        CPL C                           ;Complement the bit.
                                                        ;
CRC_CONT:               JNC CRC_SHIFT                   ;If carry is set, just shift
                        CPL CRC_HI.6                    ;Complement bit 15 of crc
                        CPL CRC_LO.1                    ;Complement bit 2 of crc
                                                        ;
                                                        ;Carry is now calculated
CRC_SHIFT:              MOV A,CRC_HI                    ;Process CRC_HI
                        RRC A                           ;Rotate CRC_HI through carry
                        MOV CRC_HI,A                    ; and save it
                        MOV A,CRC_LO                    ;Process CRC_LO
                        RRC A                           ;Rotate CRC_LO through carry
                        MOV CRC_LO,A                    ; and save it
                        POP ACC                         ;Restore ACC
                        DJNZ B,CRC_GET_BIT              ;Repeat the process for the next bit
                        POP B                           ;Restore B
                        RET                             ;Return to caller
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
CRC8:                                                   ;Calculate new CRC8 with incoming byte in the accumulator
                                                        ; refer to Dallas Semi databook for details.
                        PUSH ACC                        ;
                        PUSH B                          ;
                        PUSH ACC                        ;
                        MOV B,#8                        ;
CRC_LP:                 XRL A,CRC                       ;
                        RRC A                           ;
                        MOV ACC,CRC                     ;
                        JNC ZERO                        ;
                        XRL A,#18H                      ;
ZERO:                   RRC A                           ;
                        MOV CRC,A                       ;
                        POP ACC                         ;
                        RR A                            ;
                        PUSH ACC                        ;
                        DJNZ B,CRC_LP                   ;
                        POP ACC                         ;
                        POP B                           ;
                        POP ACC                         ;
                        RET                             ;Return to caller
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6---------7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
                        