# Copyright (c) 2022, Eugene Gershnik
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.21)

if (POLICY CMP0135)
    cmake_policy(SET CMP0135 NEW) #use DOWNLOAD_EXTRACT_TIMESTAMP
endif()

project(libuuid-cmake)

set(UTIL_LINUX_VERSION "2.39.1")

if (NOT DEFINED LIBUUID_STATIC AND NOT DEFINED LIBUUID_SHARED)

    if (BUILD_SHARED_LIBS OR PROJECT_IS_TOP_LEVEL)
        set(LIBUUID_SHARED ON)
    else()
        set(LIBUUID_SHARED OFF)
    endif()
    if(NOT BUILD_SHARED_LIBS OR PROJECT_IS_TOP_LEVEL)
        set(LIBUUID_STATIC ON)
    else()
        set(LIBUUID_STATIC OFF)
    endif()

endif()
set(LIBUUID_SHARED ${LIBUUID_SHARED} CACHE BOOL "Whether to produce shared lib" FORCE)
set(LIBUUID_STATIC ${LIBUUID_STATIC} CACHE BOOL "Whether to produce static lib" FORCE)

include(FetchContent)

FetchContent_Declare(util-linux
    # We cannot use plain Git here because occasianolly
    # util-linux does some git shenanigans that result in
    # old removed files being detected as modified by git
    # (e.g. tests/expected/libmount/optstr-apply-user-x)
    # It is safer to fetch the whole thing as a tarball from
    # Github

    #GIT_REPOSITORY  https://github.com/util-linux/util-linux
    #GIT_TAG         v${UTIL_LINUX_VERSION}
    #GIT_SHALLOW     TRUE
    #GIT_PROGRESS    TRUE
    #GIT_SUBMODULES_RECURSE FALSE

    URL              https://github.com/util-linux/util-linux/tarball/v${UTIL_LINUX_VERSION}
)

FetchContent_MakeAvailable(util-linux)

set(ORIG_SRC ${util-linux_SOURCE_DIR})

include(config.cmake)

set(PUBLIC_INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/include)


add_library(uuid_header INTERFACE EXCLUDE_FROM_ALL)

# Single interface only library for the public header
# This is to avoid having the heder in both shared and static libs
# Which is not well supported by some generators (e.g. Xcode)
list(APPEND INSTALL_LIBS uuid_header)

target_sources(uuid_header 
INTERFACE
    ${PUBLIC_INCLUDE_DIR}/uuid/uuid.h
)
set_target_properties(uuid_header PROPERTIES PUBLIC_HEADER ${PUBLIC_INCLUDE_DIR}/uuid/uuid.h)

add_custom_command(
    OUTPUT ${PUBLIC_INCLUDE_DIR}/uuid/uuid.h
    DEPENDS ${ORIG_SRC}/libuuid/src/uuid.h
    COMMAND ${CMAKE_COMMAND} -E make_directory ${PUBLIC_INCLUDE_DIR}/uuid
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${ORIG_SRC}/libuuid/src/uuid.h ${PUBLIC_INCLUDE_DIR}/uuid
)

set_source_files_properties(${PUBLIC_INCLUDE_DIR}/uuid/uuid.h PROPERTIES GENERATED ON)

#Define static and shared libs

if (LIBUUID_SHARED)
    list(APPEND BUILD_SUFFIXES "shared")
endif()
if (LIBUUID_STATIC)
    list(APPEND BUILD_SUFFIXES "static")
endif()

set(LIBTYPE_static STATIC)
set(LIBTYPE_shared SHARED)

foreach(suffix ${BUILD_SUFFIXES})
    
    add_library(uuid_${suffix} ${LIBTYPE_${suffix}})

    list(APPEND INSTALL_LIBS uuid_${suffix})

    target_link_libraries(uuid_${suffix}
    PUBLIC
        uuid_header
    )

    target_compile_definitions(uuid_${suffix}
    PRIVATE
        ${CONFIG_DEFINES}
    )

    target_include_directories(uuid_${suffix}
    INTERFACE
        ${PUBLIC_INCLUDE_DIR}
    PRIVATE
        ${ORIG_SRC}/include
    )

    target_sources(uuid_${suffix}
    PRIVATE
        ${ORIG_SRC}/libuuid/src/uuid.h
        ${ORIG_SRC}/libuuid/src/uuidP.h
        ${ORIG_SRC}/libuuid/src/clear.c
        ${ORIG_SRC}/libuuid/src/compare.c
        ${ORIG_SRC}/libuuid/src/copy.c
        ${ORIG_SRC}/libuuid/src/gen_uuid.c
        ${ORIG_SRC}/libuuid/src/isnull.c
        ${ORIG_SRC}/libuuid/src/pack.c
        ${ORIG_SRC}/libuuid/src/parse.c
        ${ORIG_SRC}/libuuid/src/unpack.c
        ${ORIG_SRC}/libuuid/src/unparse.c
        ${ORIG_SRC}/libuuid/src/uuidd.h
        ${ORIG_SRC}/libuuid/src/uuid_time.c
        ${ORIG_SRC}/libuuid/src/predefined.c
        ${ORIG_SRC}/lib/randutils.c
        ${ORIG_SRC}/lib/md5.c
        ${ORIG_SRC}/lib/sha1.c
    ) 

    add_library(uuid::uuid_${suffix} ALIAS uuid_${suffix})

    if (PROJECT_IS_TOP_LEVEL)

        add_executable(test_uuid_${suffix})

        list(APPEND BUILT_TESTS test_uuid_${suffix})
        list(APPEND TESTS_TO_RUN "COMMAND;echo;Testing ${suffix};&&;\$<TARGET_FILE:test_uuid_${suffix}>")

        target_link_libraries(test_uuid_${suffix}
        PRIVATE
            uuid::uuid_${suffix}
        )

        target_include_directories(test_uuid_${suffix}
        PRIVATE
            ${ORIG_SRC}/include
        )

        target_compile_definitions(test_uuid_${suffix}
        PRIVATE
            ${CONFIG_DEFINES}
        )

        target_sources(test_uuid_${suffix}
        PRIVATE
            ${ORIG_SRC}/libuuid/src/test_uuid.c
        )

    endif()

