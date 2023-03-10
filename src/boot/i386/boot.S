#include <asm/i386/bios.h>
#include <asm/i386/boot.h>

.code16
.globl _start
_start:
	jmp start
	nop

.org 0x4

boot_drive: /* boot drive index */
	.byte 0x0

boot_prt: /* bootable partition address */
	.short 0x0

disk_address_packet:
	.byte    0x0            /* DAP size */
	.byte    0x0            /* reserved */
	.short   0x0            /* # of sectors to be read */
	.short   0x0            /* 2-byte offset */
	.short   0x0            /* 2-byte segment */
	.long    0x0            /* LBA's lower half */
	.long    0x0            /* LBA's upper half */

start:
	cli /* disable maskable interrupts */

	xorw %ax, %ax ; AX = 0
	movw %ax, %ds ; DS = 0
	movw %ax, %es ; ES = 0
	movw %ax, %ss ; SS = 0

	movw $STACK_SEGMENT_REAL_MODE, %sp
	movw %sp, %bp

	sti /* restore maskable interrupts */

	/* BIOS preserves value in %dl for Boot Drive Index */
	movb %dl, boot_drive(,1)

	/* Some bogus BIOS'es can jump to 0x7C00:0x0000 instead */
	ljmp $0x0, $start_real_mode

start_real_mode:
	movw $new_line, %si
	call pr_msg

	/* read partition table */
	movw $prt_tbl, %si

1:
	cmpw $0x1fe, %si /* end of partition table */
	je 2f

	/* check bootable partition */
	cmpb $0x80, (%si)
	je 3f

	/* goto the next partition entry */
	addw $0x10, %si
	jmp 1b

2:
	/* there's no bootable partition */
	movw $error_msg, %si
	jmp pr_msg

3:
	movw %si, boot_prt(,1)

lba_addressing:
	/*
	 * Check if LBA supported
	 *
	 * [func]
	 *     INT = 0x13;
	 *
	 * [input]
	 *     AH = 0x41 (Check Extensions Present);
	 *     DL = [1st drive index];
	 *     BX = 0x55AA;
	 *
	 * [output]
	 *     CF: Set On Not Present, Clear If Present;
	 *     AH: Error Code on Major Version Number;
	 *     CX:
	 *         + 1 - Device Access using packet structure;
	 *         + 2 - Drive Locking Ejecting;
	 *         + 4 - Enhanced Disk Drive Support (EDD);
	 *     BX = 0xAA55;
	 */
	movb $INT13_CHECK_LBA, %ah
	movb boot_drive(,1), %dl
	movw $0x55aa, %bx
	int $0x13

	/* LBA is not supported, try CHS */
	jc chs_addressing

	cmpw $0xaa55, %bx
	jne chs_addressing

	/*
	 * LBA is supported
	 *
	 * [func]
	 *     int = 0x13;
	 *
	 * [input]
	 *     ah = 0x42 (Extended Read Sectors From Drive);
	 *     dl = [1st drive index]
	 *
	 *     ds:si = DAP (Disk Address Packet)
	 *
	 * [output]
	 *     cf: Set on Error, Clear If No Error;
	 *     ah: Return Code;
	 */
	movw boot_prt(,1), %di
	movw $disk_address_packet, %si

	/* DAP size and reserved byte */
	movw $0x0010, (%si)

	/* 1st sector in LBA format */
	movb 8(%di), %al
	movb %al, 8(%si)

	/* max # of sectors = 255 */
	movb 12(%di), %al
	movb %al, 2(%si)

	/* segment for kernel */
	movw $BOOT_KERNEL_SEG, 6(%si)

	movb $INT13_LBA_READ_MODE, %ah
	movb boot_drive(,1), %dl
	int $0x13

	/* LBA failed, try CHS */
	movw $error_msg, %si
	jc chs_addressing

	jmp load_kernel

/* skip LBA as it is not supported */
chs_addressing:
	/*
	 * Read Drive Parameters
	 *
	 * [func]
	 *     int = 0x13;
	 *
	 * [input]
	 *     ah = 0x08;
	 *     dl = [1st drive index];
	 *     es:di = 0x0000:0x0000 (for old buggy BIOS'es);
	 *
	 * [output]
	 *     cf: Set On Error, Clear if No Error;
	 *     ah: Return Code;
	 *     dl: # of hard disk drives;
	 *     dh: # of heads - 1 (HPC);
	 *     cx:
	 *         [5:0]       : # of Sectors Per Track (SPT);
	 *         [7:6] [15:8]: # of cylinders - 1;
	 *     [floppies only]
	 *         [bl: Drive type];
	 *         [es:di: pointer to drive parameter table];
	 */
	movb $0x8, %ah
	movw $0x0, %di
	movw %di, %ds
	movb boot_drive(,1), %dl
	int $0x13

	movw $error_msg, %si
	jc pr_msg

	incb %dh
	/*
	 * Read Sectors From Drive
	 *
	 * [func]
	 *     int = 0x13;
	 *
	 * [input]
	 *     ah = 0x02;
	 *     al = 0x1; # of sectors to be read
	 *     ch = [Cylinder];
	 *     cl = [Sector];
	 *     dh = [Head];
	 *     dl = [1st boot drive index];
	 *     es:bx = 0x800:0x0000
	 *
	 * [output]
	 *     cf: Set on Error, Clear If No Error;
	 *     ah: Return Code;
	 *     al: Actual # of sectors been read
	 *
	 *
	 * C = LBA / (HPC * SPT)
	 * H = (LBA / SPT) mod HPC
	 * S = (LBA mod SPT) + 1
	 */
	movw boot_prt(,1), %si

	/* Buffer address */
	movw $BOOT_KERNEL_SEG, %ax
	movw %ax, %es
	movw $0x0, %bx

	/* # of sectors to be read (max = 255) */
	movb 12(%si), %al

	/* Cylinder */
	movw 2(%si), %cx
	shl $0x6, %cx /* CH = Cylinder (8 bits) */

	/* Sector */
	movb 2(%si), %cl
	andb $0x3f, %cl

	/* Head */
	movb 1(%si), %dh

	/* Boot drive */
	movb boot_drive(,1), %dl

	movb $0x2, %ah
	int $0x13

	movw $error_msg, %si
	jc pr_msg

load_kernel:
	ljmp $0x0, $BOOT_KERNEL_ADDR

/* %si = error message */
pr_msg:
	lodsb         /* move byte from %si to %al */
	test %al, %al /* if zero -- this is the end of a string */
	jz 1f

	movb $INT10_TTY_OUT, %ah
	movw $0x700, %bx
	int $0x10 /* request BIOS to print a byte */

	jmp pr_msg

1:
	/* jump to the next line */
	movb $INT10_TTY_OUT, %ah
	movb $0xa, %al
	movw $0x700, %bx
	int $0x10

	/* get current cursor position */
	movb $INT10_GET_CUR_POS, %ah
	movb $0x0, %bh
	int $0x10

	/* set cursor to the start of line */
	movb $INT10_SET_CUR_POS, %ah
	movb $0x0, %bh
	movb $0x0, %dl
	int $0x10

	ret

new_line:
	.word 0x0a00 /* zero terminated */

error_msg:
	.asciz "Error occured"

.org 0x1b4 /* disk ID */
disk_id:

.org 0x1be /* partition table start */
prt_tbl:

.org 0x1ee /* partition table end */

.org 0x1fe
.short BOOT_MBR_SIGNATURE
