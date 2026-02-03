cmake_minimum_required(VERSION 3.5)

# -----------------------------
# Project
# -----------------------------
set(TARGET_NAME mobilityduck)
project(${TARGET_NAME} LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/src/cmake" ${CMAKE_MODULE_PATH})

# -----------------------------
# Endianness for WKB (MEOS flag)
# -----------------------------
include(TestBigEndian)
TEST_BIG_ENDIAN(IS_BIG_ENDIAN)
if(IS_BIG_ENDIAN)
  add_definitions(-DMEOS_IS_BIG_ENDIAN=1)
else()
  add_definitions(-DMEOS_IS_BIG_ENDIAN=0)
endif()

# -----------------------------
# Dependencies (vcpkg)
# -----------------------------
find_package(GEOS CONFIG REQUIRED)
find_package(PROJ CONFIG REQUIRED)
find_package(GSL REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(json-c CONFIG QUIET)
find_package(ZLIB REQUIRED)
find_package(GDAL CONFIG REQUIRED)
find_package(EXPAT REQUIRED)
find_package(unofficial-sqlite3 CONFIG REQUIRED)
if(NOT json-c_FOUND)
  find_package(JSON-C REQUIRED)
endif()

set(EXTENSION_DEPENDENCIES GDAL::GDAL PROJ::proj EXPAT::EXPAT
                           unofficial::sqlite3::sqlite3 ZLIB::ZLIB)

# MEOS from overlay port
find_package(MEOS CONFIG REQUIRED)

if(TARGET GEOS::geos_c)
  set(GEOS_TGT GEOS::geos_c)
elseif(TARGET GEOS::geos)
  set(GEOS_TGT GEOS::geos)
else()
  message(FATAL_ERROR "Neither GEOS::geos_c nor GEOS::geos was found.")
endif()

# -----------------------------
# DuckDB extension targets
# -----------------------------
set(EXTENSION_NAME ${TARGET_NAME}_extension)
set(LOADABLE_EXTENSION_NAME ${TARGET_NAME}_loadable_extension)
add_subdirectory(src/spatial)
add_subdirectory(src/sgl)
include_directories(src)
include_directories(src/include)
include_directories(src/third_party/yyjson/include)
add_subdirectory(src/third_party/yyjson)

include_directories(src/third_party/protozero/include)

include_directories(src/third_party/shapelib)
add_subdirectory(src/third_party/shapelib)
add_library(${EXTENSION_NAME} STATIC ${EXTENSION_SOURCES})
build_static_extension(${TARGET_NAME} ${EXTENSION_SOURCES})
build_loadable_extension(${TARGET_NAME} "" ${EXTENSION_SOURCES})

# -----------------------------
# json-c target / include handling
# -----------------------------
if(TARGET json-c::json-c)
  set(JSONC_TGT json-c::json-c)
else()
  target_include_directories(${EXTENSION_NAME} PRIVATE ${JSON-C_INCLUDE_DIRS})
  target_include_directories(${LOADABLE_EXTENSION_NAME} PRIVATE ${JSON-C_INCLUDE_DIRS})
  set(JSONC_TGT ${JSON-C_LIBRARIES})
endif()

# -----------------------------
# Link libraries 
# -----------------------------
target_link_libraries(${EXTENSION_NAME}
  MEOS::meos
  ${GEOS_TGT}
  PROJ::proj
  GSL::gsl
  GSL::gslcblas
  ${JSONC_TGT}
  OpenSSL::SSL
  OpenSSL::Crypto
)

target_link_libraries(${LOADABLE_EXTENSION_NAME}
  MEOS::meos
  ${GEOS_TGT}
  PROJ::proj
  GSL::gsl
  GSL::gslcblas
  ${JSONC_TGT}
  OpenSSL::SSL
  OpenSSL::Crypto
)

# -----------------------------
# Install (static & loadable)
# -----------------------------
install(
  TARGETS ${EXTENSION_NAME}
  EXPORT "${DUCKDB_EXPORT_SET}"
  LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
  ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
)

install(
  TARGETS ${LOADABLE_EXTENSION_NAME}
  LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
  ARCHIVE DESTINATION "${INSTALL_LIB_DIR}"
  RUNTIME DESTINATION "${INSTALL_LIB_DIR}"
)
