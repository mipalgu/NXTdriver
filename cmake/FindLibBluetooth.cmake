# Components: private_headers, compiler_support

include (FindPackageHandleStandardArgs)
include (CheckFunctionExists)
include (CheckCCompilerFlag)

find_path(LIBBLUETOOTH_PUBLIC_INCLUDE_DIR bluetooth/bluetooth.h
	DOC "Path to bluetooth/bluetooth.h"
)

if (LIBBLUETOOTH_PUBLIC_INCLUDE_DIR)
  list (APPEND LIBBLUETOOTH_INCLUDE_DIRS ${LIBBLUETOOTH_PUBLIC_INCLUDE_DIR})
endif ()

  if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    find_library(LIBBLUETOOTH_LIBRARIES NAMES IOBluetooth PATHS ${CMAKE_OSX_SYSROOT}/System/Library PATH_SUFFIXES Frameworks NO_DEFAULT_PATH)
    set (LIBBLUETOOTH_LINKER_FLAGS "-framework Foundation -framework IOBluetooth")
  else ()
    find_library(LIBBLUETOOTH_LIBRARIES "bluetooth" HINTS "${CMAKE_CURRENT_LIST_DIR}" /usr/lib /usr/lib/x86_64-linux-gnu /usr/local/lib)
    set (LIBBLUETOOTH_LINKER_FLAGS "-lbluetooth")
  endif ()

find_package_handle_standard_args(LibBluetooth
  REQUIRED_VARS LIBBLUETOOTH_LIBRARIES #LIBBLUETOOTH_PUBLIC_INCLUDE_DIR
  #HANDLE_COMPONENTS #This breaks compiling under ubuntu 12.04 and doesn't seem to be needed
)

