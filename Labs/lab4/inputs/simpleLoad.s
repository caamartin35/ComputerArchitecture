	.text

main:	lui $3, 0x1000
	addiu $4, $0, 0xef
	sw $4, 4($3)
	nop
	nop
	lw $5, 4($3)
	addiu $6, $5, 1
	addiu $v0, $0, 0xa
	syscall