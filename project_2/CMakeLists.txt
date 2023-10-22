cmake_minimum_required(VERSION 3.24)

project(project_2 VERSION 1.2.3)

include(CMakePackageConfigHelpers)
include(../cmake/settings.cmake)

set(CMAKE_VERBOSE_MAKEFILE ON)

find_package(project_1 1.2.3 REQUIRED)

add_library(library_3 STATIC)
target_sources(
    library_3 PUBLIC FILE_SET HEADERS FILES
    library_3.hpp
)
target_sources(
    library_3 PRIVATE
    library_3.cpp
)
# or just INTERFACE_LINK_LIBRARIES to hide the headers
target_link_libraries(library_3 PUBLIC project_1_library)

add_executable(test_1)
target_sources(
    test_1 PRIVATE
    test_1.cpp
)
target_link_libraries(test_1 PRIVATE library_3)

install(
    TARGETS library_3
    EXPORT ${PROJECT_NAME}_import
    FILE_SET HEADERS
)

install(
    EXPORT ${PROJECT_NAME}_import
    DESTINATION "${CMAKE_INSTALL_PACKAGE_DESTINATION}"
)

file(
    WRITE "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}_package_input.cmake"
[[
@PACKAGE_INIT@

include(CMakeFindDependencyMacro)

include("${CMAKE_CURRENT_LIST_DIR}/@PROJECT_NAME@_import.cmake")
check_required_components(@PROJECT_NAME@)

find_dependency(project_1 1.2.3)
]]
)

configure_package_config_file(
    "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}_package_input.cmake"
    package/${PROJECT_NAME}-config.cmake
    INSTALL_DESTINATION "${CMAKE_INSTALL_PACKAGE_DESTINATION}"
)

write_basic_package_version_file(
    package/${PROJECT_NAME}-config-version.cmake
    COMPATIBILITY SameMajorVersion
)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/package/${PROJECT_NAME}-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_PACKAGE_DESTINATION}"
)
