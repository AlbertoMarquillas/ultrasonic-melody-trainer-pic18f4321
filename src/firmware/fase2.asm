;**********
;CAPÇALERES   
;**********
LIST P=PIC18F4321 F=INHX32
#include <p18f4321.inc>

;**************
;CONFIGURACIONS 
;**************
CONFIG OSC = HSPLL    ; 40MHz
CONFIG PBADEN = DIG   ; PORTB
CONFIG WDT = OFF 

;**********
;VARIABLES
;**********
FLAGS EQU 0x0001 ;Flags per avisar a les interrupcions
NUM_NOTES EQU 0x0002
LECTURA EQU 0x0003
COMPT_ESPERA_ACK EQU 0x0004;Comptador per generar ACK
NOTA_LLEGIDA EQU 0x0005
DURATION_LLEGIDA EQU 0x0006
COMPTADOR_3S_L EQU 0x0007
COMPTADOR_3S_H EQU 0x0008
FLAGS_INT EQU 0x0009 ;Flgs que venen de les interrupcions
COMPTADOR_500MS_L EQU 0x000A
COMPTADOR_500MS_H EQU 0x000B
COMPT_ESPERA_TRIGGER EQU 0x000C ;Comptador per generar trigger
COMPTADOR_DURATION_H EQU 0x000D
COMPTADOR_DURATION_L EQU 0x000E
COMPT_ACK EQU 0X000F
COMPT_CM EQU 0X0010
COMPT_ESPERA_60US EQU 0X0011
NOTA_TROBADA EQU 0X0012
COMPTADOR_2S_L EQU 0x0013
COMPTADOR_2S_H EQU 0x0014
COMPTADOR_TRIGGER EQU 0x0015
TICKS_ALTAVEU EQU 0x0016
PWM_ALTAVEU EQU 0x0017
DC_ALTAVEU EQU 0x0018
NOTES_CORRECTES_AUX EQU 0x0019
COMPT_ESPERA_11US EQU 0x0020
GARUS_AUX EQU 0X0021
GRAUS EQU 0X0022
INTERRUPCIONS_FLASH EQU 0X0023
NOTES_CORRECTE EQU 0X0024
NOTES_CORRECTES EQU 0X0025
QUANTITAT_GRAUS EQU 0X0026
NUM_NOTES_AUXILIAR EQU 0X0027
FI_20MS EQU 0x0028
 

TAULA EQU 0X0060
 
;******************************
;VECTORS DE RESET I INTERRUPCIÓ 
;******************************
ORG 0x000
GOTO MAIN
ORG 0X0008
GOTO HIGH_RSI
ORG 0X0018
RETFIE FAST

ORG TAULA
DB .0, .180, .90, .60, .45
DB .36, .30, .26, .23, .20
DB .18, .16, .15, .14, .13
DB .12, .11
;------------------------------------MAIN------------------------------------
;------------------------------------FUNCIONS CONFIGURACIÓ------------------------------------

;**********************
;CONFIGURACIÓ DE PORTS  
;**********************
CONFIG_PORTS
    ;PORT A -> Pins analògics: RA0, RA1, RA2, RA3, RA5; Pins d'oscil·lador: RA6, RA7
    BCF TRISA,0,0   ; Sortida  --  Length_0 (Led)
    BCF TRISA,1,0   ; Sortida  --  Length_1 (Led)
    BCF TRISA,3,0   ; Sortida  --  Answer Correct (Led RA3)
    BCF TRISA,4,0   ; Sortida  --  Answer Incorrect (Led RA4)
    
    BCF TRISA,2,0   ; Sortida  --  Trigger (Ultrasons)
    BCF TRISA,5,0   ; Sortida  --  GameScore (Servo)
    ;Pins RA6, RA7 no s'utilitzen per HSPLL
    
    ;PORT B - Entrades -> Pins d'interrupció: RB0, RB1, RB2 ; Pins analògics: RB0, RB1, RB2, RB3, RB4
    BSF TRISB,0,0   ; Entrada --  NewNote (Ve de la F1)
    BSF TRISB,1,0   ; Entrada --  StartGame (Ve de la F1)
    BSF TRISB,2,0   ; Entrada --  Echo (Ultrasons)
    
    ;PORT C
    BSF TRISC,0,0   ; Entrada - Note_0 (ve de la F1)
    BSF TRISC,1,0   ; Entrada - Note_1 (ve de la F1)
    BSF TRISC,2,0   ; Entrada - Note_2 (ve de la F1)
    BSF TRISC,3,0   ; Entrada - Note_3 (ve de la F1)
    BSF TRISC,4,0   ; Entrada - Duration_0 (ve de la F1)
    BSF TRISC,5,0   ; Entrada - Duration_1 (ve de la F1)
    BCF TRISC,6,0   ; Sortida - ACK (va cap a la F1)
    BCF TRISC,7,0   ; Sortida - Speaker
    
    ;PORT D
    CLRF TRISD,0    ; Sortida - CurrentNote[7..0] (Seven segments)
    
    RETURN
    
;******************
;INICIALITZAR PORTS  
;******************
INIT_PORTS         ; Init sortides dels ports
    CLRF LATA,0    ; Netejem sortides PORTA (TOT SORTIDES)
    BCF LATC,6,0   ; Netejem el ACK
    BCF LATC,7,0   ; Netejem el PWM Speaker
    CLRF LATD,0    ; Netejem Seven Segments (CurrentNote[7..0])
    
    RETURN

