;; Leave @0
#define __SFR_OFFSET 0

;; Linked files:
;; ss_display.S
#include <avr/io.h>
#include "ss_display.S"

    ;; Frequency of CPU (16MHz) / CPU tick (1024) * highest byte
    TICKS = 16000000 / (1024 * 256) 
    ;; 12.207 ticks is around 200ms, thus 24.414 will be close to 400ms
    MS_200 = TICKS / 5
    MS_400 = MS_200 * 2
	
	BTN = 0	
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
 * r23:
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

		;; .global gives a label full visability (anyone can see it)
	.global main
main:
		// Seven Segment Setup
	;; Set pin 8 for button input to 1 as default (idel)
	;; When fallingEdge it will become 0
	cbi DDRB, BTN
	sbi PORTB, BTN

	ldi r22, SS_ALL
	out DDRD, r22		;; pins 1-7 are the seven segment outputs (PortD except 0-RX)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Timers & Interupts Glossory ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
/* TCCR1A: 	Timer Counter Control Register (A)
 * TCCR1B:	Timer Counter Control Register (B)
 * TIMSK1:	Timer Interrupt Mask
 * TCNT1H:	Timer/Counter Register (high byte)
 * TCNT1L:	Timer/Counter Register (high byte)
 * OCIE1A:	Output Compare Match Interrupt
 * OCR1AH: 	Output Compare Register (high byte)
 * OCR1AL:	Output Compare Register (low byte)
 * ICNC1: 	Input Capture Noise Canceller
 * ICIE1:	Input Capture Interrupt
 * WGM20: 	Waveform Generation Mode
 * CS10: 	Clock Select
 * CS12: 	Clock Select
 * SREG: 	Status Register (Flag)
 */
		// Timers and Interrupts Setup
	clr r22
		;; Store 0 in the Timer Control Register and Timer Interrupt Mask
	sts TCCR1A, r22								
	ldi r22,  _BV(ICIE1) | _BV(OCIE1A) 			;; Enable ICIE1 & OCIE1A (see glossory)
	sts TIMSK1, r22								

		;; Setup OCR1
	ldi r22, MS_400 
	sts OCR1AH, r22 	;; Store 400ms in the Output Compare Register (high byte)

	clr r22
	sts OCR1AL, r22 	;; Store 0 in the Output Compare Register (low byte)

		;; Load, (and enable) Clock Select, Input Capture Noise Canceller, and Waveform Generator into r22
	ldi r22,  _BV(CS10) |_BV(CS12) | _BV(ICNC1) | _BV(WGM20)		;; Setting WGM to 2-0 will display the output for longer
																	
	sts TCCR1B, r22													;; Store r22 in Timer Counter Control Register (B)				
		
	sei		;; Important: sets interupts to enable

	lockedLoop:
			;; locked loop until interupt occurs 
		rjmp lockedLoop	

	.global timer1_compa_isr
timer1_compa_isr:
		;; First interupt (OCR1)
	in r22, SREG		;; Save Status Register
	ldi r22, TCCR1B		;; Timer Control Register into r22

	cpi r31, BTN		;; Comapare r31 to 0
	sbrs r22, ICES1		;; SBRS - Skip if bit in register set
	brne goToCharFile	;; if theres no input restore the display
	
	;; Restores the display like "main:" but with none utilised register (to avoid bugs)
	ldi r29, SS_ALL
	out PORTD, r29 
	clr r29

	;; Overflow restore
	out SREG, r22 	;; Restore Status Register
	reti

	.global timer1_cpt_isr
timer1_cpt_isr:
		;; CPT, is for button capture
	in r20, SREG	;; Save Status Register

	;; Load Direct r20 into Input Capture Register 
	lds r20, ICR1L	;; Low
	lds r20, ICR1H	;; High

	push r21		;; add r21 onto the stack for debounce
	clr r29 	
	or r29, r20		;; logical 'or' between r20 and r20
	breq debounce
	pop r21			;; no branch to debounce so remove r21 from stack

	;; Now check for type of edge
	push r21
	lds r21, TCCR1B	;; Timer Control Register loaded into r21

	sbrs r21, ICES1				;; if ICES1 is 0 (rising edge) then skip 
	rjmp fallingEdge
	
	sbrc r21, ICES1				;; if ICES1 is 0 (rising edge) then skip 
	rcall risingEdge
								
	andi r21, ~(_BV(ICES1))		;; ANDI - Logical AND with Immediate
	rjmp storeEdgeInTCCR		;; reverse ICES1 to get edge

restoreTCNT:
		;; Restores the Timer/Counter Register (Overflow)
	push r21			;; add r21 onto the stack, then clear r21 to store in TCNT
	clr r21			
	sts TCNT1H, r21		
	sts TCNT1L, r21		;; Store 0 in TCNT1 low & high
	pop r21				;; remove r21 from stack now 0 is stored in TCNT
	ret

;;;;;;;;;;;;;;;;;;;;;;;
;;  Quick Functions  ;;
;;;;;;;;;;;;;;;;;;;;;;;

goToCharFile:
	;; jmp to ss_display.S
	jmp numberOfPresses

.global endOfLine
endOfLine:
		;; jmp from ss_display.S
	;; After clearing the display and registers the routine will run again
	out PORTD, r29
	clr r29
	clr r30
	clr r31
 	;; r30: Stores the length of each button press
 	;; r31:	Logs each button press

;;;;;;;;;;;;;;;;;;;;;
;; Input Handeling ;;
;;;;;;;;;;;;;;;;;;;;;

fallingEdge:
	;; Falling edge is when the button is pressed
	ori r21, _BV(ICES1)		;; wait for rising edge
	rcall restoreTCNT		;; restore Timer/Counter Register
	
storeEdgeInTCCR:
	;; Store the edge in Timer Counter Control Register (B)
	sts TCCR1B, r21

debounce:
	;;	Upon rising edge, remove all registers from the stack
	pop r21
	out SREG, r20	;; Restore Status Register
	reti

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Compute Button Press ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

risingEdge:
	;; Rising edge is when the button is released 
	inc r31					;; increment button press log
	ldi r22, MS_200 		;; used to determine if the press was longer than a dot
	cp r20,r22				;; compare for 200ms then branch  

	;; If set then isDot, else isDash
	brcs isDot				;; BRCS - Branch if carry set
	brcc isDash				;; BRCC - Branch if carry cleared

isDot:
		;; Dot Tree
	lsl r30					;; LSL - Logical shift left (with inc as isDot)
	inc r30					;; Increment as the input is a dot
	rcall restoreTCNT		;; Restore Timer/Counter Register
	ret						;; return, timer1_compa_isr

isDash:
		;; Dash Tree
	lsl r30 				;; LSL - Logical shift left (no inc as isDash)
	rcall restoreTCNT		;; Restore Timer/Counter Register
	ret						;; return, timer1_compa_isr