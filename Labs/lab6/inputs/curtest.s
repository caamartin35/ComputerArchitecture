.text
lui $t0, 0x1234
addiu $t1, 13
srlv $t2, $t0, $t1
ori $t3, $0, 0x91a0
ori $t9, $0, 0xfff1
bne $t2, $t3, bad
sllv $t2, $t2, $t1
lui $t0, 0x1234 #first last one here
ori $t9, $0, 0xfff2
bne $t2, $t0, bad
lui $t0, 0x8000
srav $t2, $t0, $t1
lui $t3, 0xfffc
ori $t9, $0, 0xfff3
bne $t2, $t3, bad #0x38

good:
addiu $v1, $0, 0x5678 #second last one 0x3c
addiu $v0, $0, 10 #0x40
syscall

bad:
addiu $v1, $0, 0x1234
addiu $v0, $0, 10
syscall
