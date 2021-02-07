/* 
 Calculatrice avec 6 chiffres en entrées possibles(3+3)
 Opération: addition, soustraction, multiplication
 Sortie '=' sur 3 chiffres (reset le calcul en cours)
 
 Peut être améliorée pour supporter plus de chiffres 
 en entrée et afficher plus de chiffres en sortie
 avec le même raisonnement
 
 Clear -> c
 
 N'affiche pas les chiffres en entrée mais il est
 possible de le faire avec le même principe que
 l'affichage lors de l'output */

.data
.equ UARTINOUT, 0xff201000
.equ SEGMENT, 0xff200020
correspondance: //segment displays
.word 63, 6, 91, 79, 102, 109, 125, 39, 255,111

.text
.global _start

_start:
	mov r5, #0 //r5 = count input

	b getch

verify_input:    
    //if(r0 = 63 && r0 + 1 = 65 ) {CE}
    cmp r0, #96
    bge clear
    
    cmp r0, #0x3d //equal
    beq correct_inputs
    
    //if(r5 == 1)
    cmp r5, #5
    blt ope_or_number_input
    
    cmp r5, #10 //r5 >= 10 => after operation
    bge second_number
    
    // if (r5<2 && 30 <= r0 <= 39){
    cmp r0, #40
    blt is_numbers
    
is_numbers:
    cmp r0, #48
    blt wrong_input
    cmp r0, #64
    bge wrong_input
    
    b first_numbers

first_numbers:
    add r5, r5, #1 //r5++
    
    cmp r5, #2
    bge first_num
    
    mov r6, r0 //r6 -> first number
    sub r6, r6, #48 //16 -> 10

    b getch

first_num:
	mov r3, #10 //temp
	mul r6, r6, r3
    sub r3, r0, #48 //temp
    add r6, r6, r3
    
    b getch

ope_or_number_input:
//operation + -> 2b; - -> 2d; * -> 2a; / -> 2f; = -> 3d 
    cmp r0, #48
    blt ope_input
    
    b is_numbers

ope_input:
    cmp r0, #0x3e
    bge wrong_input
    
    mov r5, #10 //r5 = 10
    mov r7, r0 // r7 -> opération
    
    b getch

second_number:
    cmp r0, #48
    blt wrong_input
    cmp r0, #64
    bge wrong_input
    
    add r5, r5, #1 //r5++
    
    cmp r5, #12
    bge second_num
    
    mov r8, r0 // r8 -> second number
    sub r8, r8, #48
    
    b getch

second_num:
	mov r3, #10 //temp
	mul r8, r8, r3
    sub r3, r0, #48 //temp
    add r8, r8, r3
    
    b getch

clear:
	//63 suivi de 65 -> CE
    b wrong_input

correct_inputs:
    // r9 -> result
    cmp r7, #0x2b //add
    addeq r9, r6, r8
    
    cmp r7, #0x2d //sub
    subeq r9, r6, r8
    
    cmp r7, #0x2a //mul
    muleq r9, r6, r8
    
    //cmp r7, #0x2f //div doesn't work in ARM mode
    //udiveq r9, r6, r8

    b output

output:
	ldr r1, =correspondance
    ldr r2, =SEGMENT //r2 = output
    
    mov r5, #0 //reload count
    mov r3, #0 //temp
    
    cmp r9, #0 //if r9 < 0
    movlt r9, #0
    
    cmp r9, #0x64 //if r9 >= 100
    bge mod_100
    
    cmp r9, #10 //if r9 >= 10
    bge mod_10
    
    ldr r4, [r1, r9, lsl #2]
    str r4, [r2]
    
 	b getch

mod_100:
	cmp r9, #0x64
    blt mod_10
    
    add r3, r3, #1
    sub r9, r9, #100
    b mod_100
	
mod_10:
	cmp r9, #0xa
    blt after_mod_10
    
    add r5, r5, #1
    sub r9, r9, #10
    b mod_10

after_mod_10:
	cmp r3, #1 //mod 100
    bge after_mod_10_with_100

	ldr r5, [r1, r5, lsl #2] //correspondance
    lsl r5, #8 //display segment left
    ldr r9, [r1, r9, lsl #2]
    
    add r4, r5, r9
    str r4, [r2]
    mov r5, #0 //reload count
    
    b getch

after_mod_10_with_100:
	ldr r3, [r1, r3, lsl #2]
    lsl r3, #16 //display 2 segments left
	ldr r5, [r1, r5, lsl #2]
    lsl r5, #8 //display segment left
    ldr r9, [r1, r9, lsl #2]
    
    add r4, r3, r5
    add r4, r4, r9
    str r4, [r2]
    mov r5, #0 //reset count
    mov r3, #0 //reset temp
    
    b getch
    
wrong_input:
	mov r9, #0 //display 0
    
    ldr r4, [r1, r9, lsl #2] //correspondance
    str r4, [r2]
    mov r5, #0 //reset count
	b getch

getch:
	ldr r0, =UARTINOUT //r0 = input
l1: //wait input
	ldr r11, [r0]
    lsrs r12, r11, #15
    beq l1
    and r0, r11, #0xff //first byte
    b verify_input
