;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
; HEX conversion routines to/from ASCII characters and nibbles/bytes
; Current version: 30/03/2020
;
; Subroutines available:
;  
;HEXBYTE2DPTR:                        		        ;Translate a byte into its hex equivalent and  
;                                                       ; store its components at the position 
;                                                       ; pointed by DPTR.
;                                                       ;
;HEX_NIBBLE_2_CHR:                                      ;Convert a HEX nibble to its equivalent ASCII hex character code and return it in A.
;                                                       ;
;HEX_CHR_2_NIBBLE:                                      ;Rtne to convert an ASCII hex character code to its equivalent HEX nibble and return it in A.
;                                                       ;
;HEX_CHRS_IN_IRAM_2_BYTE:                               ;Convert the bytes pointed to by R0 in internal RAM, MSB first, LSB second, to a byte returned in A.
;                                                       ;R0 is increased and returned pointing to the next location in IRAM.
;                                                       ;
;HEX_BYTE_2_TWO_CHR:                                    ;Convert a byte into nibbles & pass it on to HEXCHR for storage/handling
;                                                       ;
;TX_HEX_BYTE_2_SER_WITH_2_CHR:                          ;Transmit a hex byte to the serial port, in the form of two 
;                                                       ;
;STORE_HEX_BYTE_IN_IRAM_WITH_TWO_CHR:                   ;Store a hex byte in internal RAM, in the form of two chars
;                                                       ; MSB first, LSB second, starting at the locn pointed to
;                                                       ; by R0.  Inc R0 to point to the next available locn.
;                                                       ;
;GET_MS_NIBBLE:          ANL ACC,#11110000B             ;Zero LSnibble & bring MSnibble at its place.
;                                                       ;
;GET_LS_NIBBLE:          ANL ACC,#00001111B             ;Zero the MSnibble of the byte, result in Acc.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
HEXBYTE2DPTR:                        		        ;Translate a byte into its hex equivalent and  
;                                                       ; store its components at the position 
;                                                       ; pointed by DPTR.
                        PUSH ACC			;Keep a note of the number.
                        LCALL GET_MS_NIBBLE             ;Isolate the MS nibble
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
                        MOVX @DPTR,A			;Store it at the location pointed to by DPTR.
                        INC DPTR			;Point to the next available location.
                        POP ACC				;Read the number back into the rtne.
                        LCALL GET_LS_NIBBLE             ;Isolate the LS nibble
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
                        MOVX @DPTR,A			;Store it at the location pointed to by DPTR.
                        INC DPTR			;Point to the next available location.
                        RET				;Return to the caller.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
HEX_NIBBLE_2_CHR:                                       ;Convert a HEX nibble to its equivalent ASCII hex character code and return it in A.
                        PUSH DPH                        ;
                        PUSH DPL                        ;                                 
                        MOV DPTR,#DIGTAB                ;
                        MOVC A,@A+DPTR                  ;
                        POP DPL                         ;
                        POP DPH                         ;
                        RET                             ;
                                                        ;
DIGTAB:                 DB        48,49,50              ;Data converting a HEX nr to a CHR code.
                        DB        51,52,53              ;
                        DB        54,55,56              ;
                        DB        57,65,66              ;
                        DB        67,68,69              ;
                        DB        70                    ;
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
;HEX2AS: 	                                        ;
HEX_CHR_2_NIBBLE:                                       ;Rtne to convert an ASCII hex character code to its equivalent HEX nibble and return it in A.
                        CJNE A,#48,HEX2AS1		;
                        MOV A,#0                        ;
                        RET                             ;
HEX2AS1:                CJNE A,#49,HEX2AS2              ;
                        MOV A,#1                        ;
                        RET                             ;
HEX2AS2:                CJNE A,#50,HEX2AS3              ;
                        MOV A,#2                        ;
                        RET                             ;
HEX2AS3:                CJNE A,#51,HEX2AS4              ;
                        MOV A,#3                        ;
                        RET                             ;
HEX2AS4:                CJNE A,#52,HEX2AS5              ;
                        MOV A,#4                        ;
                        RET                             ;
HEX2AS5:                CJNE A,#53,HEX2AS6              ;
                        MOV A,#5                        ;
                        RET                             ;
HEX2AS6:                CJNE A,#54,HEX2AS7              ;
                        MOV A,#6                        ;
                        RET                             ;
HEX2AS7:                CJNE A,#55,HEX2AS8              ;
                        MOV A,#7                        ;
                        RET                             ;
HEX2AS8:                CJNE A,#56,HEX2AS9              ;
                        MOV A,#8                        ;
                        RET                             ;
HEX2AS9:                CJNE A,#57,HEX2ASA              ;
                        MOV A,#9                        ;
                        RET                             ;
HEX2ASA:                CJNE A,#65,HEX2ASB              ;
                        MOV A,#10                       ;
                        RET                             ;
HEX2ASB:                CJNE A,#66,HEX2ASC              ;
                        MOV A,#11                       ;
                        RET                             ;
HEX2ASC:                CJNE A,#67,HEX2ASD              ;
                        MOV A,#12                       ;
                        RET                             ;
