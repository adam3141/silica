# Silica workspace build: builds every library in one tree so changes across flint and agate are seen together.
# Each library also builds on its own from its own directory.
cmake_minimum_required(VERSION 3.28)

project(silica LANGUAGES CXX)

option(SILICA_BUILD_FLINT "Build the flint foundation library" ON)
option(SILICA_BUILD_AGATE "Build the agate UI library" ON)
option(SILICA_BUILD_OPAL "Build the opal editor" OFF)
option(SILICA_BUILD_TESTS "Build every library's unit tests" ON)
option(SILICA_BUILD_EXAMPLES "Build every library's examples and demos" ON)

# Libraries only build tests and examples by default when they are the top-level project; turn them on here.
set(FLINT_BUILD_TESTS ${SILICA_BUILD_TESTS} CACHE BOOL "" FORCE)
set(FLINT_BUILD_EXAMPLES ${SILICA_BUILD_EXAMPLES} CACHE BOOL "" FORCE)
set(AGATE_BUILD_TESTS ${SILICA_BUILD_TESTS} CACHE BOOL "" FORCE)
set(AGATE_BUILD_EXAMPLES ${SILICA_BUILD_EXAMPLES} CACHE BOOL "" FORCE)

if(SILICA_BUILD_TESTS)
  enable_testing()
endif()

if(SILICA_BUILD_FLINT AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/flint/CMakeLists.txt")
  add_subdirectory(flint)
endif()

if(SILICA_BUILD_AGATE AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/agate/CMakeLists.txt")
  add_subdirectory(agate)
endif()

if(SILICA_BUILD_OPAL AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/opal/CMakeLists.txt")
  add_subdirectory(opal)
endif()
