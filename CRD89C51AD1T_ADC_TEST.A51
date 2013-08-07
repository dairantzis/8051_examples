;-----------------------------------------------------------------------------
; PROGRAM TO CTRL A CHARGE AMP, MEASURE ITS O/P AND TX IT TO THE SERIAL PORT
;
;
;  FILE NAME   :  UCL_CHARGE_AMP.A51
;  TARGET MCU  :  CRD89C51AD1T 
;
;-----------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------
; SFR DEFNs
;-----------------------------------------------------------------------------
;
P4		EQU	0E8H			  ;
P5		EQU	0D8H			  ;
                      ;
                      ;UART control registers
RCON		EQU	086H			;Internal RAM ctrl reg
S0CON		EQU	098H			;Serial port 0 ctrl reg
S0BUF		EQU	099H			;Serial port 0 shift reg
S0RELL		EQU 	0AAH			;Serial port 0 reload reg low
S0RELH		EQU 	0BAH			;Serial port 0 reload reg high
S1CON		EQU 	09BH			;Serial port 1 ctrl reg
;TI1		BIT	S1CON.1			;Serial port 1 transmit in process flag
;RI1		BIT	S1CON.0			;Serial port 1 received character is available
S1BUF		EQU 	09CH			;Serial port 1 shift reg
S1RELL		EQU 	09DH			;Serial port 1 reload reg low
S1RELH		EQU 	0BBH			;Serial port 1 reload reg high
						          ;
DPL1		EQU	084H			;Data pointer 1
DPH1		EQU	085H			;
                      ;
AUX		EQU	091H			  ;BRGS,P4CC,P4SPI,P4UR1,P4IIC,P0KBI,P2PWM,DPS 
AUX2		EQU	092H			;P42CC 
						          ;
						          ;Interrupt handling
IEN0		EQU	0A8H			;Enhanced Interrupt control register 0
IEN1		EQU	0B8H			;Enhanced Interrupt control register 1
IEN2		EQU	09AH			;Enhanced Interrupt control register 2
IP0		EQU	0A9H			  ;Enhanced Interrupt Priority control register 0
IP1		EQU	0B9H			  ;Enhanced Interrupt Priority control register 1
IRCON		EQU	0C0H			;Interrupt request control register 0
IRCON2		EQU	097H		;Interrupt request control register 2
						          ;
						          ;Watchdog control
WDTC		EQU	0B6H			;Watchdog control register
WDTK		EQU	0B7H			;Watchdog refresh key register
						;
						;GPIO mode control registers
P0M0		EQU 	0D2H			;
P0M1		EQU 	0D3H			;
P1M0		EQU 	0D4H			;
P1M1		EQU 	0D5H			;
P2M0		EQU 	0D6H			;
P2M1		EQU 	0D7H			;
P3M0		EQU 	0DAH			;
P3M1		EQU 	0DBH			;
P4M0		EQU 	0DCH			;
P4M1		EQU 	0DDH			;
P5M0		EQU 	0DEH			;
P5M1		EQU 	0DFH			;
						;
						;Reset ctrl registers
LVC		EQU 	0E6H			;LVI_EN,X,LVRXE
SWRES		EQU 	0E7H			;
						;
						;RTC ctrl registers
RTCDATA		EQU	09FH			;
RTCADDR		EQU	09EH			;
						;
						;OpAmp & Comparator ctrl registers
OpPin		EQU	0F6H			;
Cmp0CON		EQU	0FEH			;
Cmp1CON		EQU	0FFH			;
                                                ;
ADCC1           EQU     0ABH                    ;ADC module registers
ADCC2           EQU     0ACH                    ;
ADCDH           EQU     0ADH                    ;Result byte MSB
ADCDL           EQU     0AEH                    ;
ADCCS           EQU     0AFH                    ;ADC module clock source
ADCIF           BIT     IRCON.2                 ;
;
;
;-----------------------------------------------------------------------------
;       SYSTEM CT DEFNs
;-----------------------------------------------------------------------------
;
RESET_LOOP_CT       EQU 018H                    ;Constant to wait for 10usec, the time required for the integrating capacitor to discharge
HOLD_HALF_LOOP_CT   EQU 005H                    ;Constant to wait for 5usec, half of the time required during the pre-integration and the hold periods
INTEGRATION_LOOP_CT EQU 030H                    ;Constant to wait for the integration period.
MAXCOMT 	          EQU 5                	      ;Max nr of repetitions before timeout of comms rtne.
;
;-----------------------------------------------------------------------------
; 	SYSTEM BYTE VARIABLEs DEFNs
;-----------------------------------------------------------------------------
;
COMTIML 		        EQU 014H                            ;Comms timeout var.
COMTIMM 		        EQU 015H		
COMTIMH 		        EQU 016H		
;
;-----------------------------------------------------------------------------
;       SYSTEM BIT VARIABLEs DEFNs
;-----------------------------------------------------------------------------
;
TEMP                 BIT 20H.0                       
MEASURE              BIT 20H.1                       
S1                   BIT P3.2
S2                   BIT P3.3
BJT1                 BIT P3.4
BJT2                 BIT P3.5
ADC_INDICATOR        BIT P3.6

