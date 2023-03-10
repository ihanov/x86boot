/*
 * BIOS Interrupt 0x13
 */

#define INT13_CHS_READ_MODE 0x02
#define INT13_LBA_READ_MODE 0x42

/* Check LBA support (extensions) */
#define INT13_CHECK_LBA 0x41

/* Extended read drive parameters */
#define INT13_XREAD_DRIVE_PARAMS 0x48



/*
 * BIOS Interrupt 0x10
 */

/* Set cursor position */
#define INT10_SET_CUR_POS 0x02

/* Get cursor position and shape */
#define INT10_GET_CUR_POS 0x03

/* Teletype output */
#define INT10_TTY_OUT 0x0e
