# Crazy Taxi. Everything is in cmake/DreamAddGame.cmake; this file exists so that adding a game is
# adding a directory. Add BOOT_TEST once the title boots far enough to be worth asserting on.
dream_add_game(crazytaxi TITLE "Crazy Taxi")

# Every guest call, and every jump between translated functions, is a host call. Windows gives the
# main thread 1 MB of stack, which SA-nx overflowed in play (0xC00000FD). 256 MB, reserved not
# committed, so it costs nothing unless used.
if(MSVC)
  target_link_options(crazytaxi_boot PRIVATE /STACK:268435456)
endif()

# The Switch: Horizon's own main() around the launcher, and the NRO the homebrew menu runs.
# switch/build.sh configures this with devkitPro's toolchain.
if(NINTENDO_SWITCH)
  target_sources(crazytaxi_boot PRIVATE ${CMAKE_SOURCE_DIR}/switch/src/switch_main.cpp
    ${CMAKE_SOURCE_DIR}/switch/src/egl_stubs.c)
  target_link_libraries(crazytaxi_boot PRIVATE nx)
  # A cache in front of libgcc's FDE search for C++ exception unwinding (SA-nx switch-test28,
  # switch_main.cpp's __wrap__Unwind_Find_FDE).
  target_link_options(crazytaxi_boot PRIVATE -Wl,--wrap=_Unwind_Find_FDE)
  set(CTDC_VERSION "0.1.0" CACHE STRING "Version shown in the homebrew menu")
  # A release: no end-of-run report, no profiler, stock clocks on the first run (switch_main.cpp).
  option(CTDC_RELEASE "Build the Switch launcher as a release" OFF)
  if(CTDC_RELEASE)
    set_source_files_properties(${CMAKE_SOURCE_DIR}/switch/src/switch_main.cpp
      PROPERTIES COMPILE_DEFINITIONS CTDC_RELEASE=1)
  endif()
  nx_generate_nacp(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/crazytaxi.nacp
    NAME "Crazy Taxi (CTDC-nx)"
    AUTHOR "CTDC-nx"
    VERSION "${CTDC_VERSION}")
  nx_create_nro(crazytaxi_boot NACP ${CMAKE_CURRENT_BINARY_DIR}/crazytaxi.nacp
    ICON ${CMAKE_SOURCE_DIR}/switch/icon.jpg)
endif()
