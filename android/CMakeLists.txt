project(ArcsoftFaceReactNative)
cmake_minimum_required(VERSION 3.9.0)

set(PACKAGE_NAME ArcsoftFaceReactNative)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_CXX_STANDARD 20)

add_library(${PACKAGE_NAME} SHARED src/main/cpp/cpp-adapter.cpp)

include(${CMAKE_CURRENT_SOURCE_DIR}/../nitrogen/generated/android/ArcsoftFaceReactNative+autolinking.cmake)

find_library(LOG_LIB log)
find_package(react-native-vision-camera REQUIRED)

target_link_libraries(
        ${PACKAGE_NAME}
        ${LOG_LIB}
        android
        react-native-vision-camera::VisionCamera
)
