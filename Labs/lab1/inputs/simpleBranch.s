.text
  addiu $v0, $zero, 0xa
  addiu $3, $zero, 0xb
  addiu $4, $3, 1
  addiu $4, $3, 1
  addiu $4, $3, 1
  addiu $4, $3, 1
  addiu $4, $3, 1
  beq $zero, $zero, taken
  addiu $5, $4, 1
  addiu $6, $5, 1
  addiu $7, $6, 1
  addiu $8, $7, 1
  addiu $9, $8, 1
  addiu $10, $9, 1
taken:
  addiu $11, $zero, 1
  syscall
