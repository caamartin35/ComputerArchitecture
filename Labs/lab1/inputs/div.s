	.text

main:
	addiu	$3, $zero, 0x3
	addiu	$4, $zero, 0x9
	div	$4, $3
	divu	$4, $3
	addiu	$4, $4, 0x1
	div 	$4, $3
	addiu	$2, $zero, 0x0a
	syscall