;***********************
;INICIALITZAR VARIABLES 
;***********************
INIT_VARS
    BCF FLAGS, 0, 0 ;Posem a 0 el bit 0 de la variable Flags -> Indica quan el joc ha començat (START GAME ES ACTIU)
    BCF FLAGS, 1, 0 ;Posem a 0 el bit 1 de la variable Flags -> Indica que s'han de comptar 3 segons
    BCF FLAGS, 2, 0 ;Posem a 0 el bit 2 de la variable Flags -> Indica quan s'ha de fer algo amb el servo
    BCF FLAGS, 3, 0 ;Posem a 0 el bit 3 de la variable Flags -> Indica quan s'ha de fer algo amb l'altaveu
    BCF FLAGS, 4, 0 ;Posem a 0 el bit 4 de la variable Flags -> Indica quan s'han de comptar 500ms
    BCF FLAGS, 5, 0 ;Posem a 0 el bit 4 de la variable Flags -> Indica quan s'han de comptar DURACIO
    BCF FLAGS, 7, 0 ;Posem a 0 el bit 4 de la variable Flags -> Indica quan s'ha de comptar temps de TRIGGER

    CLRF NUM_NOTES
    CLRF LECTURA 
    CLRF COMPT_ESPERA_ACK ;Comptador per generar ACK
    CLRF NOTA_LLEGIDA 
    CLRF DURATION_LLEGIDA 
    CLRF COMPTADOR_3S_L 
    CLRF COMPTADOR_3S_H 
    CLRF COMPTADOR_500MS_L  
    CLRF COMPTADOR_500MS_H  
    CLRF COMPT_ESPERA_TRIGGER   ;Comptador per generar trigger
    CLRF COMPTADOR_DURATION_H  
    CLRF COMPTADOR_DURATION_L  
    CLRF COMPT_ACK  
    CLRF COMPT_CM  
    CLRF COMPT_ESPERA_60US  
    CLRF NOTA_TROBADA  
    CLRF COMPTADOR_2S_L  
    CLRF COMPTADOR_2S_H  
    CLRF COMPTADOR_TRIGGER  
    CLRF TICKS_ALTAVEU  
    CLRF PWM_ALTAVEU  
    CLRF DC_ALTAVEU  
    CLRF NOTES_CORRECTES_AUX  
    CLRF COMPT_ESPERA_11US  
    CLRF GARUS_AUX  
    CLRF GRAUS  
    CLRF INTERRUPCIONS_FLASH  
    CLRF NOTES_CORRECTE  
    CLRF NOTES_CORRECTES  
    CLRF QUANTITAT_GRAUS  
    CLRF NUM_NOTES_AUXILIAR  

    BCF FLAGS_INT, 0, 0 ;Posem a 0 el bit 0 de la variable Flags_Int -> Indica quan s'han comptat els 3 segons    
    BCF FLAGS_INT, 1, 0 ;Posem a 0 el bit 1 de la variable Flags_Int -> Indica quan s'ha comptat duracio
    BCF FLAGS_INT, 3, 0 ;Posem a 0 el bit 3 de la variable Flags_Int -> Indica quan s'han comptat els 500 milisegons

    SETF PORTD ;Netejem tot el port D per no encende el display 7-segments
    RETURN
    
;****************************
;CONFIGURACIÓ D'INTERRUPCIONS  
;****************************
CONFIG_INTERRUPTS
    ; Activar Interrupcions
    BSF INTCON,7,0   ; Unmasked
    BSF INTCON,6,0   ;High
    ; Activo interrupció RB0 i indico que es per flanc de baixada (NewNote)
    BSF INTCON, INT0IE,0    ; Activo interrupció RB0
    BCF INTCON2, INTEDG0,0  ; Indico flanc de baixada
    ;Activo interrupció RBI (StartGame)
    BSF INTCON3, INT1IE, 0  ; Activo interrupció RB1
    ;Activo interrupció TMR0
    BSF INTCON, TMR0IE, 0   ; Activo interrupció TMR0
    
    RETURN
    
;*****************
;INICIALITZAR RAM
;*****************
PUNTER_RAM
    MOVLW .1
    MOVWF FSR0H,0   ; Inicialitzar al banc 1 el punter d'escriptura de la RAM
    CLRF FSR0L,0    ; Inicialitzar el punter a l'adreça 0
    
    MOVLW .1
    MOVWF FSR1H,0   ; Incialitzar al banc 1 el punter de lectura de la RAM
    CLRF FSR1L,0    ; Inicialitzar el punter a l'adreça 0
    
    RETURN

;**************************
;CARREGAR EL VALOR DE TMR0
;**************************
CARREGA_TMR0
    
    MOVLW HIGH(.60536) ;Primer carreguem High
    MOVWF TMR0H, 0
    MOVLW LOW(.60536) ;Despres carreguem low
    MOVWF TMR0L, 0
    RETURN
    
;*****************
;INICIALITZAR TMR0
;*****************
INIT_TMR0
    ;Tint=(4/Fosc)Preescarler(2^Bits - L)
    ;500us=(4/40M) * 256 * (2^16 - L) = 65516,46875
    ;Preescaler=246, Bits=16
    
    ;500us=(4/40M) * 1 * (2^16 - L) -> L = 60536
    MOVLW b'10001000'
    ;Bit 7: Enables TMR0
    ;Bit 6: Timer 8/16 bit (16)
    ;Bit 5: CLKO
    ;Bit 4: High-To-Low
    ;Bit 3: Not preescaler output
    ;Bit 2-0: Prescale value
    MOVWF T0CON, 0
    RETURN
;------------------------------------FUNCIONS INIT COMPTADORS------------------------------------
;**********************************
;INICIALITZAR COMPTADOR DE 500MS
;**********************************
INIT_COMPT_500MS
	;Interrupcions de 500u per aribar a 500ms -> 500ms/500us = 1000
	;2 registres 65535
	;1000 d = 0011 1110 1000 b
	MOVLW HIGH(.1000)
	MOVWF COMPTADOR_500MS_H, 0
	MOVLW LOW(.1000)
	MOVWF COMPTADOR_500MS_L, 0

	RETURN
