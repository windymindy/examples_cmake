cmake_minimum_required(VERSION 3.24)

project(project_0 VERSION 1.2.3)

include(../cmake/settings.cmake)

add_library(library_1 STATIC)
add_library(library_2 SHARED)

target_sources(
    library_1 PUBLIC FILE_SET HEADERS FILES
    library_1.hpp
)
target_sources(
    library_1 PRIVATE
    library_1.cpp
)
target_sources(
    library_2 PUBLIC FILE_SET HEADERS FILES
    library_2.hpp
)
target_sources(
    library_2 PRIVATE
    library_2.cpp
)

target_compile_definitions(library_2 PRIVATE library_2_exporting)

install(
    TARGETS library_1
    FILE_SET HEADERS
)

install(
    TARGETS library_1 library_2
    FILE_SET HEADERS
    RUNTIME DESTINATION "${CMAKE_INSTALL_LIBRARY_RUNTIME_DESTINATION}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
)
