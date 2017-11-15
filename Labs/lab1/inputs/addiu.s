		.text
__start:	addiu $v0, $zero, 10
		addiu $t0, $v0, 5
		addiu $v0, $t0, -16
		addiu $t2, $zero, 500
		addiu $t3, $t2, 34
		addiu $t3, $t3, 45
		syscall