;*************************************************
;INICIALITZAR COMPTADOR DE 1 SEGON PER LA DURACIO
;*************************************************
INIT_COMPT_1S_DURATION
	;Interrupcuins de 500u per arribar a 3s -> 2s/500us = 2000
	;2 registres 65535
	MOVLW HIGH(.2000)
	MOVWF COMPTADOR_DURATION_H, 0
	MOVLW LOW(.2000)
	MOVWF COMPTADOR_DURATION_L, 0
    
	RETURN
;**************************************************
;INICIALITZAR COMPTADOR DE 2 SEGONS PER LA DURACIO
;**************************************************
INIT_COMPT_2S_DURATION
	;Interrupcuins de 500u per arribar a 3s -> 2s/500us = 4000
	;2 registres 65535
	MOVLW HIGH(.4000)
	MOVWF COMPTADOR_DURATION_H, 0
	MOVLW LOW(.4000)
	MOVWF COMPTADOR_DURATION_L, 0
    
	RETURN
;**************************************************
;INICIALITZAR COMPTADOR DE 3 SEGONS PER LA DURACIO
;**************************************************
INIT_COMPT_3S_DURATION
	;Interrupcuins de 500u per arribar a 3s -> 3s/500us = 6000
	;2 registres 65535
        ;6000 d = 0001 0111 0111 0000 b
	MOVLW HIGH(.6000)
	MOVWF COMPTADOR_DURATION_H, 0
	MOVLW LOW(.6000)
	MOVWF COMPTADOR_DURATION_L, 0
    
	RETURN
INIT_COMPT_2S
	;Interrupcuins de 500u per arribar a 3s -> 2s/500us = 4000
	;2 registres 65535
	MOVLW HIGH(.4000)
	MOVWF COMPTADOR_2S_H, 0
	MOVLW LOW(.4000)
	MOVWF COMPTADOR_2S_L, 0
    
	RETURN
;**********************************
;INICIALITZAR COMPTADOR DE 3 SEGONS
;**********************************
INIT_COMPT_3S
	;Interrupcuins de 500u per arribar a 3s -> 3s/500us = 6000
	;2 registres 65535
        ;6000 d = 0001 0111 0111 0000 b
	MOVLW HIGH(.6000)
	MOVWF COMPTADOR_3S_H, 0
	MOVLW LOW(.6000)
	MOVWF COMPTADOR_3S_L, 0
	
	BCF FLAGS_INT, 0, 0
	BSF FLAGS, 1, 0 ;FLAGS<1>=Comptar 3 Segons
    
	RETURN
	
;------------------------------------FUNCIONS COMPTADORS------------------------------------
;****************
;FUNCIO QUE COMPTA 1000 CICLES MAQUINA
;****************
COMPTA_ACK ;Espera 2ms
    ;Tosc = 1 / 40M = 25ns
    ;Cicle màquina = 4*Tosc = 4*25ns = 100ns
    ;Cicles=2m/100ns=20000 (20 REPETICIONS DE 1000 CICLES)
    MOVLW .124 ;1CICLE
    MOVWF COMPT_ESPERA_ACK, 0 ;1CICLE
    LOOP_ESPERA_ACK
	;1000 - 6 = 994
	;3x + 5nops (DINS DEL BUCLE) = 8X = 994 
	NOP 
	NOP
	NOP
	NOP
	NOP

	DECFSZ COMPT_ESPERA_ACK, 1, 0 ;3CICLES
	GOTO LOOP_ESPERA_ACK ;2CICLES
    RETURN
    
COMPTA_1000_CICLES
    MOVLW .110
    MOVWF COMPT_ESPERA_ACK,0
    LOOP_ESPERA_1000
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	DECFSZ COMPT_ESPERA_ACK,1,0
	GOTO LOOP_ESPERA_1000
    
RETURN
    
;*****************
;COMPTAR 3 SEGONS
;*****************
COMPTAR_3S   
	
    DECF COMPTADOR_3S_L,1,0
    BTFSC STATUS,C,0
    RETURN
    
    DECF COMPTADOR_3S_H,1,0
    BTFSC STATUS,C,0
    RETURN
    
    BSF LATA, 4, 0 ;Activo Led incorrecte
    BCF FLAGS, 4, 0 ;Desactiva 500ms
    BCF LATA, 3, 0;Apagar led correcte
    
    BSF FLAGS_INT, 0, 0 ;Poso a 1 el bit 0 de la variable Flags_Int, indicant que ja he comptat 3s
    BCF FLAGS, 1, 0 ;Poso a 0 el flag de comptar 3 segons
    RETURN

;*****************
;COMPTAR 500MS
;*****************
COMPTAR_500MS
    DECF COMPTADOR_500MS_L,1,0
    BTFSC STATUS,C,0
    RETURN
    DECF COMPTADOR_500MS_H,1,0
    BTFSC STATUS,C,0
    RETURN
    
    ;AQUI HAN PASSAT 500MS
    ;3 opcions -> 
    ;1. 500ms, comencem duracio
    ;2. 3s, no 500ms ;Comptador 3s (fet)
    ;3. Nota incorrecte (durant 500ms), ultasons para comptatge
    
    BCF FLAGS, 1, 0 ;Poso a 0 el Flag de 3s
    
    BCF LATA, 3, 0 
    BCF LATA, 4, 0
    
    BSF FLAGS, 5, 0 ;Activo TM0 Duracio
    
    MOVLW .1
    SUBWF DURATION_LLEGIDA, 0, 0
    BTFSC STATUS, Z, 0
    CALL INIT_COMPT_1S_DURATION
    
    MOVLW .2
    SUBWF DURATION_LLEGIDA, 0, 0
    BTFSC STATUS, Z, 0
    CALL INIT_COMPT_2S_DURATION

    
    MOVLW .3
    SUBWF DURATION_LLEGIDA, 0, 0
    BTFSC STATUS, Z, 0
    CALL INIT_COMPT_3S_DURATION

    
    
    
    BSF FLAGS_INT, 3, 0 ;Poso a 1 el bit 1 de la variable Flags_Int, indicant que ja he comptat 500usS
    BCF FLAGS, 4, 0; Posem a 0 el flag que indica que s'han de comptar els 500ms

    RETURN 