;
;-----------------------------------------------------------------------------
; RESET and INTERRUPT VECTORS
;-----------------------------------------------------------------------------
;

;
;-----------------------------------------------------------------------------
; MAIN PROGRAM
;-----------------------------------------------------------------------------
;
                      ORG 0000h			                  ;Reset Vector
						
START:         					
                    MOV SP,#60	                      ;Set the stack bottom @ 60 bytes from the bottom of the internal RAM.
						                                          ;
		LCALL INISER			                          ;Initialise the serial ports
    MOV A,#'S'                                  ;Send an 'S' char to let the user know that the s/w has started
    LCALL TXCHR                                 ;
    CLR MEASURE                                 ;Clear the MEASURE flag so as to cancel the continuous reading of the charge amplifier
		MOV P0,#0FFH			                          ;Make sure that all i/o pins are set.
		MOV P1,#0FFH			                          ;
		MOV P2,#0FFH			                          ;
                                                ;        
		MOV P3M0,#00111100B		                      ;Turn P3.4 (BJT1) and P3.5 (BJT2) into push pull o/p pins
		MOV P3M1,#00000000B		                      ;
                                                ;
		ORL IE,#0             		                  ;Global interrupt disable
    LCALL ADC_INI                               ;Iniitalise the ADC module
						;
CHECK_UART0:	JNB RI,CHECK_UART0_X		          ;Check UART1 status if nothing was received
		         MOV A,S0BUF			                  ;Read the byte in from UART0
		         CLR RI				
CHECK_UART0_N:					
                                                ;
CHECK_UART0_N0: CJNE A,#'0',CHECK_UART0_N1      ;

                SETB BJT1
                CLR BJT2
		            SJMP CHECK_UART0_XL		;When done, jump to the end of the UART0 rtne.
                                                ;
CHECK_UART0_N1: CJNE A,#'1',CHECK_UART0_NM      ;
                
                SETB BJT2
                CLR BJT1
                SJMP CHECK_UART0_XL		           ;When done, jump to the end of the UART0 rtne.
                                                ;
CHECK_UART0_NM: CJNE A,#'M',CHECK_UART0_X       ;                                                
                CPL MEASURE                     ;Toggle the MEASURE flag to start/stop the continuous measurement of the charge amplifier                                
                                                
CHECK_UART0_X:					                        ;
                JNB MEASURE,CHECK_UART0_XL      ;Skip the continuous measurement of the charge amp if the MEASURE flag is cleared.
                                                ;Continuous measurement of the charge amplifier.
                SETB BJT1                       ;Turn the 1st light source on. 
                LCALL CHARGE_AMP                ;Take a measurement off the charge amplifier
                                                ;
                LCALL TRANS_AMP                 ;Take a measurement off the transimpedance amplifier
                                                ;                
                MOV A,#44                       ;Tx a comma to the PC as a field separator
                LCALL TXCHR                     ;Send the char to the serial port.
                                                ;                      
                CLR BJT1                        ;Turn the 1st light source off.
                                                ;
                SETB BJT2                       ;Turn the 2nd light source on.                                               
                LCALL CHARGE_AMP                ;Take a measurement off the charge amplifier
                                                ;
                LCALL TRANS_AMP                 ;Take a measurement off the transimpedance amplifier
                                                ;
                MOV A,#10                       ;Tx the CR/LF sequence for the terminal to change line.
                LCALL TXCHR                     ;Send the char to the serial port.
                MOV A,#13                       ;
                LCALL TXCHR                     ; 
                                                ;                      
                CLR BJT2                        ;Turn the 2nd light source off.
                                                ;
