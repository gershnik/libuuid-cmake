# libuuid-cmake

[![Language](https://img.shields.io/badge/language-CMake-blue.svg)](https://cmake.org)
[![Version](https://img.shields.io/badge/CMake-21-blue.svg)](https://cmake.org/cmake/help/latest/release/3.21.html)
[![License](https://img.shields.io/badge/license-BSD-brightgreen.svg)](https://opensource.org/licenses/BSD-3-Clause)
[![Tests](https://github.com/gershnik/libuuid-cmake/actions/workflows/test.yml/badge.svg)](https://github.com/gershnik/libuuid-cmake/actions/workflows/test.yml)

CMake build for [libuuid](https://github.com/util-linux/util-linux/tree/master/libuuid) library from [util-linux](https://github.com/util-linux/util-linux)

Libuuid is a portable, [BSD licensed](https://github.com/util-linux/util-linux/blob/master/libuuid/COPYING), 
library that is part of util-linux bundle. The whole bundle comes with autoconf and meson build scripts which, 
while not terribly complicated to use, aren't very friendly to CMake projects. The libuuid library is also available 
via package managers on all Linux platforms, Conan and possibly other places, but these, again, introduce friction 
into a simple CMake workflow.

This project allows you to use libuuid directly from CMake with no extra steps or complications. 

## Requirements

* CMake 3.21 or newer
* Internet connection when _configuring_ CMake. Note that this project automatically fetches libuuid sources from github.

## Versioning

The tags in this repository have the following form:

```
util-linux-tag[.revN]
```

Where `util-linux-tag` is the release tag in [util-linux](https://github.com/util-linux/util-linux) such as `v2.39`, 
`v2.39.1` etc.
The optional revision field is used when there are changes/bug fixes etc. in *this repository*. The numeric value
`N` is incremented by 1 every time a new revision is released.
Thus, `v2.39.rev1` is a newer revision than `v2.39` and both include `libuuid` version `v2.39`


## Usage

### Dependency with FetchContent

```cmake
include(FetchContent)
...
FetchContent_Declare(libuuid
    GIT_REPOSITORY  https://github.com/gershnik/libuuid-cmake.git
    GIT_TAG         v2.39.1
    GIT_SHALLOW     TRUE
)
...
FetchContent_MakeAvailable(libuuid)
...
target_link_libraries(mytarget
PRIVATE
  uuid::uuid
)
```
> ℹ&#xFE0F; _[What is FetchContent?](https://cmake.org/cmake/help/latest/module/FetchContent.html)_

### Dependency in a subdirectory

1. Download or clone this repository into SOME_PATH
2. Add it as subdirectory 
```cmake

add_subdirectory(SOME_PATH)
...
target_link_libraries(mytarget
PRIVATE
  uuid::uuid
)
```

Regardless of which method you use the `uuid.h` header will be available via
```c
#include <uuid/uuid.h>
```

### Building and installing on your system

You can also build and install libuuid on your system using CMake (this is only useful on non-Linux platforms,
since on Linux you might as well just use original util-linux build).
Note that man pages will only be generated if you have [Asciidoctor](https://asciidoctor.org) available.

1. Download or clone this repository into SOME_PATH
2. Do something like this on command line
```bash
cd SOME_PATH
cmake -S . -B build 
cmake --build build

#Optional
#cmake --build build --target run-tests

sudo cmake --install build
#or for custom prefix
cmake --install build --prefix some-dir
```

The installation above sets things up so that you can do `find_package(uuid)` from CMake as well as use
`pkg-config --libs --cflags uuid` if you have `pkg-config` available. 

Note that by default `cmake` installs under `/usr/local` which might not be in the list of places your
`pkg-config` looks into. If so you might need to do:
```bash
export PKG_CONFIG_PATH=/usr/local/share/pkgconfig
```

## Settings and targets

### Choosing static or shared libraries 
There are 3 variables that affect the type of library built:

* `LIBUUID_SHARED` - if set enables shared library target even if it otherwise wouldn't be enabled
* `LIBUUID_STATIC` - if set enables static library target even if it otherwise wouldn't be enabled
* [BUILD_SHARED_LIBS](https://cmake.org/cmake/help/latest/variable/BUILD_SHARED_LIBS.html) - see below

If you don't explicitly set either `LIBUUID_SHARED` or `LIBUUID_STATIC` the behavior is as follows:

* If the libuuid project is not a top level project then the enabled variant depends on `BUILD_SHARED_LIBS`.
  If `BUILD_SHARED_LIBS` is `ON` then the shared library target will be enabled. Otherwise - the static one.
* If the libuuid project is a top level project then both variants are enabled.

You can [set()](https://cmake.org/cmake/help/latest/command/set.html) `LIBUUID_SHARED`, `LIBUUID_STATIC` and `BUILD_SHARED_LIBS` in your CMake script prior to 
adding libuuid or specify them on CMake command line.

The exposed targets can be:

* `uuid::uuid_static` - the static library
* `uuid::uuid_shared` - the shared library
* `uuid::uuid` - the "default" one. If only one of static/shared variants is enabled, this one points to it. 
  If both variants are enabled then this alias points to `uuid::uuid_shared` if `BUILD_SHARED_LIBS` is `ON` or 
  `uuid::uuid_static` otherwise.  

### libuuid configuration

Two additional CMake settings expose functionality originally available via configure flags of `util-linux` autoconf build. 
These are:

* `LIBUUID_RUNSTATEDIR` for `--runstatedir`. Default is `/run`
* `LIBUUID_LOCALSTATEDIR` for `--localstatedir`. Default is `/var`

The precise effects of each original flag on libuuid are poorly documented. From source code examination `localstatedir`
can be used as a root directory for storage of local clock state, and `runstatedir` as a root for a location for Unix domain
sockets to communicate with `uuidd` daemon. 