endforeach()

#Set uuid::uuid alias to an appropriate variant
if (LIBUUID_SHARED AND LIBUUID_STATIC)
    if (BUILD_SHARED_LIBS)
        add_library(uuid::uuid ALIAS uuid_shared)
    elseif (LIBUUID_STATIC)
        add_library(uuid::uuid ALIAS uuid_static)
    endif()
elseif (LIBUUID_SHARED)
    add_library(uuid::uuid ALIAS uuid_shared)
elseif (LIBUUID_STATIC)
    add_library(uuid::uuid ALIAS uuid_static)
endif()

#Set filenames names of shared and static libraries
if (LIBUUID_SHARED)
    set_target_properties(uuid_shared PROPERTIES OUTPUT_NAME "uuid")
endif()
if (LIBUUID_STATIC AND NOT ${CMAKE_IMPORT_LIBRARY_SUFFIX} STREQUAL ${CMAKE_STATIC_LIBRARY_SUFFIX})
    set_target_properties(uuid_static PROPERTIES OUTPUT_NAME "uuid")
endif()

#Shared library versioning
if (LIBUUID_SHARED)
    set_target_properties(uuid_shared PROPERTIES 
        VERSION ${UTIL_LINUX_VERSION}
        SOVERSION 1
    )

    if (HAVE_LD_VERSION_SCRIPT)
        target_link_options(uuid_shared
        PRIVATE
            LINKER:--version-script=${ORIG_SRC}/libuuid/src/libuuid.sym
        )
        set_target_properties(uuid_shared PROPERTIES LINK_DEPENDS ${ORIG_SRC}/libuuid/src/libuuid.sym)
    endif()
endif()

# Running tests
if (PROJECT_IS_TOP_LEVEL AND (LIBUUID_SHARED OR LIBUUID_STATIC))
    add_custom_target(run-tests
        DEPENDS ${BUILT_TESTS}
        ${TESTS_TO_RUN}
    )
endif()

# Installing
include(GNUInstallDirs)

install(
    TARGETS ${INSTALL_LIBS}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/uuid
)


# Man pages
if (PROJECT_IS_TOP_LEVEL AND ASCIIDOCTOR_PATH AND GZIP)

    set(MAN_SOURCES 
        ${ORIG_SRC}/libuuid/man/uuid.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_clear.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_compare.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_copy.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_generate.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_is_null.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_parse.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_time.3.adoc
        ${ORIG_SRC}/libuuid/man/uuid_unparse.3.adoc
    )


    foreach(mansrc ${MAN_SOURCES})
        cmake_path(GET mansrc STEM LAST_ONLY manstem)
        set(mandst ${CMAKE_CURRENT_BINARY_DIR}/man/${manstem})
        add_custom_command(
            OUTPUT ${mandst}
            DEPENDS ${mansrc}
            COMMAND ${ASCIIDOCTOR_PATH} -b manpage -B ${ORIG_SRC} -o ${mandst} ${mansrc}
        )
        add_custom_command(
            OUTPUT ${mandst}.gz
            DEPENDS ${mandst}
            COMMAND ${CMAKE_COMMAND} -E rm -f ${mandst}.gz
            COMMAND ${GZIP} ${mandst} 
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/man
        )
        list(APPEND MAN_PAGES ${mandst}.gz)
    endforeach()

    add_custom_target(man ALL
        DEPENDS ${MAN_PAGES}
    )

    target_sources(man
    PRIVATE
        ${MAN_SOURCES}
    )


    install(
        FILES ${MAN_PAGES} 
        DESTINATION ${CMAKE_INSTALL_MANDIR}/man3
    )

elseif(PROJECT_IS_TOP_LEVEL)

    if (NOT ASCIIDOCTOR_PATH)
        message(WARNING "asciidoctor not found - man page generation is disabled")
    endif()
    if (NOT GZIP)
        message(WARNING "gzip not found - man page generation is disabled")
    endif()

endif()
