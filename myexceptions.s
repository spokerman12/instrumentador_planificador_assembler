# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (C) 1990-2004 James Larus, larus@cs.wisc.edu.
# ALL RIGHTS RESERVED.
#
# SPIM is distributed under the following conditions:
#
# You may make copies of SPIM for your own use and modify those copies.
#
# All copies of SPIM must retain my name and copyright notice.
#
# You may not sell SPIM or distributed SPIM in conjunction with a commerical
# product or service without the expressed written consent of James Larus.
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE.
#

# Editado por: Daniel Francis - Carnet: 12-10863
# 	       Javier Vivas - Carnet: 12-11067
#
# Proyecto 2 de Organizacion del Computador CI-3815
# Instrumentador y planificador.
#
# Última modificacion 27.11.2017

# $Header: $


# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz ""
__m2_:	.asciiz ""
__e0_:	.asciiz ""
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst\data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	""
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	"  [Interrupt] "
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	"  [Interrupt] "
__e17_:	.asciiz "  [Interrupt] "
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	"  [Interrupt] "
__e20_:	.asciiz	"  [Interrupt] "
__e21_:	.asciiz	"  [Interrupt] "
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	"  [Interrupt] "
__e26_:	.asciiz	"  [Interrupt] "
__e27_:	.asciiz	"  [Interrupt] "
__e28_:	.asciiz	"  [Interrupt] "
__e29_:	.asciiz "  [Interrupt] "
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	"  [Interrupt] "
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0

InstruStart:
	.asciiz "\nInstrumentando...\n"

InstruEnd:
	.asciiz "Fin del instrumentador. Ejecutando programas \n"

fin1:	.asciiz "\nEl programa "
fin2:	.asciiz " ha terminado su ejecucion.\n"

ESC1:	.asciiz "\nLa maquina ha sido apagada. Status de los programas:"
ESC2:	.asciiz "\nPrograma "
ESC3:	.asciiz " (Finalizado)\n"
ESC4:	.asciiz " (No Finalizado)\n"
ESC5:	.asciiz "\tNumero de add: "

SaveLoad:
	.word 0 # Indica si es necesario guardar y cargar registros
TEMP:	.word 0 # Registro temporal

SaveTimer:
	.word 0 # Guardo el count mientras atiendo interrupciones


# This is the exception vector address for MIPS32:
	.ktext 0x80000180

	li $t0 0x00
	mtc0 $t0 $12		# Ignoro interrupciones
	
	sw $t0 0xffff0000

	sw $t0 TEMP		# Guardamos t0
	mfc0 $t0 $9
	sw $t0 SaveTimer	# Guardamos el count
	
	mfc0 $t1 $14
	lw $t0 RegActual
	sw $t1 8($t0)		# Guardamos PC en heap

	move $k1 $at		# Save $at
	
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f

	# (Do not) Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	#syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	#syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	#syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	
	beq $a0 9 breakEx
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!

esTransmitter:

# Guardo en pagina los registros del programa actual
#
	lw $t0 RegActual	# Guardo en array de registros
	mfc0 $k0 $14
	sw $k0 8($t0)
	sw $at 12($t0)
	sw $v0 20($t0)
	sw $v1 24($t0)
	sw $a0 28($t0)
	sw $a1 32($t0)
	sw $a2 36($t0)
	sw $a3 40($t0)
	sw $t1 48($t0)
	
	#sw $t0 44($t0)		# Guardo t0 original
	lw $t1 TEMP
	sw $t1 44($t0)
	
	sw $t2 52($t0)		# Continuo guardando
	sw $t3 56($t0)
	sw $t4 60($t0)
	sw $t5 64($t0)
	sw $t6 68($t0)
	sw $t7 72($t0)
	sw $t8 76($t0)
	sw $t9 80($t0)
	sw $s0 84($t0)
	sw $s1 88($t0)
	sw $s2 92($t0)
	sw $s3 96($t0)
	sw $s4 100($t0)
	sw $s5 104($t0)
	sw $s6 108($t0)
	sw $s7 112($t0)
	sw $gp 116($t0)
	sw $sp 120($t0)
	sw $fp 124($t0)
	sw $ra 128($t0)
	
	move $t2 $zero 			# Necesito t2 limpio
	
	lw $t0 0xffff0004		# Que tipo de interrupt tengo?
	beq $t0 0x00000073 esS_save
	beq $t0 0x00000070 esP_save
	beq $t0 0x0000001b esESC
	beqz $t0 esTimer		# Interrupt timer
	b ret
	