;*****************
;COMPTAR DURATION
;*****************
COMPTAR_DURATION   
	
    DECF COMPTADOR_DURATION_L,1,0
    BTFSC STATUS,C,0
    RETURN
    
    DECF COMPTADOR_DURATION_H,1,0
    BTFSC STATUS,C,0
    RETURN
    
    ;Ja ha passat duration
    
    BSF LATA, 3, 0 ;Activo led correcte
    INCF NOTES_CORRECTES, 1, 0
    
    BSF FLAGS_INT, 0, 0 ;Ho he de mirar -> per acabar
    BCF FLAGS, 5, 0 ;Desactivo el propi comptador
    BSF FLAGS_INT, 1, 0 ;Poso a 1 el bit 1 de la variable Flags_Int, indicant que ja he comptat DURATION
    RETURN
;------------------------------------FUNCIONS ESPERES------------------------------------

;**********************************
;COMPTAR 1CM
;**********************************
ESPERA_60US
	;Compto 60us perque cada cm son uns 60us
	;velocitat del so = 343m/s
	;dist = vel * t = 343m/s*t
	;L'ultrasons retorna la ditancia calculada d'anada i tornada, per tant dist hauria de ser 2dist
	;dist=(vel * t)/2 = (343m/s * t) / 2
	;Si dist=1cm=0.01m -> t = (0.01 * 2)/343 = 58.3us ~ 60us
	
	;Tosc = 1 / 40M = 25ns
	;Cicle màquina = 4*Tosc = 4*25ns = 100ns
	;Cicles= 60us/100ns=600
	MOVLW .198
	MOVWF COMPT_ESPERA_60US, 0 
	LOOP_ESPERA_60US ;600 - 6 = 594
	    ;3X = 595 -> x = 198
	    DECFSZ COMPT_ESPERA_60US, 1, 0
	    GOTO LOOP_ESPERA_60US
	RETURN
;************************************
;ESPERA PER LA GENERACIÓ DEL TRIGGER
;************************************
ESPERA_GENERAR_TRIGGER
    ;Tosc = 1 / 40M = 25ns
    ;Cicle màquina = 4*Tosc = 4*25ns = 100ns
    ;Cicles= 10us/100ns=100
    MOVLW .32 ;1CICLE
    MOVWF COMPT_ESPERA_TRIGGER, 0 ;1CICLE
    LOOP_ESPERA_TRIGGER ;100 - 4 = 96
	;3x = 96 -> X = 32
	DECFSZ COMPT_ESPERA_TRIGGER, 1, 0 ;3CICLES
	GOTO LOOP_ESPERA_TRIGGER ;2CICLES
    RETURN	

;********************************************
;ESPERA A QUE ES MOSTRI BE EL LED INCORRECT
;********************************************
ESPERA_INCORRECT
    ;Esperar 2s
    CALL INIT_COMPT_2S
    
    LOOP_2S
	DECF COMPTADOR_DURATION_L,1,0
	BTFSC STATUS,C,0
	GOTO LOOP_2S

	DECF COMPTADOR_DURATION_H,1,0
	BTFSC STATUS,C,0
	GOTO LOOP_2S
    RETURN

;------------------------------------FUNCIONS PEL FINAL DE L'EXECUCIO------------------------------------
;*****************************************
;FUNCIO AMB UN BUCLE INFINIT AMB EL FINAL
;*****************************************
MOSTRA_FINAL
    MOVLW b'11111101'
    MOVWF LATD, 0
    BCF FLAGS, 3, 0 ;Desactivar Altaveu
    BCF LATC, 7, 0;Apagar altaveu
    LOOP_MOSTRA_FINAL
        BSF FLAGS, 2, 0
        CLRF INTERRUPCIONS_FLASH
	BSF LATA, 5, 0
	CALL ESPERA_SERVO
	BCF LATA, 5, 0
	LOOP_ESPERA_SERVO
	    BTFSC FLAGS, 2, 0
	    GOTO LOOP_ESPERA_SERVO
	GOTO LOOP_MOSTRA_FINAL
	
	
    RETURN
;------------------------------------FUNCIONS PER NOTA OK------------------------------------
NOTA_IGUALS
    ;NO COMPTANT 500MS && NO ESTIC COMPTATNT DURACIO -> COMENÇO A COMPTAR 500MS
    
    BTFSS FLAGS, 4, 0 ;Flag de 500ms
    CALL NO_500MS
    RETURN
    
    NO_500MS
	BTFSS FLAGS, 5, 0 ;Flag de comptar duració
	BSF FLAGS, 4, 0 ;Activo 500ms
	CALL INIT_COMPT_500MS
    
    RETURN
