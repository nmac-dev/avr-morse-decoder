#include <avr/io.h>

;;;;;;;;;;;;;;;;;;;
;; Registers Log ;;
;;;;;;;;;;;;;;;;;;;
/* 8-bit
 * r16: #
 * r17: #
 * r18: #
 * r19: #
 * r20: Timer operand for timer1_cpt_isr and debounce
 * r21: Timer and Input Capture operations
 * r22: Timer setup operand (Program counter) uses MS_200 and MS_400
 * r23: #
 * 16-bit
 * r24: #
 * r25: #
 * r26: #
 * r27: #
 * r28: Stores the character sequance to be loaded to r29 if the bit sequance is equal to r30
 * r29: Used for Seven Segment display output
 * r30: Stores the length of each button press, lsl with inc for dot and just lsl for dash
 * r31:	Logs each button press  
 */

selectThis:
	;; If the comparison is true,
	;; jmp and move r28 into r29 to display the character
	mov r29, r28
	clr r28
	rjmp endOfLine  ; Back to morse-decoder.S to restore to default reeady for timers and interupts again

	;; Hardware Note:
	;; breq has a distance limit as it is relative,
	;; when this limit is reached jmp is used for the longer letters as 
	;; the Arduino can accurately point to the address of: selectThis
	
numberOfPresses:
		;; r31:	Logs each button press
	cpi r31, 0x01
	breq singlePress

	cpi r31, 0x02
	breq doublePress

	cpi r31, 0x03
	breq triplePress

	cpi r31, 0x04
	breq quadPress		;; not working

singlePress:
		;;	Single press

	;; Loads the letter to be displayed into r28, 
	;; compares r30 against the bit sequance (BS_?) from button input
	;; if r30 is equal to the bit sequance then jmp

	;; Dash tree
	ldi r28, CS_T
	cpi r30, BS_0
	breq selectThis	

	;; Dot tree
	ldi r28, CS_E
	cpi r30, BS_1
	breq selectThis

doublePress:
		;;	Double Press

	;; Dash tree
	ldi r28, CS_M
  	cpi r30, BS_0
  	breq selectThis
    
	ldi r28, CS_N
  	cpi r30, BS_1
  	breq selectThis
	
	;; Dot tree
	ldi r28, CS_A
    cpi r30, BS_2
  	breq selectThis
	
	ldi r28, CS_I
  	cpi r30, BS_3
  	breq selectThis

triplePress:
		;;	Triple Press
	
	;; Dash tree
	ldi r28, CS_O
  	cpi r30, BS_0
    breq selectThis
    	
	ldi r28, CS_K	
  	cpi r30, BS_1
	breq selectThis
    
	ldi r28, CS_G
  	cpi r30, BS_2
	breq selectThis
    
	ldi r28, CS_D
  	cpi r30, BS_3
    breq selectThis

	;; Dot tree
	ldi r28, CS_W
  	cpi r30, BS_4
    breq selectThis

    ldi r28, CS_R
  	cpi r30, BS_5
    breq selectThis
    
	ldi r28, CS_U
  	cpi r30, BS_6
    breq selectThis
    
	ldi r28, CS_S
  	cpi r30, BS_7
    breq selectThis

