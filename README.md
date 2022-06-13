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

The tags in this repository directly correspond to tags in [util-linux](https://github.com/util-linux/util-linux). Thus if you use
`v2.38` from here you will be using libuuid code at `v2.38` in `util-linux`.

## Usage

### Dependency with FetchContent

```cmake
include(FetchContent)
...
FetchContent_Declare(libuuid
    GIT_REPOSITORY  https://github.com/gershnik/libuuid-cmake.git
    GIT_TAG         v2.38
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

### Building and installing on your system

You can also build and install libuuid on your system using CMake (though in this case you might as well just use original util-linux build).
Note that man pages will only be generated if you have [Asciidoctor](https://asciidoctor.org) available.

1. Download or clone this repository into SOME_PATH
2. Do something like this on command line
```bash
cd SOME_PATH
mkdir build && cd build
cmake -S .. 

#Optional
#make run-tests

sudo make install
#or for custom prefix
cmake --install . --prefix some-dir
```

## Settings and targets

There are 3 variables that affect the build.

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