CHECK_UART0_XL:	LJMP CHECK_UART0		            ;Done, now go to repeat the whole ctrl loop.   
                                                ;
                                                ;
CHARGE_AMP:                                     ;
                                                ;Reset the charge amplifier
                SETB S1                         ;Make sure that S1 switch is open, the sensor is disconnected.
                CLR S2                          ;Make sure that S2 switch is closed, the integrating capacitors are shorted.
                MOV B,#RESET_LOOP_CT            ;Wait for 10usec, the time required for the integrating capacitor to discharge
                DJNZ B,$                        ;
                SETB S2                         ;Make sure that S2 switch is open, releasing the integrating capacitors.
                                                ;
                                                ;Pre-integration hold period with possible sampling of offset voltage
                MOV B,#HOLD_HALF_LOOP_CT        ;Hold the charge amplifier for the first half of the holding period
                DJNZ B,$                        ;
                                                ;A measurement could place here as the offset o/p voltage
                                                ;  measurement.  This source of error accounts for the charge
                                                ;  injection of S2 opening/closing.                                              
                MOV B,#HOLD_HALF_LOOP_CT        ;Hold the charge amplifier for the second half of the holding period
                DJNZ B,$                        ;
                                                ;
                                                ;Integration phase
                CLR S1                          ;Make sure that S1 switch is closed, the sensor is connected.
                MOV B,#INTEGRATION_LOOP_CT      ;Delay enough time for the integration to be completed
                DJNZ B,$                        ;Keep on decrementing B while jumping to the same prog addr (simple delay loop).                            ;
                SETB S1                         ;Disconnect the sensor, the integration is now complete.
                                                ;
                LCALL ADC_MEAS0                 ;Measure ADC channel 0
                                                ;Tx the result to the PC
                MOV A,ADCDH                     ;Tx the MSB of the result first,
                LCALL TX2HEXCHR                 ;
                MOV A,ADCDL                     ;Tx the LSB of the result second.
                LCALL TX2HEXCHR                 ;
                                                ;
                MOV A,#44                       ;Tx a comma to the PC as a field separator
                LCALL TXCHR                     ;Send the char to the serial port.
                RET                             ;
                                                ;
TRANS_AMP:                                      ;
                LCALL ADC_MEAS1                 ;Measure channel 1 and Tx the result
                MOV A,ADCDH                     ;Tx the MSB of the result first,
                LCALL TX2HEXCHR                 ;
                MOV A,ADCDL                     ;Tx the LSB of the result second.
                LCALL TX2HEXCHR                 ;
                                                ;                
                MOV A,#44                       ;Tx a comma to the PC as a field separator
                LCALL TXCHR                     ;Send the char to the serial port.
                                                ;
                LCALL ADC_MEAS2                 ;Measure channel 2 and Tx the result
                MOV A,ADCDH                     ;Tx the MSB of the result first,
                LCALL TX2HEXCHR                 ;
                MOV A,ADCDL                     ;Tx the LSB of the result second.
                LCALL TX2HEXCHR                 ;
                RET                             ;
                                                ;
;
;-----------------------------------------------------------------------------------------------------------
;

;
;-----------------------------------------------------------------------------
;       SUBROUTINES TO SERVICE THE COMMS TIMEKEEPING FUNCTIONS
;-----------------------------------------------------------------------------
;
;
COMTCTI:	                        	;Initialize the comms timeout rtne.
	 	MOV COMTIML,#0
  	MOV COMTIMM,#0
  	MOV COMTIMH,#0
  	RET
;
;-----------------------------------------------------------------------------
;
COMTCTR:	                        	;Comms timeout rtne  (non interrupt based).
        	PUSH ACC
		CLR TEMP                	;Assume failure.
		INC COMTIML             	;Increase the var.
		MOV A,COMTIML
		CJNE A,#0,COMTCTX
 	  INC COMTIMM
   	MOV A,COMTIMM
   	CJNE A,#0,COMTCTX
		INC COMTIMH
		MOV A,COMTIMH
		CJNE A,#MAXCOMT,COMTCTX		;Compare and exit if not equal.
		SETB TEMP
COMTCTX: 	POP ACC
        	RET
;
;-----------------------------------------------------------------------------
;
ASCII2NUM: 					;Rtne to convert an ASCII hex code to an actual binary number.
          CJNE A,#48,ASCII2NUM_1
        	MOV A,#0
        	RET