# Tipos de Interrupt
# s, p, ESC

# Interrupt s
#

esTimer:
	sw $zero SaveTimer		# Coloco el count en 0
	b esS_save			# Como si presionara 's'

esS_save:
	li $t0 1
	sw $t0 SaveLoad			# Es necesario SaveLoad		
			
esS:					# El interrupt es presionar 's' en 
					# el teclado.
	lw $t0 RegActual		
	addi $t0 $t0 4
	lw $t1 NUM_PROGS
	addi $t1 $t1 -1
	lw $t0 ($t0)
	beq $t0 $t1 ultimoS		# Estoy en el ultimo programa?
	
	lw $t0 RegActual		# Si no, salto a la siguiente pagina
	addi $t0 $t0 136
	addi $t1 $t0 132
	lw $t1 ($t1)
	sw $t0 RegActual
	beq $t1 1 esS			# Si ese programa ha terminado
					# lo paso de largo.
	lw $t0 ($t0)
	mtc0 $t0 $14
	j restore
	
ultimoS:
	lw $t0 PrimeroDeTodos		# Si hago 's' en el ultimo programa
	sw $t0 RegActual		# me voy al primero.

	addi $t1 $t0 132		# Salto a la siguiente pagina
	lw $t1 ($t1)
	sw $t0 RegActual
	beq $t1 1 esS			# Si ese programa ha terminado
					# lo paso de largo.

	lw $t0 ($t0)			# Vuelvo al planificador
	mtc0 $t0 $14
	j restore	
	
# Interrupt p
#
	
esP_save:
	li $t0 1
	sw $t0 SaveLoad			# Es necesario SaveLoad
	
esP:	lw $t0 RegActual		# El interrupt es al presionar 'p'
	addi $t0 $t0 4			# en el teclado.
	lw $t0 ($t0)
	beqz $t0 primerP
	
	lw $t0 RegActual		# Salto a pagina anterior
	addi $t0 $t0 -136
	addi $t1 $t0 132
	lw $t1 ($t1)
	sw $t0 RegActual
	beq $t1 1 esP			# Si ese programa ha terminado
					# lo paso de largo
	
	lw $t0 ($t0)			# Vuelvo al planificador
	mtc0 $t0 $14
	j restore

primerP:
	lw $t1 NUM_PROGS
	addi $t1 $t1 -1
	mul $t1 $t1 136
	lw $t0 PrimeroDeTodos
	add $t0 $t0 $t1			# Encuentro el ultimo
	
	add $t1 $t0 132			# Ha culminado?
	lw $t1 ($t1)
	sw $t0 RegActual
	beq $t1 1 esP			# si culmino, ve al previo
	
	lw $t0 ($t0)			# Vuelvo al planificador
	mtc0 $t0 $14
	j restore
	
# Interrupt ESC
#

esESC:
	sw $zero SaveLoad		# No es necesario SaveLoad
	move $t2 $zero			# Necesito t2 limpio
	
	la $a0 ESC1 			# "La maquina..."
	li $v0 4
	syscall
	
	lw $t0 PrimeroDeTodos		# t0 es el iterador de pagina
	lw $t1 NUM_PROGS		# Comparo t2 y t1 para saber si termine con los programas
	addi $t2 $t2 1			# Otro programa reportado = t2 ++

loopESC:	
	la $a0 ESC2			# "El Programa.."
	li $v0 4
	syscall
		
	move $a0 $t2			# "... i..."
	addi $a0 $a0 -1
	li $v0 1
	syscall
	
	addi $t4 $t0 132 		# Verifica si finalizo
	lw $t4 ($t4)
	beq $t4 1 finalizESC
	beqz $t4 nofinalizESC
	
finalizESC:
	la $a0 ESC3			# "Finalizado"
	li $v0 4
	syscall
	b printAdds

nofinalizESC:	
	la $a0 ESC4			# "No Finalizado"
	li $v0 4
	syscall
	b printAdds
	