quadPress:
;;
;;		;; Needs FIX
;;	;;		Quadruple Press
;;
;;	;; No Bit Sequance 0 or 1
;;
;;	;; Start of Error: relocation truncated to fit: R_AVR_7_PCREL against `no symbol'
;;	;; Summary: Relative distance is to far, therefore jmp is used
;;
;;	;; Dash tree
;;	ldi r28, CS_Q
;;  	cpi r30, BS_2
;;    breq selectThis
;;
;;    ldi r28, CS_Z
;;  	cpi r30, BS_3
;;    breq selectThis
;;    
;;	ldi r28, CS_Y
;;  	cpi r30, BS_4
;;    breq selectThis
;;    
;;	ldi r28, CS_C
;;  	cpi r30, BS_5
;;    breq selectThis
;;    
;;	ldi r28, CS_X
;;  	cpi r30, BS_6
;;    breq selectThis
;;    
;;	ldi r28, CS_B
;;  	cpi r30, BS_7
;;    breq selectThis
;;
;;	;; Dot tree
;;	ldi r28, CS_J
;;  	cpse r30, 0x08 ;BS_8
;;    jmp selectThis
;;    
;;	ldi r28, CS_P
;;  	cpse r30, 0x09 ;BS_9
;;    jmp selectThis
;;
;;	ldi r28, CS_L
;;  	cpse r30, 0x0B ;BS_B
;;    jmp selectThis
;;    
;;	ldi r28, CS_F
;;  	cpse r30, 0x0D ;BS_D
;;    jmp selectThis
;;    
;;	ldi r28, CS_V
;;  	cpse r30, 0x0E ;BS_E
;;    jmp selectThis
;;    
;;	ldi r28, CS_H
;;  	cpse r30, 0x0F ;BS_F
;;    jmp selectThis
      
	;; Input unintelligible, display error and clearDisplay
	;; Error only possiable on/after 4th button press
	ldi r28, CS_ERROR
	jmp selectThis

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Seven-Segment Display Sequances ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;
	;; Bit Sequance (BS)
	;;
	BS_0 = 0x00
	BS_1 = 0x01
	BS_2 = 0x02
	BS_3 = 0x03
	BS_4 = 0x04
	BS_5 = 0x05
	BS_6 = 0x06
	BS_7 = 0x07
	BS_8 = 0x08
	BS_9 = 0x09
 ;; BS_A = 0x0A <- redundent 
	BS_B = 0x0B
 ;;	BS_C = 0x0C <- redundent
	BS_D = 0x0D
	BS_E = 0x0E	
	BS_F = 0x0F

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;	 PRESS NUMBER TO CHAR	 ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;;  P1  ;  P2  ;  P3  ;  P4  ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; T.00 ; M.00 ; O,00 ; Q.02 ;; <- Relative distance issues start here
	;; E.01 ; N.01 ; G.01 ; Z.03 ;;
	;;;;;;;;; A.02 ; K.02 ; Y.04 ;;
	       ;; I.03 ; D.03 ; C.05 ;;
	       ;;;;;;;;; W.04 ; X.06 ;;
		      ;; R.05 ; B.07 ;;
		      ;; U.06 ; J.08 ;; 
		      ;; S.07 ; P.09 ;;
		      ;;;;;;;;; L.0B ;;
			     ;; F.0D ;;
			     ;; N.0E ;;
	        	     ;; H.0F ;;
			     ;;;;;;;;;;

	;;
	;; Assign each Segment of the display to a number
	;; 
	SS_A = 7 	;; top			  _______
	SS_F = 5  	;; top-left		 |   A	 |	
	SS_B = 1 	;; top-right		F|       |B
				;;		 |_______|
	SS_G = 6	;; center-line		 |   G   |
				;;		E|	 |C
	SS_E = 4	;; bottem-left		 |_______|
	SS_C = 2  	;; bottem-right		     D
	SS_D = 3	;; bottem
	
	SS_ALL = _BV(SS_A) | _BV(SS_F) | _BV(SS_B) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D)
	;; 
	;; Character sequance (CS)
	;; '~' is invert
	;; 
	CS_A = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_B) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C))
	CS_B = ~(_BV(SS_F) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D))
	CS_C = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_E) | _BV(SS_D))
	CS_D = ~(_BV(SS_B) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D))
	CS_E = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_G) | _BV(SS_E) | _BV(SS_D))
	CS_F = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_G) | _BV(SS_E))
	CS_G = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D))
	CS_H = ~(_BV(SS_F) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C))
	CS_I = ~(_BV(SS_F) | _BV(SS_E))
	CS_J = ~(_BV(SS_B) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D))
	CS_K = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C))
	CS_L = ~(_BV(SS_F) | _BV(SS_E) | _BV(SS_D))
	CS_M = ~(_BV(SS_A) | _BV(SS_E) | _BV(SS_C))
	CS_N = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_B) | _BV(SS_E) | _BV(SS_C))
	CS_O = ~(_BV(SS_G) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D))
	CS_P = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_B) | _BV(SS_G) | _BV(SS_E))
	CS_Q = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_B) | _BV(SS_G) | _BV(SS_C))
	CS_R = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_B) | _BV(SS_E))
	CS_S = ~(_BV(SS_A) | _BV(SS_F) | _BV(SS_G) | _BV(SS_C) | _BV(SS_D))
	CS_T = ~(_BV(SS_F) | _BV(SS_G) | _BV(SS_E) | _BV(SS_D))
	CS_U = ~(_BV(SS_F) | _BV(SS_B) | _BV(SS_E) | _BV(SS_C) | _BV(SS_D))
	CS_V = ~(_BV(SS_F) | _BV(SS_B) | _BV(SS_C) | _BV(SS_D))
	CS_W = ~(_BV(SS_F) | _BV(SS_B) | _BV(SS_D))
	CS_X = ~(_BV(SS_F) | _BV(SS_B) | _BV(SS_G) | _BV(SS_E) | _BV(SS_C))
	CS_Y = ~(_BV(SS_F) | _BV(SS_B) | _BV(SS_G) | _BV(SS_C) | _BV(SS_D))
	CS_Z = ~(_BV(SS_A) | _BV(SS_B) | _BV(SS_G) | _BV(SS_D))

	CS_ERROR = ~(_BV(SS_A) | _BV(SS_B) | _BV(SS_G) | _BV(SS_E))  ;; Represented by: '?' 