ASCII2NUM_1: 	CJNE A,#49,ASCII2NUM_2
        	MOV A,#1
        	RET
ASCII2NUM_2: 	CJNE A,#50,ASCII2NUM_3
        	MOV A,#2
        	RET
ASCII2NUM_3: 	CJNE A,#51,ASCII2NUM_4
        	MOV A,#3
        	RET       
ASCII2NUM_4: 	CJNE A,#52,ASCII2NUM_5
        	MOV A,#4
        	RET
ASCII2NUM_5: 	CJNE A,#53,ASCII2NUM_6
        	MOV A,#5
        	RET
ASCII2NUM_6: 	CJNE A,#54,ASCII2NUM_7
        	MOV A,#6
        	RET
ASCII2NUM_7: 	CJNE A,#55,ASCII2NUM_8
        	MOV A,#7
        	RET
ASCII2NUM_8: 	CJNE A,#56,ASCII2NUM_9
        	MOV A,#8
        	RET
ASCII2NUM_9: 	CJNE A,#57,ASCII2NUM_A
        	MOV A,#9
        	RET     
ASCII2NUM_A: 	CJNE A,#65,ASCII2NUM_B
        	MOV A,#10
        	RET
ASCII2NUM_B: 	CJNE A,#66,ASCII2NUM_C
        	MOV A,#11
        	RET
ASCII2NUM_C: 	CJNE A,#67,ASCII2NUM_D
        	MOV A,#12
        	RET
ASCII2NUM_D: 	CJNE A,#68,ASCII2NUM_E
        	MOV A,#13
        	RET
ASCII2NUM_E: 	CJNE A,#69,ASCII2NUM_F
        	MOV A,#14
        	RET
ASCII2NUM_F: 	CJNE A,#70,ASCII2NUM_X
        	MOV A,#15
ASCII2NUM_X: 	RET
;
;-----------------------------------------------------------------------------
;
NUM2ASCII: 	     		           	;Convert a HEX nr to CHR and return it in A.
		PUSH DPH
		PUSH DPL                                                         
		MOV DPTR,#DIGTAB        
		MOVC A,@A+DPTR          
		POP DPL
		POP DPH
		RET
;
DIGTAB:  	DB        48,49,50      	;Data table converting a HEX nr to its ASCII CHR code.
		DB        51,52,53
		DB        54,55,56
		DB        57,65,66
		DB        67,68,69
		DB        70
;
;-----------------------------------------------------------------------------
;
HEX_DATA_2_DPTR:  				;Routine to translate two HEX bytes (sent in four characters MSn first, LSn second) MSB first, LSB second
						;into a 16 bit number returned into DPTR.
						;The HEX numbers are expected from PACKET_BUFFER+3 to PACKET_BUFFER+6
;		MOV R0,#PACKET_BUFFER+3       	;PACKET_BUFFER+3=MSn OF DPH
        	MOV A,@R0               	;PACKET_BUFFER+4=LSn OF DPH
        	INC R0
        	LCALL ASCII2NUM			;Convert the ASCII hex into a number
		SWAP A				;place it to the MSnibble
        	MOV B,A				;and keep a note of the result in B.
        	MOV A,@R0			;Read the next number (LSnibble)
        	INC R0
        	LCALL ASCII2NUM			;Convert the ASCII hex into a number
        	ADD A,B				;add the two results
        	MOV DPH,A			;and the end result is the DPH
        	MOV A,@R0			;Now repeat the process for the DPL
        	INC R0
        	LCALL ASCII2NUM            	;PACKET_BUFFER+5=MSn OF DPL
        	SWAP A                  	;PACKET_BUFFER+6=LSn OF DPL
        	MOV B,A
        	MOV A,@R0
        	INC R0
        	LCALL ASCII2NUM
        	ADD A,B
        	MOV DPL,A
	       	RET
;
;-----------------------------------------------------------------------------
;
HEX_DATA_2_BYTE:  				;Routine to translate one HEX byte (sent in two characters MSn first, LSn second) MSB first, LSB second
						;into an 8 bit number returned into A.
						;The HEX number is expected from the byte pointed by R0 and the byte next to it.
		PUSH B				;Save B
        	MOV A,@R0               	;R0 points to the MSn
        	INC R0
        	LCALL ASCII2NUM			;Convert the ASCII hex into a number
		SWAP A				;place it to the MSnibble
        	MOV B,A				;and keep a note of the result in B.
        	MOV A,@R0			;Read the next number (LSnibble)
        	INC R0
        	LCALL ASCII2NUM			;Convert the ASCII hex into a number
        	ADD A,B				;add the two results
        	POP B				;Restore B
	       	RET				;and return
