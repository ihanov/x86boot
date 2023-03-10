/* Boot signature of a hard drive used by BIOS */
#define BOOT_MBR_SIGNATURE 0xaa55

/* Load kernel into conventional memory of 480.5 KiB */
#define BOOT_KERNEL_ADDR 0x8000

/* kernel segment */
#define BOOT_KERNEL_SEG (BOOT_KERNEL_ADDR >> 4)

/*
 * Stack Segment starts from 0x2000.
 * Actually its size is limited to 22 KiB due to in
 * lower 0x500 addresses is located BIOS data area (BDA).
 */
#define STACK_SEGMENT_REAL_MODE 0x2000