HEX2ASD:                CJNE A,#68,HEX2ASE              ;
                        MOV A,#13                       ;
                        RET                             ;
HEX2ASE:                CJNE A,#69,HEX2ASF              ;
                        MOV A,#14                       ;
                        RET                             ;
HEX2ASF:                CJNE A,#70,HEX2AS_FAIL          ;
                        MOV A,#15                       ;
HEX2ASX:                RET                             ;
HEX2AS_FAIL:            MOV A,#0                        ;
                        RET                             ;
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
HEX_CHRS_IN_IRAM_2_BYTE:                                ;Convert the bytes pointed to by R0 in internal RAM, MSB first, LSB second, to a byte returned in A.
;                                                       ;R0 is increased and returned pointing to the next location in IRAM.
                        PUSH B                          ;We'll need B in the process, save it for later
                        MOV A,@R0                       ;Read the first HEX char (MSB) in A
                        INC R0                          ;Get R0 ready to point to the next IRAM location
                        LCALL HEX_CHR_2_NIBBLE          ;Convert the ASCII hex character code to its equivalent HEX nibble and return it in A.
                        SWAP A                          ;Since this was the char describing the MS nibble, bring the 
                                                        ;  LS nibble into the position of the MS nibble
                        MOV B,A                         ;and store the result onto B for later use.
                        MOV A,@R0                       ;Read the second HEX char (LSB) in A
                        INC R0                          ;Get R0 ready to point to the next IRAM location
                        LCALL HEX_CHR_2_NIBBLE          ;Convert the ASCII hex character code to its equivalent HEX nibble and return it in A.
                        ADD A,B                         ;Add the LS nibble with the MS nibble and store the result in A
                        POP B                           ;Restore B, as it was used in the process
                        RET                             ;Return to the caller, holding the result in A
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
HEX_BYTE_2_TWO_CHR:                                     ;Convert a byte into nibbles & pass it on to HEXCHR for storage/handling
                        PUSH ACC                        ;
                        LCALL GET_MS_NIBBLE             ;Handle the high nibble first.
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
                        POP ACC                         ;
                        LCALL GET_LS_NIBBLE             ;Handle the low nibble second.
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
                        RET                             ;
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
;TXHBYTE:
TX_HEX_BYTE_2_SER_WITH_2_CHR:                           ;Transmit a hex byte to the serial port, in the form of two 
                                                        ; chars MSB first, LSB second.
                        PUSH ACC                        ;Take a note of the byte to be stored into internal RAM.
                        LCALL GET_MS_NIBBLE             ;Isolate the MS nibble
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
        		LCALL TX_CHAR                   ;Transmit the character through the serial port
                        POP ACC                         ;Restore the byte to be stored into internal RAM.
TX_HEX_NIBBLE_2_SER_WITH_1_CHR:                         ;2nd part of the routine to work on the LSnibble
                        LCALL GET_LS_NIBBLE             ;Isolate the LS nibble
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
        		LCALL TX_CHAR                   ;Transmit the character through the serial port
                        RET                             ;Done, return to the caller.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
;STORE_HEX_BYTE:
STORE_HEX_BYTE_IN_IRAM_WITH_TWO_CHR:                    ;Store a hex byte in internal RAM, in the form of two chars
;                                                       ; MSB first, LSB second, starting at the locn pointed to
;                                                       ; by R0.  Inc R0 to point to the next available locn.
                        PUSH ACC                        ;Take a note of the byte to be stored into internal RAM.
                        LCALL GET_MS_NIBBLE             ;Isolate the MS nibble
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
                        MOV @R0,A                       ;Store it at the internal RAM locn pointed to by R0
                        INC R0                          ;Increase R0.
                        POP ACC                         ;Restore the byte to be stored into internal RAM.
STORE_HEX_NIBBLE_IN_IRAM_WITH_ONE_CHR:                  ;Store a hex nibble stored in the lower nibble of A, in internal RAM, in the form of one char
;STORE_HEX_BYTE_L:                                       ;2nd part of the routine to work on the LSnibble
                        LCALL GET_LS_NIBBLE             ;Isolate the LS nibble
                        LCALL HEX_NIBBLE_2_CHR		;Translate the nibble into its ASCII character.
                        MOV @R0,A                       ;Store it at the internal RAM locn pointed to by R0
                        INC R0                          ;Increase R0.
                        RET                             ;Done, return to the caller.
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
;HINIBL:                                                 ;
GET_MS_NIBBLE:          ANL ACC,#11110000B              ;Zero LSnibble & bring MSnibble at its place.
                        SWAP A                          ;
                        RET                             ;
                                                        ;
;LONIBL:                                                 ;
GET_LS_NIBBLE:          ANL ACC,#00001111B              ;Zero the MSnibble of the byte, result in Acc.
                        RET                             ;
;                                                       ;
;--------1---------2----+----3---------4---------5------+--6----+----7---------8---------9---------A---------B---------C---------D---------E---------F
;                                                       ;
                                                        ;ÔÝëïò, êáé ôù Èåþ Äüîá...