;
;-----------------------------------------------------------------------------
;
TX2HEXCHR:					;Translate a byte into its hex characters equivalents and send them through the h/w serial port
						;Η ρτνα BYTE2HEXCHR παίρνει τον αριθμό, τον μεταφράζει σε HEX και τον αποθηκεύει σε δύο διαδοχικές θέσεις του R0 ο οποίος αυξάνεται αυτομάτως.
		PUSH ACC			;Keep a note of the number.
		PUSH ACC			;Keep a note of the number.
		SWAP A				;Retain the low nibble.
		ANL A,#00001111B
	        LCALL NUM2ASCII			;Translate the nibble into its ASCII character.
	        LCALL TXCHR			;Transmit the ASCII character through the h/w serial port.
		POP ACC				;Read the number back into the rtne.
		ANL A,#00001111B		;Keep the low nibble.
	        LCALL NUM2ASCII			;Translate the nibble into its ASCII character.
	        LCALL TXCHR			;Transmit the ASCII character through the h/w serial port.
		POP ACC				;Read the number back into the rtne.
		RET				;Return to the caller.
;
;-----------------------------------------------------------------------------
;
BYTE2HEXCHR:                        		;Translate a byte into its hex character equivalent and store its components to the position pointed by R0. R0 is then inc'd.
						;Η ρτνα BYTE2HEXCHR παίρνει τον αριθμό, τον μεταφράζει σε HEX και τον αποθηκεύει σε δύο διαδοχικές θέσεις του R0 ο οποίος αυξάνεται αυτομάτως.
		PUSH ACC			;Keep a note of the number.
		SWAP A				;Retain the low nibble.
		ANL A,#00001111B
	        LCALL NUM2ASCII			;Translate the nibble into its ASCII character.
	        MOV @R0,A			;Store it at the location pointed to by R0.
	        INC R0				;Point to the next available location.
		POP ACC				;Read the number back into the rtne.
		ANL A,#00001111B		;Keep the low nibble.
	        LCALL NUM2ASCII			;Translate the nibble into its ASCII character.
	        MOV @R0,A			;Store it at the location pointed to by R0.
	        INC R0				;Point to the next available location.
		RET				;Return to the caller.
;
;-----------------------------------------------------------------------------
;

;
;-----------------------------------------------------------------------------
;
ECHOCHR:
TXCHR:	                         		;Send the character to the serial port - non interrupt.
						;UART0 rtne.
TXCHR_0:  	LCALL RWATCH			;Keep the w/d running.
		ANL S0CON,#11101111B		;Disable serial reception on UART0 (in case the IR i/p channel picks up the transmission from the o/p channel)
		MOV SBUF,A			;Move the character into the serial buffer,
        	JNB TI,$			;and wait for the transmission process to be completed.
        	CLR TI				;Release the serial transmission cct.
		ORL S0CON,#00010000B		;Enable serial reception on UART0.
        	RET				;Return to the caller.
        					;
;
;-----------------------------------------------------------------------------
;
RXCHR:						;Rtne to wait for a chr to arrive at the serial port - non interrupt.
						;A timeout limit is imposed.
	        LCALL COMTCTI           	;Initialise the timeout counter.
RXCHRLP: 	
		LCALL RWATCH			;Keep the w/d running.
        	LCALL COMTCTR           	;Has the timeout period expired?
        	JNB TEMP,RXCHRPC
        	SJMP RXCHRPX            	;The timeout period has expired, exit from the rtne.
;                               
RXCHRPC:        				;
						;UART0 rtne
        	JNB RI,RXCHRLP          	;Repeat the loop if no chr arrived and not enough time has passed by.
        	CLR RI				;
        	MOV A,SBUF			;
						;				