printAdds:
	addi $t4 $t0 16
	lw $t4 ($t4)			# t4 tiene el numero de adds actual
	
	la $a0 ESC5			# "Numero de add"
	li $v0 4
	syscall
	
	move $a0 $t4
	li $v0 1			# Imprimo t4
	syscall
	
	beq $t2 $t1 finESC		# Si he reportado todos los programas finalizo
	
	addi $t2 $t2 1			# Si no, reportados++ y 
	addi $t0 $t0 136		# paso a la siguiente pagina
	b loopESC
	
finESC: li $v0 10			# Finalizo
	syscall
	
# Excepciones "break"
#	


breakEx:
	sw $zero SaveLoad		# No es necesario SaveLoad
	mfc0 $a0 $14
	lw $a0 ($a0)
	
	mfc0 $k0 $14
	addi $k0 $k0 4
	sw $k0 8($t0)
	mtc0 $k0 $14
	
	beq $a0 0x0000040d breakFinal	# Estoy en un break 0x10?

	b ret				# Si no, retorna al programa

breakFinal:
	la $a0 fin1			# "El programa"
	li $v0 4
	syscall
	
	lw $a0 RegActual
	addi $a0 $a0 4			# "... i..."
	lw $a0 ($a0)
	li $v0 1			
	syscall

	la $a0 fin2			# "ha finalizado su ejecucion."
	li $v0 4
	syscall
	
	lw $t2 RegActual
	addi $t0 $zero 1
	sw $t0 132($t2)			# RegActual+132 = 1 sii el programa ha culminado
	lw $t0 Ejecutandose
	addi $t0 $t0 -1
	sw $t0 Ejecutandose		# Programas ejecutadose--
	beqz $t0 esESC			# Si ya no hay programas ejecutandose, ejecuta esESC
	b esS
	
	lw $t1 RegActual
	
	addi $t1 $t1 136
	sw $t1 RegActual		# RegActual ahora es la siguiente pagina
	
	
	
	b ret

# Don't skip instruction at EPC since it has not executed.


ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
				# (Need to handle delayed branch case here)
	mtc0 $k0 $14

restore:
# Restore registers and reset processor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	move $at $k1		# Restore $at

	lw $k0 SaveLoad
	beqz $k0 afterLoad	# Es necesario guardar/cargar?

# Carga los registros de la pagina del programa actual
#

loadRegs:
	lw $t0 RegActual
	addi $t1 $t0 8 
	lw $t0 ($t1)
	beqz $t0 loadPrimeraEj		# Si es la primera vez que ejecuto solo cargo la pagina
	b loadCont
	
loadPrimeraEj:
	lw $t0 RegActual		# Cargo la pagina
	lw $t0 ($t0)

