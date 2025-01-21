;------------------------------------------------------------------------------
; Aaron Foster, EELE 465, Project Led Flashing
; 1/1/25
; This project uses different methods to flash pultiple LEDs and verify that 
; the MSP430 is working correctly
;------------------------------------------------------------------------------
;
;--------PINOUTS----------
; P1.0: RED LED
; P6.6: GREEN LED
;-------------------------
;
;---------MATH------------
; ACLK (32.768kHz)
; 12 counter length
; Divider of 4
; (1/32.768k)*2^12*4=0.5s
;-------------------------
; --COPYRIGHT--,BSD_EX
;  Copyright (c) 2016, Texas Instruments Incorporated
;  All rights reserved.
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions
;  are met:
;
;  *  Redistributions of source code must retain the above copyright
;     notice, this list of conditions and the following disclaimer.
;
;  *  Redistributions in binary form must reproduce the above copyright
;     notice, this list of conditions and the following disclaimer in the
;     documentation and/or other materials provided with the distribution.
;
;  *  Neither the name of Texas Instruments Incorporated nor the names of
;     its contributors may be used to endorse or promote products derived
;     from this software without specific prior written permission.
;
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
;  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
;  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
;  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; ******************************************************************************
;
;                        MSP430 CODE EXAMPLE DISCLAIMER
;
;  MSP430 code examples are self-contained low-level programs that typically
;  demonstrate a single peripheral function or device feature in a highly
;  concise manner. For this the code may rely on the device's power-on default
;  register values and settings such as the clock configuration and care must
;  be taken when combining code from several examples to avoid potential side
;  effects. Also see www.ti.com/grace for a GUI- and www.ti.com/msp430ware
;  for an API functional library-approach to peripheral configuration.
;
; --/COPYRIGHT--
;******************************************************************************
;  MSP430FR235x Demo - Toggle P1.0 using software
;
;  Description: Toggle P1.0 every 0.1s using software.
;  By default, FR235x select XT1 as FLL reference.
;  If XT1 is present, the PxSEL(XIN & XOUT) needs to configure.
;  If XT1 is absent, switch to select REFO as FLL reference automatically.
;  XT1 is considered to be absent in this example.
;  ACLK = default REFO ~32768Hz, MCLK = SMCLK = default DCODIV ~1MHz.
;
;           MSP430FR2355
;         ---------------
;     /|\|               |
;      | |               |
;      --|RST            |
;        |           P1.0|-->LED
;
;   Cash Hao
;   Texas Instruments Inc.
;   November 2016
;   Built with Code Composer Studio v6.2.0
;******************************************************************************
            .cdecls C,LIST,"msp430.h"  ; Include device header file
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
            .global __STACK_END
            .sect   .stack                  ; Make stack linker segment ?known?

            .text                           ; Assemble to Flash memory
            .retain                         ; Ensure current section gets linked
            .retainrefs

RESET       mov.w   #__STACK_END,SP         ; Initialize stack pointer
StopWDT     mov.w   #WDTPW+WDTHOLD,&WDTCTL  ; Stop WDT
            ;LED initialization
SetupP1     bic.b   #BIT0,&P1OUT            ; Clear P1.0 output
            bis.b   #BIT0,&P1DIR            ; Set P1.0 as output
            bic.b	#BIT6,&P6OUT			; Clear P6.6 output
            bis.b	#BIT6,&P6DIR			; Set P6.6 as output

;--------------------------------Timer Setup------------------------------------
;TimerB0
	bis.w	#TBCLR, &TB0CTL			;Clear timer and dividers
	bis.w 	#TBSSEL__ACLK, &TB0CTL	;Select ACLK as timer source
	bis.w	#MC__CONTINUOUS, &TB0CTL;choose continuous counting
	bis.w	#CNTL_1, &TB0CTL		;choose counter length=12 bits
	bis.w	#ID_3, &TB0CTL			;choose divider D1=4
    bis.w 	#TBIE, &TB0CTL			;Enable Overflow Interrupt
	bic.w 	#TBIFG, &TB0CTL			;Clear Interrupt flag

;----------------------------End Timer Setup------------------------------------

            bic.b	#LOCKLPM5, &PM5CTL0		;Disable low power mode
            NOP
            bis.w	#GIE, SR					;Enable global interrupt
            NOP
            xor.b   #BIT6,&P6OUT            ; Toggle P6.6 on
Mainloop    xor.b   #BIT0,&P1OUT            ; Toggle P1.0 every 0.1s
Wait        mov.w   #1000,R15              ; Delay to R15
            call #delay
;L1
            ;dec.w   R15                     ; Decrement R15
            ;jnz L1
            jmp     Mainloop                ; Again
            NOP

;------------------------------------------------------------------------------
; Subroutines
;------------------------------------------------------------------------------
;---------Start 1s delay Subroutine--------------------------------------------
;Set an outer register value (R15) to 1000
;----
delay:
                    
Outer:     mov.w #348, R10  ;Set inner register
Inner:     dec.w R10        ;dec inner register until 0
           jnz Inner
          
           dec R15          
           jnz Outer


    ret
;---------End 1s delay Subroutine----------------------------------------------


;------------------------------------------------------------------------------
; Interrupt Service Routines
;------------------------------------------------------------------------------
;--------------------------Start TimerB1_2s-------------------------------------
TimerB0_1s:

	xor.b	#BIT6, &P6OUT		; Toggle P6.6 (LED)
	bic.w	#TBIFG, &TB0CTL		;turn LED off

	reti
;-------------------------------End TimerB1_2s----------------------------------
;------------------------------------------------------------------------------
;           Interrupt Vectors
;------------------------------------------------------------------------------
            .sect   RESET_VECTOR            ; MSP430 RESET Vector
            .short  RESET                   ;
            

            .sect   ".int42"                ; TB0 vector
            .short  TimerB0_1s              ;
            .end