RXCHRPX: 	RET				;
;
;-----------------------------------------------------------------------------
;
;TXCHR_SW:                         		;Send the character to the s/w serial port - non interrupt.
;	  	LCALL RWATCH			;Keep the w/d running.
;		MOV SW_TX_BUFFER,A		;Move the character into the serial buffer,
;		SETB SW_UART_TI			;get the s/w uart Tx cct running,
;        	JB SW_UART_TI,$			;and wait for the transmission process to be completed.
;        	RET				;Return to the caller.
;
;-----------------------------------------------------------------------------
;
;RXCHR_SW:					;Rtne to wait for a chr to arrive at the s/w serial port - non interrupt.
;						;A timeout limit is imposed.
;	        LCALL COMTCTI           	;Initialise the timeout counter.
;	        ;!!!!!!!! DO NOT RESET THE SW_RX_BUFFER REGISTER - THE RECEPTION PROCESS MIGHT AS WELL HAVE STARTED
;
;RXCHRLP_SW 	
;		LCALL RWATCH			;Keep the w/d running.
;        	LCALL COMTCTR           	;Has the timeout period expired?
;        	JNB TEMP,RXCHRPC_SW
;        	SJMP RXCHRPX_SW            	;The timeout period has expired, exit from the rtne.
;                               
;RXCHRPC_SW 	JNB SW_UART_RI,RXCHRLP_SW        ;Repeat the loop if no chr arrived and not enought time has passed by.
;        	CLR SW_UART_RI
;        	MOV A,SW_RX_BUFFER
;        	
;RXCHRPX_SW 	RET
;
;-----------------------------------------------------------------------------
;
DELLON: 	PUSH ACC                	;Long Delay.
		PUSH B
		MOV ACC,#255
DELLO1:  	MOV B,#50
DELLO2:  	LCALL RWATCH
		DJNZ B,DELLO2
		DJNZ ACC,DELLO1
		POP B
		POP ACC
		RET
;
;-----------------------------------------------------------------------------
;
;       Initialise the serial ports for 9600 BAUD,1 START BIT, 8 DATA BITS, 1 STOP bits
;	11,0592MHz crystal is assumed.
;
INISER:  					;
						;Initialise port 0 first
        	CLR TI				;Make sure that UART0 engine is reset
        	CLR RI				;
                
                
        	
        	;!!!!! DO NOT USE S0REL TO CTRL UART0
        	; IT SEEMS THAT THE TX/RX CLOCKS ARE NOT 
        	; GENERATED IN A SIMILAR MANNER AND THE
        	; RESULT IS THAT TX/RX OPERATE AT DIFFERENT
        	; SPEEDS.
        	; USE TIMER1 INSTEAD
        					;
;		MOV S0RELH,#002H		;Set the reload value of S0REL for 1200 baud
;		MOV S0RELL,#0E0H		;
;		MOV S0RELH,#001H		;Set the reload value of S0REL for 600 baud
;		MOV S0RELL,#0C0H		;
;		ORL AUX,#080H			;BRS = 1

		ANL AUX,#01111111B		;BRS = 0
		
		ORL TMOD,#20H			;Set Timer1 to operate as an 8bit autoreload timer      
                MOV TH1,#0FAH     		;
                MOV TL1,#0FAH     		;
		ORL PCON,#80H 			;SMOD =1     
		MOV SCON,#52H
		ORL TCON,#40H			;Enable Timer1 to run

;		ANL PCON,#01111111B		;SMOD =0


						;ATTENTION!!!! THE SETTING FOR 600 BAUD RESULTED
						;  IN 1200 BAUD!!!! THE ONLY WAY OUT OF THE PROBLEM
						;  WAS TO CANCEL THE DOUBLE RATE THAT SMOD=1 IMPLIES
						;  RESULTING TO 600 BAUD.
;		ORL IEN0,#090H			;EA=1, ES0=1, interrupt enable
		MOV S0CON,#050H			;Set UART0 to mode 1, SM20=0, and enable the device
						;
						;Initialise port 1 second
        	ANL S1CON,#11111100B		;Make sure that UART1 engine is reset (clear RI1, TI1)
        	ANL AUX,#1110111B		;Clear bit P4UR1 to move UART1 to P1
;		MOV S1RELH,#002H		;Set the reload value of S0REL for 1200 baud
;		MOV S1RELL,#0E0H		;
		MOV S1RELH,#001H		;Set the reload value of S0REL for 600 baud
		MOV S1RELL,#0C0H		;
		MOV S1CON,#0B0H			;d_mode_B, SM21 =1, REN1 =1
        					;
;		ORL TCON,#00000100B		;Set the INT0 & INT1 as an edge triggered interrupt
;		ORL IE,#00000100B		;Enable the INT0 so as to enable Rxing through the sw uart Rx engine.
						;
		RET