loadCont:				# Cargo todos los registros
	mtc0 $t0 $14			# y actualizo el epc para retomar la ejecucion.
	lw $at RegActual
	addi $at $at 12
	lw $at ($at)
	lw $v0 RegActual
	addi $v0 $v0 20
	lw $v0 ($v0)
	lw $v1 RegActual
	addi $v1 $v1 24
	lw $v1 ($v1)
	lw $a0 RegActual
	addi $a0 $a0 28
	lw $a0 ($a0)
	lw $a1 RegActual
	addi $a1 $a1 32
	lw $a1 ($a1)
	lw $a2 RegActual
	addi $a2 $a2 36
	lw $a2 ($a2)
	lw $a3 RegActual
	addi $a3 $a3 40
	lw $a3 ($a3)
	#lw $t0 RegActual		# Estoy usando t0, lo cargo luego
	#addi $t0 $t0 44
	#lw $t0 ($t0)
	lw $t1 RegActual
	addi $t1 $t1 48
	lw $t1 ($t1)
	lw $t2 RegActual
	addi $t2 $t2 52
	lw $t2 ($t2)
	lw $t3 RegActual
	addi $t3 $t3 56
	lw $t3 ($t3)
	lw $t4 RegActual
	addi $t4 $t4 60
	lw $t4 ($t4)
	lw $t5 RegActual
	addi $t5 $t5 64
	lw $t5 ($t5)
	lw $t6 RegActual
	addi $t6 $t6 68
	lw $t6 ($t6)
	lw $t7 RegActual
	addi $t7 $t7 72
	lw $t7 ($t7)
	lw $t8 RegActual
	addi $t8 $t8 76
	lw $t8 ($t8)
	lw $t9 RegActual
	addi $t9 $t9 80
	lw $t9 ($t9)
	lw $s0 RegActual
	addi $s0 $s0 84
	lw $s0 ($s0)
	lw $s1 RegActual
	addi $s1 $s1 88
	lw $s1 ($s1)
	lw $s2 RegActual
	addi $s2 $s2 92
	lw $s2 ($s2)
	lw $s3 RegActual
	addi $s3 $s3 96
	lw $s3 ($s3)
	lw $s4 RegActual
	addi $s4 $s4 100
	lw $s4 ($s4)
	lw $s5 RegActual
	addi $s5 $s5 104
	lw $s5 ($s5)
	lw $s6 RegActual
	addi $s6 $s6 108
	lw $s6 ($s6)
	lw $s7 RegActual
	addi $s7 $s7 112
	lw $s7 ($s7)
	lw $gp RegActual
	addi $gp $gp 116
	lw $gp ($gp)
	lw $sp RegActual
	addi $sp $sp 120
	lw $sp ($sp)
	lw $fp RegActual
	addi $fp $fp 124
	lw $fp ($fp)
	lw $ra RegActual
	addi $ra $ra 128
	
afterLoad:
	
	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	mtc0 $k0 $12
	
	li $t0 0x10
	sw $t0 0xffff0000	# Permito interrupciones de teclado
	
	li $t0 0x11
	mtc0 $t0 $12		# Enciendo modo usuario e interrupciones
		
	lw $t0 SaveTimer
	
	mtc0 $t0 $9		# Recupero el count
	
	lw $t0 RegActual	# Me ubico en la pagina actual
	
	lw $k0 8($t0)
	mtc0 $k0 $14		# y cargo el pc correcto
	
	
	addi $t0 $t0 44		# Ya puedo cargar t0
	lw $t0 ($t0)
	
	

# Return from exception on MIPS32:
	eret

#				#			#			#
	.globl __eoth
__eoth:

	.data

RegActual:
	.word 0			# Direccion de pagina de registros actual
	
Ejecutandose:
	.word 0			# Numero de programas ejecutandose

PrimeroDeTodos:
	.word 0			# Direccion de pagina del primer programa
	
	.globl main	

	.text

# Proceso principal del proyecto			
#
									
main:

mul $v0  $zero 10863		# Dummy para saber cuando termina myprogs.s

sw $zero 0xffff0000		# Prohibo interrupciones de teclado
li $t1 0x00
mtc0 $t1 $12			# Ignoro interrupciones

li $v0 4			# "Instrumentando"
la $a0 InstruStart
syscall

la $s0 PROGS	
lw $t1 NUM_PROGS		# *** Ver tabla de pagina de registros en el reporte ***		

sw $t1 Ejecutandose		# Comenzamos con todos los programas ejecutandose
				
mul $a0 $t1 136
li $v0 9
syscall				# En v0 comienza la memoria reservada para las paginas

lw $t0 ($s0)
sw $t0 ($v0)			# La dir del primer programa queda en su pagina
sw $v0 RegActual		# La pagina actual (RegActual) es del primer programa
sw $v0 PrimeroDeTodos

move $t1 $v0			# Preparo al iterador de la estructura
move $s1 $s0			# s1 = PROGS, preparo al iterador del loopInstrumentador
lw $t2 NUM_PROGS		# Preparo al contador del main
lw $s2 NUM_PROGS		# Preparo al contador del loopInstrumentador

addi $s3 $zero 1		# Preparo al contador de numProg

# Comienzo a instrumentar y 
# armar las paginas de cada programa
#

loopLista:
addi $t1 $t1 136		# Voy a donde quedaran los registros del siguiente programa
addi $s0 $s0 4			
lw $t3 ($s0)			# dirPrograma en t3
sw $t3 ($t1)			# Guardo la direccion del programa en su pagina
sw $s3 4($t1)			# Asigno numero de programa
sw $t3 8($t1)			# Guardo PC en pagina
addi $s3 $s3 1			# Aumento numero de programa
addi $t2 $t2 -1			# Decremento el contador del main
beq $t2 1 loopInstru		# Termine de guardar cada uno en su pagina? Instrumento
b loopLista

