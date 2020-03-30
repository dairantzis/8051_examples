; Program file to introduce the Special Function Registers unique to the CRD89C51AD1T
;;
;
;**************************************************************
;*** CRD89C51AD1T REGISTER DEFINITION 
;**************************************************************
;
;*** ISP SPECIFIC SFR LOCATIONS (CONSTANTS)***
						;
TAKEY		EQU 0F7H			;Timed Access Key Register
IFCON		EQU 08FH			;Interface Control Register
ISPFC  		EQU 0E4H			;ISP Flash control
ISPFD		EQU 0E3H			;ISP Flash Data
ISPFAL		EQU 0E2H			;ISP Flash Address Low
ISPFAH		EQU 0E1H			;ISP Flash Address High
						;
                                                ;
SCONF		EQU 0BFh			;SYStem CONtrol register
SYSCON		EQU 0BFH			;WDR,n/u,n/u,n/u,DFLASHE,IAPE,XRAME,ALEI
;
WDTWREN		EQU 097H
;
P4		EQU 0D8H
;
TH2		EQU 0CDH
TL2		EQU 0CCH
CRCH    	EQU 0CBH
CRCL    	EQU 0CAH
T2CON		EQU 0C8H
;
IE_1		EQU 0A9H
IP1		EQU 0B9H
IRCON           EQU 0C0H
;
SPWMD3		EQU 0A7H
SPWMD2		EQU 0A6H
SPWMD1		EQU 0A5H
SPWMD0		EQU 0A4H
SPWMC		EQU 0A3H
;
WDTC		EQU 09FH
WDTKEY		EQU 097H
;
P1CON		EQU 09BH
;
RCON		EQU 085H
;
;
                END        
