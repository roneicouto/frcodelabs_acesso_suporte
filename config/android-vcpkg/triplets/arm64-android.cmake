include("${CMAKE_CURRENT_LIST_DIR}/../../../upstream/res/vcpkg-triplets/arm64-android.cmake")
if(CMAKE_HOST_WIN32)
    list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS
        "-DCMAKE_ASM_COMPILER=$ENV{ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/windows-x86_64/bin/aarch64-linux-android21-clang.cmd")
endif()
