        # Basic branch test
	.text

main:
        addiu $v0, $zero, 0xa
l_0:    
        addiu $5, $zero, 1
        jal l_1
        addiu $10, $10, 0xf00
	nop
	nop
	syscall
	
l_2:	j l_3
	addiu $11, $zero, 0xff
	syscall
l_1:
	addiu $12, $zero, 0xbeef
	j l_2
	syscall
         
l_3:	addiu $13, $zero, 0xdead
	bne $zero, $zero, l_4
	nop
	addiu $14, $zero, 0xfeed
	syscall

l_4:	syscall