loopInstru:
lw $a0 ($s1)			# Carga en a0 el programa a instrumentar
lw $a1 4($s1)			# Y en a1 el segundo, para finalizar ciclos

addi $sp $sp -16		# Guardo registros dependientes del llamador			
sw $s0 4($sp)
sw $s1 8($sp)
sw $s2 12($sp)

move $s0 $zero			# Necesitamos estos dos registros limpios
move $s1 $zero

jal instrumentador		# Instrumento
lw $s2 12($sp)
lw $s1 8($sp)
lw $s0 4($sp)
addi $sp $sp 16			# Recupero registros

addi $s1 $s1 4			# s1 tiene al siguiente programa
addi $s2 $s2 -1			# Decremento el contador hasta llegar a 1

lw $s3 RegActual		# Actualizo RegActual con la pagina del programa siguiente
addi $s3 $s3 136
sw $s3 RegActual

beq $s2 0 planificador		# Si ya instrumente todos, paso al planificador
b loopInstru

# Planificador 
# Ejecuta los programas y prepara la ejecucion de las interrupciones
#

planificador:

#li $v0 10			# Si solo quiero instrumentar enciendo esto
#syscall

lw $s3 PrimeroDeTodos
sw $s3 RegActual		# Me ubico en pagina del primer programa

la $t0 p1			# Cargo direccion de la primera instruccion del primer programa
lw $t1 RegActual
sw $t0 ($t1)

li $v0 4
la $a0 InstruEnd		# "Fin del instrumentador. Ejecutando..."
syscall

li $t0 0x10
sw $t0 0xffff0000		# Permito interrupciones de teclado

	
li $t0 0x11
mtc0 $t0 $12			# Enciendo modo usuario e interrupciones

lw $t0 QUANTUM			# Cargo el compare
mtc0 $t0 $11

andi $at 0x00000000		# Limpio los registros que usamos hasta este punto
andi $v0 0x00000000
andi $a0 0x00000000
andi $a1 0x00000000
andi $t0 0x00000000
andi $t1 0x00000000
andi $t2 0x00000000
andi $t3 0x00000000
andi $t4 0x00000000
andi $t5 0x00000000
andi $s0 0x00000000
andi $s1 0x00000000
andi $s2 0x00000000
andi $s3 0x00000000

mtc0 $zero $9			# Inicio el count

j p1				# Ejecutamos primer programa


# Instrumentador
#

instrumentador:
addi $sp $sp -8			# Creamos marco del instrumentador
sw $ra 4($sp)
sw $fp ($sp)
move $fp $sp

# Entrada $a0			# En a0 tengo la direccion del programa y de su primera instruccion
move $t1 $a0			# Itero sobre el las direcciones de las instrucciones

sw $zero 0xffff0000		# Prohibo interrupciones de teclado

loopInstrumentador:

lw $t2 ($t1)			# Cargo el codigo de operacion de la inst actual
move $t4 $t1			# Preparo el iterador de subrutina
move $t6 $t2
andi $t6 $t6 0xffff0000		# Busco un li $v0
beq $t6 0x24020000 li_10_a	# Si lo tengo, extraigo el inmediato
andi $t3 $t2 0xfc0007df		# Filtro con mascara el codigo
beqz $t3 prefindAdd		# Si el filtro = 0x00000000, encontre un add
andi $t3 $t2 0xfffffff3			
add $t3 $t3 $s0 
beq $t3 10 UltimoSyscall10_a	# Si v0 es 10 y t3 es 0x0, encontre un syscall 10
addi $t1 $t1 4			# Paso a la siguiente instruccion
b loopInstrumentador

li_10_a:			# Encontre un li $v0 10 en la rutina principal
and $s0 $t2 0x0000ffff		# En s0 tengo el inmediato del li $v0
addi $t1 $t1 4
b loopInstrumentador

