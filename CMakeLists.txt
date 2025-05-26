cmake_minimum_required(VERSION 3.31)
project(YumeCard VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED True)

find_package(PNG REQUIRED)
find_package(ZLIB REQUIRED)
find_package(CURL REQUIRED)
find_package(nlohmann_json REQUIRED)

if (MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif ()

add_executable(YumeCard src/main.cpp)

set(EXTRA_LIBS)
if (WIN32 AND MSVC)
    list(APPEND EXTRA_LIBS ${PNG_LIBRARIES} ${ZLIB_LIBRARIES})
endif ()

target_include_directories(YumeCard PRIVATE
        ${CMAKE_SOURCE_DIR}/include
)

target_link_libraries(YumeCard
        PRIVATE
        CURL::libcurl
        nlohmann_json::nlohmann_json
        ${EXTRA_LIBS}
)

#configure_file(
#    ${CMAKE_SOURCE_DIR}/core/screenshot.js
#    ${CMAKE_BINARY_DIR}/screenshot.js
#    COPYONLY
#)

