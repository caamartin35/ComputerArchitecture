		.text
__start:	lui $3, 0x1000
		addiu $4, $zero, 0x00000011
		sb $4, 0($3)
		addiu $4, $zero, 0
		addiu $4, $zero, 0x00000022
		sb $4, 1($3)
		addiu $4, $zero, 0
		addiu $4, $zero, 0x00000033		
		sb $4, 2($3)
		addiu $4, $zero, 0
	        addiu $4, $zero, 0x00000044
		sb $4, 3($3)
		#lw $5, 0($3)
		lb $5, 0($3)
		lb $6, 1($3)
		lb $7, 2($3)
		lb $8, 3($3)
		addiu $v0, $zero, 0xa
		syscall