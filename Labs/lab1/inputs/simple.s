	.text

main:
	addiu $v0, $zero, 0xa
	addiu $v0, $zero, 0xa
	addiu $v0, $zero, 0xb

test:
	addiu $v0, $zero, 0xa
	addiu $v0, $zero, 0xa
	addiu $v0, $zero, 0xa
	j test3

test2:
	addiu $v0, $zero, 0x4
	addiu $v0, $zero, 0x5
test3:
	addiu $v0, $zero, 0x6
	syscall