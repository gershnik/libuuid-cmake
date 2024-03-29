# Copyright (c) 2022, Eugene Gershnik
# SPDX-License-Identifier: BSD-3-Clause

include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckStructHasMember)
include(CheckCSourceCompiles)
include(CheckTypeSize)
include(CheckSymbolExists)
include(CMakePushCheckState)
include(FindUnixCommands)

set(CONFIG_DEFINES "")

macro(add_config_def name)
   list(APPEND CONFIG_DEFINES "\$<\$<BOOL:${${name}}>:${name}>")
endmacro()

macro(xcheck_function_exists fun var)
    check_function_exists(${fun} ${var} ${ARGN})
    add_config_def(${ARGV1})
endmacro()

macro(xcheck_include_file fun var)
    check_include_file(${fun} ${var} ${ARGN})
    add_config_def(${var})
endmacro()

macro(xcheck_type_size fun var)
    check_type_size(${fun} ${var} ${ARGN})
    add_config_def(HAVE_${var})
endmacro()

macro(xcheck_struct_has_member struct member header var)
    check_struct_has_member("${struct}" "${member}" "${header}" ${var} ${ARGN})
    add_config_def(${var})
endmacro()

macro(xcheck_c_source_compiles src var)
    check_c_source_compiles("${src}" ${var} ${ARGN})
    add_config_def(${var})
endmacro()

macro(xcheck_symbol_exists symbol files var)
    check_symbol_exists("${symbol}" "${files}" ${var} ${ARGN})
    add_config_def(${var})
endmacro()

xcheck_include_file("unistd.h" HAVE_UNISTD_H)
xcheck_include_file("stdlib.h" HAVE_STDLIB_H)
xcheck_include_file("err.h" HAVE_ERR_H)
xcheck_include_file("sys/sysmacros.h" HAVE_SYS_SYSMACROS_H)
xcheck_include_file("sys/time.h" HAVE_SYS_TIME_H)
xcheck_include_file("sys/file.h" HAVE_SYS_FILE_H)
xcheck_include_file("sys/ioctl.h" HAVE_SYS_IOCTL_H)
xcheck_include_file("sys/socket.h" HAVE_SYS_SOCKET_H)
xcheck_include_file("sys/un.h" HAVE_SYS_UN_H)
xcheck_include_file("sys/sockio.h" HAVE_SYS_SOCKIO_H)
xcheck_include_file("sys/syscall.h" HAVE_SYS_SYSCALL_H)
xcheck_include_file("net/if.h" HAVE_NET_IF_H)
xcheck_include_file("net/if_dl.h" HAVE_NET_IF_DL_H)
xcheck_include_file("netinet/in.h" HAVE_NETINET_IN_H)

xcheck_function_exists("usleep" HAVE_USLEEP)
xcheck_function_exists("nanosleep" HAVE_NANOSLEEP)
xcheck_function_exists("getexecname" HAVE_GETEXECNAME)
xcheck_function_exists("err" HAVE_ERR)
xcheck_function_exists("errx" HAVE_ERRX)
xcheck_function_exists("warn" HAVE_WARN)
xcheck_function_exists("warnx" HAVE_WARNX)
xcheck_function_exists("dirfd" HAVE_DIRFD)
xcheck_function_exists("reallocarray" HAVE_REALLOCARRAY)
if (NOT HAVE_DIRFD)
    xcheck_symbol_exists("dirfd" "sys/types.h;dirent.h" HAVE_DECL_DIRFD)
    if (HAVE_DECL_DIRFD)
        set(HAVE_DIRFD True CACHE INTERNAL "")
    endif()
endif()

if (NOT HAVE_DIRFD)
    xcheck_struct_has_member("DIR" "dd_fd" "sys/types.h;dirent.h" HAVE_DIR_DD_FD)
    if (HAVE_DIRFD)
        set(HAVE_DIRFD True CACHE INTERNAL "")
    endif()
endif()

xcheck_type_size("loff_t" LOFF_T)

xcheck_struct_has_member("struct stat" "st_mtim.tv_nsec" "sys/stat.h" HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC)
xcheck_struct_has_member("struct sockaddr" "sa_len" "sys/types.h;sys/socket.h" HAVE_SA_LEN)

xcheck_c_source_compiles("
    #include <errno.h>

    int main() { 
        program_invocation_short_name = \"test\";    
        return 0; 
    }
" HAVE_PROGRAM_INVOCATION_SHORT_NAME)
xcheck_c_source_compiles("
    extern char *__progname;

    int main() {
        if (*__progname == 0) return 1;
        return 0;
    }
" HAVE___PROGNAME)
xcheck_c_source_compiles("
    int main() {
        static __thread int foo;
        return 0;
    }
" HAVE_TLS)

# Check if LD supports GNU linker scripts.
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/conftest.map" 
"VERS_1 {
    global: sym;
};
VERS_2 {
    global: sym;
} VERS_1;
")
cmake_push_check_state()
set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS} "-Wl,--version-script=${CMAKE_CURRENT_BINARY_DIR}/conftest.map")
check_c_source_compiles("int main(void){return 0;}" HAVE_LD_VERSION_SCRIPT)
cmake_pop_check_state()
file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/conftest.map")

#find asciidoc for man page generation
find_program(ASCIIDOCTOR_PATH asciidoctor)
