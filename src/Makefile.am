AUTOMAKE_OPTIONS = subdir-objects

bin_PROGRAMS = boot.image
boot_image_SOURCES = boot/i386/boot.S
boot_image_CCASFLAGS = $(AM_CCASFLAGS) -m32 -nostdinc -ffreestanding -fno-PIE -fno-pie -msoft-float  -I$(top_builddir)/include
boot_image_LDFLAGS = $(AM_LDFLAGS) -fno-common -Os -m32 -march=i386 -mrtd -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-3dnow -msoft-float -nostdinc -fno-dwarf2-cfi-asm -mno-stack-arg-probe -fno-asynchronous-unwind-tables -fno-unwind-tables -fno-ident -fno-stack-protector -fno-pie -fno-PIE -fno-builtin -Wl,-melf_i386 -no-pie -nostdlib -falign-loops=1 -falign-jumps=1 -Wl,-N -Wl,-S -Wl,-Ttext,0x7C00
boot_image_OBJCOPYFLAGS = $(AM_OBJCOPYFLAGS) -O binary
data_DATA = boot.img
CLEANFILES = boot.img

boot.img: boot.image
	$(TARGET_OBJCOPY) $(boot_image_OBJCOPYFLAGS) --strip-unneeded -R .note -R .comment -R .note.gnu.build-id -R .MIPS.abiflags -R .reginfo -R .rel.dyn -R .note.gnu.gold-version -R .note.gnu.property -R .ARM.exidx -R .interp $< $@

bin_PROGRAMS += kernel.img
kernel_img_SOURCES = kernel/i386/start.S
kernel_img_CCASFLAGS = $(AM_CFLAGS)-m32 -nostdinc -ffreestanding -fno-PIE -fno-pie -msoft-float  -I$(top_builddir)/include
kernel_img_LDFLAGS = $(AM_LDFLAGS) -fno-common -Os -m32 -march=i386 -mrtd -mno-mmx -mno-sse -mno-sse2 -mno-sse3 -mno-3dnow -msoft-float -nostdinc -fno-dwarf2-cfi-asm -mno-stack-arg-probe -fno-asynchronous-unwind-tables -fno-unwind-tables -fno-ident -fno-stack-protector -fno-pie -fno-PIE -fno-builtin -Wl,-melf_i386 -no-pie -nostdlib -Wl,-N -Wl,-S -Wl,-Ttext,0x8000 -Wl,--oformat,binary
