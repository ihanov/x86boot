AC_INIT([KenieB], [0.1])
AM_INIT_AUTOMAKE([-Wall -Werror foreign])

AM_PROG_AS
AC_PROG_CC

AC_CONFIG_HEADERS([config.h])

AC_CONFIG_FILES([
	Makefile
	src/Makefile
])

# Check for needed tools
AC_CHECK_TOOL([TARGET_OBJCOPY], [objcopy])

AC_OUTPUT