;
TIMER0_INIT:					;Initialise TIMER0 and its interrupt
						;Timer1 pending flag:TF1(TCON.7),enable:ET1(IE.3)
						;Bottom 4 bit of TMOD control Timer0
		ANL TMOD,#11110010B		;Timer0 is active when TR0 is active,incremented by T0M (CKON.4),mode2 (8bit timer/counter with auto-reload),top nibble is unaffected.
		ORL TMOD,#00000010B		;
						;
        	MOV TH0,#0D0H     		;This value will make Timer 0 to overflow 19200 times per second.
		MOV TL0,#0D0H			;This will ensure a 256 step PWM rolling 25 times a second.
		ORL TCON,#10H			;Enable Timer0 to run
		ORL IE,#10000010B		;Enable global interrupts and the Timer0 interrupt in particular.
		RET				;
						;
;
TIMER1_INIT:					;Initialise TIMER1 and its interrupt
						;Timer1 pending flag:TF1(TCON.7),enable:ET1(IE.3)
						;Top 4 bit of TMOD control Timer1
		MOV A,TMOD			;Move the current contents of TMOD for processing
		ANL A,#00101111B		;Timer1 is active when TR1 is active,incremented by T1M (CKON.4),mode2 (8bit timer/counter with auto-reload),bottom nibble is unaffected.
		ORL A,#00100000B		;
		MOV TMOD,A      		;
						;
        	MOV TH1,#0D0H     		;This value will make Timer 1 to overflow 19200 times per second.
		MOV TL1,#0D0H			;This will ensure a 256 step PWM rolling 25 times a second.
		ORL TCON,#40H			;Enable Timer1 to run
		ORL IE,#10001000B		;Enable global interrupts and the Timer1 interrupt in particular.
		RET				;
						;
;
RWATCH:		RET				;Routine to reset the watchdog
;
						;
;
;-----------------------------------------------------------------------------
;
ADC_INI:                                        ;Rtne to initialise the ADC module.
                MOV ADCC1,#00000111B            ;Set bit 0 to enable channels 0 & 1 of the ADC module.
                MOV ADCCS,#00011111B            ;Set the ADC clock to system clock / 64.
                RET                             ;
                                                ;
ADC_MEAS0:                                      ;Rtne to measure channel 0 of the ADC.
                CLR ADC_INDICATOR               ;Indicator line brought low to flag the a/d process => measure how long it takes
                CLR ADCIF                       ;Clear the ADC data ready flag.
                MOV ADCC2,#07Fh                 ;Stop any conversion that may be taking place
                MOV ADCC2,#11000000B            ;Select channel 0, right adjust the result and start the conversion.
                JNB ADCIF,$                     ;Wait for the conversion to be completed.
                SETB ADC_INDICATOR              ;
                RET                             ;and return to the caller.
                                                ;
ADC_MEAS1:                                      ;Rtne to measure channel 1 of the ADC.
                CLR ADC_INDICATOR               ;Indicator line brought low to flag the a/d process => measure how long it takes
                CLR ADCIF                       ;Clear the ADC data ready flag.
                MOV ADCC2,#07Fh                 ;Stop any conversion that may be taking place
                MOV ADCC2,#11000001B            ;Select channel 1, right adjust the result and start the conversion.
                JNB ADCIF,$                     ;Wait for the conversion to be completed.
                SETB ADC_INDICATOR              ;
                RET                             ;and return to the caller.
                                                ;    
ADC_MEAS2:                                      ;Rtne to measure channel 1 of the ADC.
                CLR ADC_INDICATOR               ;Indicator line brought low to flag the a/d process => measure how long it takes
                CLR ADCIF                       ;Clear the ADC data ready flag.
                MOV ADCC2,#07Fh                 ;Stop any conversion that may be taking place
                MOV ADCC2,#11000010B            ;Select channel 1, right adjust the result and start the conversion.
                JNB ADCIF,$                     ;Wait for the conversion to be completed.
                SETB ADC_INDICATOR              ;
                RET                             ;and return to the caller.
                                                ;    
                                                
                                                                                            
;
;-----------------------------------------------------------------------------
;
VEREK:  	DB 'E:0.001 20120719',0
MANUF:  	DB 'UCL MEDICAL PHYSICS',0
;
               END
