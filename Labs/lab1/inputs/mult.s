	.text

main:
	addiu	$2, $zero, 0x0
	addiu	$3, $2, -0x1
	addiu	$4, $2, 0xcafebabe
	addiu	$5, $2, 0xdeadbeef
	mthi	$3
	mtlo	$4

multtest:
	mult $4, $5
	multu $4, $5
	addiu	$2, $zero, 0x0a
	syscall
	
