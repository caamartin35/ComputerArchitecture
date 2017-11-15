	.text

main:
	addiu	$3, $zero, 0x7FFFFFFF
	addi	$4, $3, 0x2
	addiu	$2, $zero, 0x0a
	syscall