UltimoSyscall10_a:
addi $t7 $t1 4			# Como es mi proxima instruccion?
lw $t6 ($t7)
beqz $t6 finInstrumentador	# Deja de instrumentar si la siguiente instruccion es nop o dummy
beq $t6 0x20012a6f finInstrumentador
beq $t7 $a1 finInstrumentador	# O si la proxima instruccion es el proximo programa
li $t5 0x0000040d		# De todas formas, cargo en t5 el codigo de break 0x10
sw $t5 ($t1)			# Reemplazo el syscall con break 0x10
addi $t1 $t1 4			# Sigue instrumentando
b loopInstrumentador

prefindAdd:

lw $t5 RegActual		
addi $t5 $t5 16			# En t5 estan el num adds del programa
lw $t6 ($t5)
addi $t6 $t6 1
sw $t6 ($t5)			# Num de adds en este programa++

findAdd:

lw $t5 ($t4)			# t4 apunta al ultimo syscall => Termino subrutina

move $t6 $t5
andi $t6 $t6 0xffff0000		# Busco un li $v0
beq $t6 0x24020000 li_10_b
andi $t3 $t5 0xfffffff3		
add $t3 $t3 $s1			# Si t3 es 0 y s1 es 10 encontre un syscall 10
beq $t3 10 UltimoSyscall10_b	# Quiero llegar al final del programa
addi $t4 $t4 4			
b findAdd

li_10_b:			# Encontre un li $v0 10 en la subrutina
and $s1 $t5 0x0000ffff		# En s1 tengo el inmediato del li $v0
addi $t4 $t4 4
b findAdd

UltimoSyscall10_b:
addi $t7 $t4 4			# Como es mi proxima instruccion?
lw $t6 ($t7)
beqz $t6 loopDesplazamiento	# Comienza a desplazar si la siguiente instruccion es nop o dummy
#beq $t6 0x20012a6f loopDesplazamiento
#beq $t7 $a1 loopDesplazamiento	# O si la proxima instruccion es el proximo programa
addi $t4 $t4 4			# Sigue buscando
b findAdd

loopDesplazamiento:

lw $t5 ($t4)			# Busco 'beq' para corregirlos
andi $t6 $t5 0xfc000000		# t6 es 0x1000000 sii t5 es codigo de beq
beq $t6 0x10000000 tengoBranch
sw $t5 4($t4)			# Guarda el codigo de instruccion 4 bytes mas abao
addi $t4 $t4 -4			# Coloca al iterador 4 espacios mas arriba
beq $t4 $t1 insertaBreak	# Si t4 = iterador principal, inserta el break
b loopDesplazamiento

tengoBranch:
andi $t6 $t5 0x0000ffff		# En t6 tengo el inmediato del branch
addi $t6 $t6 1
mul $t6 $t6 4			# Desplazamiento en memoria = (inmediato-1)*4
add $t7 $t6 $t4			# t7 tiene la direccion del label del beq
bgt $t7 $t1 Caso1		# Si el label esta encima del add, estamos en el Caso1 del enunciado
addi $t4 $t4 -4			# Coloca al iterador 4 espacios mas arriba
b loopDesplazamiento		# Si no, continua el loop de desplazamiento

Caso1:
addi $t5 $t5 -1			# El inmediato nuevo llega una instruccion mas lejos (hacia arriba)
sw $t5 4($t4)			# Guardo el nuevo codigo del branch en 4+ donde esta el iterador secundario
addi $t4 $t4 -4			# Coloca al iterador 4 espacios mas arriba
beq $t4 $t1 insertaBreak	# Si t4 = iterador principal, inserta el break
b loopDesplazamiento		# Vuelve al loop de desplazamiento

insertaBreak:
li $t5 0x0000080d 		# Cargo en t5 el codigo de break 0x20
sw $t5 4($t4)			# Guarda el break debajo del add
addi $t1 $t1 4
b loopInstrumentador		# Vuelve al loop principal

finInstrumentador:
li $t5 0x0000040d		# Cargo en t5 el codigo de break 0x10
sw $t5 ($t1)			# Reemplazo el syscall con break 0x10

addi $t6 $zero 0		# Limpio t6

lw $fp ($sp)			# Recuperamos el marco anterior
lw $ra 4($sp)
addi $sp $sp 8
jr $ra
