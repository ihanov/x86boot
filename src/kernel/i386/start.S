.code16
.globl _start
_start:
	movb $0x58, %al
	movb $0xe, %ah
	movw $0x700, %bx
	int $0x10

	hlt