;------------------------------------FUNCIONS PER NOTA KO------------------------------------
;********************************************
;FUNCIO QUE S'EXECUTA EN EL CAS DE LA FALLAR
;********************************************
NOTA_KO
    ;Si estic comptant 500ms, paro el comptador de 500ms
    ;Si estic comptant la duracio, paro el comptador de duracio, activo el led incorrecte 
    ;i vaig a la proxima nota -> Activar flag_int
    
    BTFSC FLAGS, 4, 0;Flag comptar 500ms
    ;Si esta actiu, parar el comptador de 500ms
    BCF FLAGS, 4, 0; Flag comptar 500ms
    
    BTFSC FLAGS, 5, 0;Flag per duracio (temps que he d'estar donant la nota correcte)
    CALL INTERROMP_DURACIO
    RETURN
    
    INTERROMP_DURACIO
	BCF FLAGS, 5, 0 ; DESACTIVO EL COMPTADOR DE DURACIO
	BSF LATA, 4, 0 ;ACTIVO LED INCORRECTE
	BCF LATA,3,0
	;CALL ESPERA_INCORRECT
	;BCF LATA, 4, 0
	BSF FLAGS_INT, 0, 0 ;ACTIVO FLAGS INT PER FER LA SEGUENT NOTA
     
    RETURN
;------------------------------------FUNCIONS ULTRASONS------------------------------------
;******************************
;GENERAR TRIGGER PER ULTRASONS
;******************************
GENERAR_TRIGGER
    BSF LATA, 2, 0 ;Activo el bit 2 del port A, on esta conectat el trigger
    CALL ESPERA_GENERAR_TRIGGER ;M'ha d'esperar 10us
    BCF LATA, 2, 0
    RETURN 
;------------------------------------FUNCIONS START GAME------------------------------------
NOTA_0_ULTRASONS
    MOVLW .0
    MOVWF NOTA_TROBADA
    MOVLW .1
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_1_ULTRASONS
    MOVLW .1
    MOVWF NOTA_TROBADA
    MOVLW .2
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_2_ULTRASONS
    MOVLW .2
    MOVWF NOTA_TROBADA
    MOVLW .3
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_3_ULTRASONS
    MOVLW .3
    MOVWF NOTA_TROBADA
    MOVLW .4
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_4_ULTRASONS
    MOVLW .4
    MOVWF NOTA_TROBADA
    MOVLW .5
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_5_ULTRASONS
    MOVLW .5
    MOVWF NOTA_TROBADA
    MOVLW .6
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_6_ULTRASONS
    MOVLW .6
    MOVWF NOTA_TROBADA
    MOVLW .7
    MOVWF DC_ALTAVEU
    GOTO FINAL_ECHO
NOTA_ERRONIA
    MOVLW .255
    MOVWF NOTA_TROBADA
    BCF FLAGS, 3, 0;Apaga interrupcio altaveu
    BCF LATC, 7, 0;Apaga altaveu
    GOTO FINAL_ECHO

;**********************************************
;FUCNIÓ PER ACTIVAR L'INTERRUPCIO DE L'ALTAVEU
;**********************************************
ACTIVA_ALTAVEU
    BSF FLAGS, 3, 0
    RETURN
;******************************
;TROBAR NOTA RETORNADA PER L'ECHO
;******************************
TROBAR_NOTA
    CALL ACTIVA_ALTAVEU
    MOVLW .10 ;NOTA MES PETITA QUE 10
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_0_ULTRASONS    
    ;compt - 10 >= 0 -> Status (C) = 1
    ;Compt > 10 -> Salto
    ;Compt < 10 -> No salto
    
    MOVLW .20
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_1_ULTRASONS
    
    MOVLW .30
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_2_ULTRASONS
    
    MOVLW .40
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_3_ULTRASONS
    
    MOVLW .50
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_4_ULTRASONS
    
    MOVLW .60
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_5_ULTRASONS
    
    MOVLW .70
    SUBWF COMPT_CM, 0, 0
    BTFSS STATUS, C, 0
    GOTO NOTA_6_ULTRASONS
    
    MOVLW .70
    SUBWF COMPT_CM, 0, 0
    BTFSC STATUS, C, 0
    GOTO NOTA_ERRONIA
    
    FINAL_ECHO
	;Mirar si la nota es correcte
	MOVF NOTA_LLEGIDA, 0, 0
	SUBWF NOTA_TROBADA, 0, 0
	BTFSC STATUS, Z, 0
	CALL NOTA_IGUALS
	
	MOVF NOTA_LLEGIDA, 0, 0
	SUBWF NOTA_TROBADA, 0, 0
	BTFSS STATUS, Z, 0
	CALL NOTA_KO
	
    RETURN
    
INIT_COMPTADOR_TRIGGER
    ;Interrupcuins de 500u per arribar a 100ms -> 100ms/500us = 200
    MOVLW .200
    MOVWF COMPTADOR_TRIGGER, 0
    BSF FLAGS, 7, 0 ;Flag comptador trigger
    LOOP_ESPERA_INIT_TRIGGER
	DECFSZ COMPTADOR_TRIGGER, 1, 0
	GOTO LOOP_ESPERA_INIT_TRIGGER
    RETURN
    
ESPERA_TRIGGER
    DECF COMPTADOR_TRIGGER,1,0
    BTFSC STATUS,C,0
    RETURN
    
    ;Aqui ja hauràn passat els 100ms
    BCF FLAGS, 7, 0
    RETURN
    
    
;************************************
;ESPERA EL TEMPS PER DETECTAR LA NOTA
;************************************
ESPERAR_TEMPS
    ;1. Hagin passat 3s
    ;2. duracio correcte (1, 2, 3 s)
    ;3. durant la duracio s'hagi mogut la ma (duracio incorrecte)
    LOOP_MOSTRAR_DURATION
	BSF FLAGS, 2, 0
	CLRF INTERRUPCIONS_FLASH
	BSF LATA, 5, 0
	CALL ESPERA_SERVO
	BCF LATA, 5, 0

	;Fer ultrasons
	;Interrupcio Echo (Flanc de pujada)
	;enerar flanc i esperar resposta
	CLRF COMPT_CM
	
	CALL GENERAR_TRIGGER ;Pot donar problemes (es fa cada 20ms, la podriem fer cada 5periodes si dones error)
	LOOP_ESPERAR_ULTRASONS
	    ;1. RB2 amb echo
 	    BTFSC PORTB, 2, 0 ;Miro si RB2 (Echo) es actiu -> indica que hi ha eco
	    GOTO REBRE_NOTA ;Si hi ha echo vaig a rebre la nota
	    ;2. 3s && !RB2 -> Flag_int s'ha activat
	    BTFSC FLAGS_INT, 0, 0 ;Comprobo si FLAG_INT<0>=1
	    GOTO FINAL; Si FLAG_INT<0>=1 vol dir que han passat 3 segons, per tant ja no seguim comptant
	    
	    BTFSS FLAGS, 2, 0 ;(Si han passat 20ms vol dir que no rebem res del echo)
	    GOTO LOOP_MOSTRAR_DURATION
	    
	    GOTO LOOP_ESPERAR_ULTRASONS
	    REBRE_NOTA
		;COMPTAR CM I DECODIFICAR NOTA
		CALL ESPERA_60US ;Espero 60us
		INCF COMPT_CM, 1, 0
		BTFSC PORTB, 2, 0 ;Mirar que RB2 (Echo) encara estigui actiu
		;INCREMENTAR COMPTADOR CADA CMD QUE PASSI FINS QUE ECHO SIGUI 0 (PORTB2 = 0)
		;HAN PASSAT 60US I PORTB2=1, SUMO 1CM (BUCLE FINS QUE JA NO, PORTB2=0)
		GOTO REBRE_NOTA
		;PORTB2 = 0
		;VEURE QUINA NOTA ES
		CALL TROBAR_NOTA
		;DESPRES GESTIO DE LEDS
		LOOP_ESPERA_SERVO_ULTRASONS
		    BTFSC FLAGS, 2, 0 ;Esperar 20ms del periode del servo
		    GOTO LOOP_ESPERA_SERVO_ULTRASONS
	BTFSS FLAGS_INT, 0, 0 ;Miro el flag que genera la meva interrupció
	GOTO LOOP_MOSTRAR_DURATION ;Esto lo he de mirar bien
    FINAL
    BCF FLAGS_INT, 0, 0 ;Poso a 0 el flag per poder tornar a comptar
    RETURN
;****************************
;MOSTRAR NOTA PEL 7-SEGMENTS
;****************************
MOSTRAR_NOTA
	; Màscara per agafar només la nota
	MOVLW b'00001111'
	ANDWF NOTA_LLEGIDA, 1, 0          ; Apliquem la màscara i guardem la nota
	; Comprovar quina nota és
	MOVLW b'00000000'          ; Posem un 0 al w
	SUBWF NOTA_LLEGIDA, 0, 0   ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 0
	CALL NOTA_0

	MOVLW b'00000001'          ; Posem un 1 al w
	SUBWF NOTA_LLEGIDA, 0, 0   ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 1
	CALL NOTA_1

	MOVLW b'00000010'          ; Posem un 2 al w
	SUBWF NOTA_LLEGIDA, 0, 0   ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 2
	CALL NOTA_2

	MOVLW b'00000011'          ; Posem un 3 al w
	SUBWF NOTA_LLEGIDA, 0, 0   ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 3
	CALL NOTA_3

	MOVLW b'00000100'          ; Posem un 4 al w
	SUBWF NOTA_LLEGIDA, 0, 0   ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 4
	CALL NOTA_4

	MOVLW b'00000101'          ; Posem un 5 al w
	SUBWF NOTA_LLEGIDA, 0, 0      ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 5
	CALL NOTA_5

	MOVLW b'00000110'          ; Posem un 6 al w
	SUBWF NOTA_LLEGIDA, 0, 0   ; Restem per comparar
	BTFSC STATUS, Z, 0         ; Si STATUS = 0 -> SALTA; Si STATUS = 1 -> NOTA_LLEGIDA = 6
	CALL NOTA_6
	
	RETURN
	
;**************************
;MOSTRAR DURACIÓ PELS LEDS
;**************************
MOSTRAR_LEDS
	; Apliquem màscara per quedar-nos amb la duració
	MOVLW b'00110000'		   ; Màscara
	ANDWF DURATION_LLEGIDA, 1, 0       ; Apliquem màscara i guardem a la mateixa variable
	
	RRNCF DURATION_LLEGIDA, 1, 0
	RRNCF DURATION_LLEGIDA, 1, 0
	RRNCF DURATION_LLEGIDA, 1, 0
	RRNCF DURATION_LLEGIDA, 1, 0

	; Comprovo els valors del led
	MOVLW .1                      ; Comprovem si és 1
	SUBWF DURATION_LLEGIDA, 0, 0             ; Restem la nota llegida i el w (comparar)
	BTFSC STATUS, Z, 0             ; si és igual -> STATUS = 1
	CALL LED_1
	
	MOVLW .2                      ; Comprovem si és 2
	SUBWF DURATION_LLEGIDA, 0, 0             ; Restem la nota llegida i el w (comparar)
	BTFSC STATUS, Z, 0             ; si és igual -> STATUS = 1
	CALL LED_2
	
	MOVLW .3                      ; Comprovem si és 3
	SUBWF DURATION_LLEGIDA, 0, 0             ; Restem la nota llegida i el w (comparar)
	BTFSC STATUS, Z, 0             ; si és igual -> STATUS = 1
	CALL LED_3
	
	RETURN
	
;******************
;NOTES (7-SEGMENTS)
;******************
; El 7-segments funciona per lògica negativa
NOTA_0
	MOVLW b'10000010'              ; Combinació per mostrar un 0 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_1
	MOVLW b'11001111'              ; Combinació per mostrar un 1 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_2
	MOVLW b'10010001'              ; Combinació per mostrar un 2 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_3
	MOVLW b'10000101'              ; Combinació per mostrar un 3 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_4
	MOVLW b'11001100'              ; Combinació per mostrar un 4 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_5
	MOVLW b'10100100'              ; Combinació per mostrar un 5 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_6
	MOVLW b'10100000'              ; Combinació per mostrar un 6 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
NOTA_7
	MOVLW b'10001111'              ; Combinació per mostrar un 7 pel 7-seg
	MOVWF LATD, 0                  ; Carreguem el valor al port de sortida
	RETURN                          ; Tornem a l'execució de StartGame per mirar els LEDS
	
;**************
;DURACIÓ (LEDS)
;**************
LED_1
    BSF LATA, 0, 0         ; Activem length_0
    BCF LATA, 1, 0         ; Desactivem lenght_1
    RETURN                  ; Tornem a l'execució de StartGame
	
LED_2
    BCF LATA, 0, 0         ; Activem length_0
    BSF LATA, 1, 0         ; Desactivem lenght_1
    RETURN                  ; Tornem a l'execució de StartGame
    
LED_3
    BSF LATA, 0, 0         ; Activem length_0
    BSF LATA, 1, 0         ; Desactivem lenght_1
    RETURN                  ; Tornem a l'execució de StartGame
;*********************************
;COMPROVAR SI HI HA NOTES A LA RAM  
;*********************************
COMPROVAR_NOTES
	; Mirem si la variable Num_Notes = 0
	MOVLW .0
	SUBWF NUM_NOTES,0,0
	BTFSC STATUS, Z, 0    ; Si STATUS = 0 -> Saltara; Si Num_Notes = 0 -> STATUS = 1
	GOTO RAM_BUIDA_END    ; Si la RAM és buida no continuem amb el programa
	
	RETURN
	
GET_GRAUS
    MOVFF NUM_NOTES,NUM_NOTES_AUXILIAR
    LOOP_GRAUS_FLASH
        TBLRD*+
        DECFSZ NUM_NOTES_AUXILIAR,1,0
        GOTO LOOP_GRAUS_FLASH
    TBLRD*
    MOVFF TABLAT,GRAUS
RETURN
;***********
;START GAME  
;***********
START_GAME
    CALL VES_FLASH
    CALL GET_GRAUS
    BSF FLAGS, 2, 0
    ; Comprovar si hi ha notes
    CALL COMPROVAR_NOTES
    LOOP_START_GAME
	; Llegim la posició
	MOVF POSTINC1, 0, 0       ; Movem el registre al work
	MOVWF NOTA_LLEGIDA, 0
	MOVWF DURATION_LLEGIDA, 0
	; Mostrem la nota al 7-segments
	CALL MOSTRAR_NOTA
	; Mostrem la duració als leds
	CALL MOSTRAR_LEDS
	;Comptar 3s amb el tmr0 -> Indco amb un flag
	;Activar una flag
	CALL INIT_COMPT_3S
	CALL ESPERAR_TEMPS

	; Comprovar si hi ha notes per llegir
	MOVF NUM_NOTES, 0, 0   ; Movem num_notes al w
	SUBWF FSR1L,0, 0       ; Restem el número de notes al punter de lectura de la RAM
	BTFSS STATUS, Z, 0   ; Comprovem -> STATUS = 1 : Són iguals -> Si son iguals vol dir que s'ha acabat
	GOTO LOOP_START_GAME
	
    RAM_BUIDA_END
	CALL MOSTRA_FINAL
	GOTO RAM_BUIDA_END
	
	RETURN
;------------------------------------FUNCIONS NEW NOTE------------------------------------
;****************
;ESPERA PER L'ACK
;****************    
ESPERA_ACK
    MOVLW .20
    MOVWF COMPT_ACK, 0
    LOOP_ACK
	CALL COMPTA_ACK
	DECFSZ COMPT_ACK, 1, 0
	GOTO LOOP_ACK
    RETURN
    

;************
;ACTIVAR ACK  
;************
ACTIVAR_ACK
    BSF LATC,6,0      ; Activem ACK (RC6)
    
    CALL ESPERA_ACK   ; Ens hem d'esperar perquè la fase 1 detecti ACK ;2CICLES
    
    BCF LATC,6,0      ; Desactivem ACK (RC6)
    
    RETURN

;*****************
;GUARDAR NOTA RAM 
;*****************
GUARDAR_NOTA_RAM
    MOVFF NUM_NOTES, FSR0L    ;Movem el punter d'escriptura de la RAM per escriure una nota nova -> el banc sempre és 1
    ; Màscara per guardar Nota[3..0] : Duration[1..0]
    MOVFF PORTC, LECTURA
    MOVLW b'00111111'
    ANDWF LECTURA,0,0           ; Multipliquem la màscara pel portc i guardem el resultat a w
    ; Guardem la nota
    MOVWF POSTINC0,0         ; Escriure RAM (FSR1)
    
    RETURN
;------------------------------------FUNCIONS INTERRUPCIONS------------------------------------
;****************
;SERVOMOTOR
;****************
SERVO
    ;calcular servo
    ;quantitat totals de notes -> NUM_NOTES
    ;Notes correctes -> necesito una variable
    ;Agafo el valor del servo de la flash (num_notes/valor flash = graus minims)
    ;faig un move d'aquell graus minims * notes correctes al servo -> Necesito una altra varaible
    
    INCF INTERRUPCIONS_FLASH, 1, 0
    MOVLW .40 ;20ms/500us = 40
    SUBWF INTERRUPCIONS_FLASH, 0, 0
    BTFSS STATUS, Z, 0
    RETURN
    
    ;Han passat 20ms
    
    BCF FLAGS, 2, 0
    
    RETURN
    
ESPERA_SERVO
    CALL ESPERA_05MS
    MOVLW .0
    SUBWF NOTES_CORRECTES,0,0
    BTFSC STATUS,Z,0
    RETURN 
    
    ;Hi ha notes correctes (minim una)
    MOVFF NOTES_CORRECTES, NOTES_CORRECTES_AUX
    LOOP_STEPS
	CALL STEP
	DECFSZ NOTES_CORRECTES_AUX, 1, 0
	GOTO LOOP_STEPS
    RETURN
    
ESPERA_05MS
    ;Tosc = 1 / 40M = 25ns
    ;Cicle màquina = 4*Tosc = 4*25ns = 100ns
    ;Cicles=0.5m/100ns=5000 -> molt -> 0.1m/100ns=1000 (5x1000)
    CALL COMPTA_1000_CICLES
    CALL COMPTA_1000_CICLES
    CALL COMPTA_1000_CICLES
    CALL COMPTA_1000_CICLES
    CALL COMPTA_1000_CICLES
    RETURN
    
STEP
    MOVFF GRAUS, GARUS_AUX
    LOOP_STEP_GRAUS
	CALL ESPERA_11US ;11US -> 1grau 
	DECFSZ GARUS_AUX, 1, 0
	GOTO LOOP_STEP_GRAUS
    RETURN
    
ESPERA_11US
    ;Tosc = 1 / 40M = 25ns
    ;Cicle màquina = 4*Tosc = 4*25ns = 100ns
    ;Cicles=11US/100NS = 110
    MOVLW .33 ;1CICLE
    MOVWF COMPT_ESPERA_11US, 0 ;1CICLE
    LOOP_ESPERA_11us
	;110 - 6 = 104
	;3x = 102 (+2NOP)
	;x = 34
	DECFSZ COMPT_ESPERA_11US, 1, 0 ;3CICLES
	GOTO LOOP_ESPERA_11us ;2CICLES
	NOP
	NOP
    RETURN
;****************
;ESPERA PER L'ACK
;****************
ALTAVEU

    ;Te un comptador de tick i si arriba a la quantiat de ticks que te el dc fer btg de la sortida
    INCF TICKS_ALTAVEU,1,0
    MOVF TICKS_ALTAVEU, 0, 0
    SUBWF DC_ALTAVEU, 0, 0
    BTFSS STATUS, Z, 0
    RETURN
    
    BTG LATC, 7, 0
    CLRF TICKS_ALTAVEU
    
    RETURN
;***************
;PROCES NEWNOTE
;***************
NEW_NOTE
    BCF INTCON,INT0IF,0   ; Netejem el flag de la interrupció    
    ;Guardar la nota a la RAM
    CALL GUARDAR_NOTA_RAM
    ;Incrementar num notes
    INCF NUM_NOTES,1,0
    ;Activar ACK
    CALL ACTIVAR_ACK
    
    RETURN
;*********************************
;CONTROLAR INTERRUPCIÓ START GAME 
;*********************************
ACTIVAR_START_GAME
    BCF INTCON3, INT1IF,0   ; Netejar flanc d'interrupció
    BSF FLAGS,0,0      ; Activem flag per començar el joc (FLAG<0>=Start Game)
    
    RETURN
;****************
;ACCIO DEL TMR0
;****************
ACTION_TMR0

    BCF INTCON, TMR0IF, 0 ;Netejem el flag
    CALL CARREGA_TMR0 ;Carreguem el valor del tmr0 de nou

    BTFSC FLAGS, 1, 0 ;Mirem el Flag de comptar 3 segons
    CALL COMPTAR_3S

    BTFSC FLAGS, 2, 0 ;Mirem el Flag d'activar el servo
    CALL SERVO
    
    BTFSC FLAGS, 3, 0 ;Mirem el Flag d'activar l'altaveu
    CALL ALTAVEU
    
    BTFSC FLAGS, 4, 0 ;Mirem el Flag de comptar 500ms
    CALL COMPTAR_500MS

    BTFSC FLAGS, 5, 0 ;Mirem el Flag de comptar duracio
    CALL COMPTAR_DURATION
    
    BTFSC FLAGS, 7, 0 ;Espera Trigger
    CALL ESPERA_TRIGGER
    
    RETURN
;------------------------------------FUNCIONS PRINCIPALS------------------------------------
;******************************
;INTERRUPCIONS D'ALTA PRIORITAT
;******************************
HIGH_RSI
    ;Comprovem flag TMR0
    BTFSC INTCON, TMR0IF, 0
    CALL ACTION_TMR0
    ;Comprovem flag RB0 (NewNote)
    BTFSC INTCON, INT0IF, 0
    CALL NEW_NOTE ;Ho posem per interrupció perque va per flanc
    ;Comprovem flag RB1 (StartGame)
    BTFSC INTCON3, INT1IF, 0
    CALL ACTIVAR_START_GAME
    
    RETFIE FAST
 
INIT_FLASH
    BSF EECON1,EEPGD,0
    BCF EECON1,CFGS,0
RETURN
 
VES_FLASH
    CLRF TBLPTRU,0
    MOVLW HIGH(TAULA)
    MOVWF TBLPTRH,0
    MOVLW LOW(TAULA)
    MOVWF TBLPTRL,0
RETURN
    
;********************
;MAIN 
;********************
MAIN
    CALL CONFIG_PORTS   ; CONFIGURAR ELS VO PORTS
    CALL INIT_PORTS     ; INICIALITZAR O PORTS
    CALL INIT_VARS      ; INICIALITZAR VARIABLES
    CALL CONFIG_INTERRUPTS    ; CONFIGURAR INTERRUCIONS
    CALL PUNTER_RAM     ; INICIALITZEM ELS PUNTERS DE LA RAM
    CALL INIT_TMR0      ; INICIALITZEM EL TMR0 PER INTERRUMPIR
    CALL CARREGA_TMR0   ; CARREGA EL TMR0 PER GENERAR LA INTERRUPCIÓ
    CALL INIT_FLASH
    CLRF FSR1L, 0 ; Posicionem el punter de lectura de la RAM a la primera posició
    
    LOOP
		    ; FEM NEWNOTE PER INTERRUPCIONS -> INT0IE
		    ;FEM STARTGAME PER INTERRUPCIÓ -> INT1IE
    BTFSC FLAGS,0,0     ; MIREM EL BIT 0 DEL REGISTRE QUE INDICA QUE START GAME ES ACTIU
    CALL START_GAME
    ;Un tick son 500us adalt i 500us abaix
    GOTO LOOP

    END