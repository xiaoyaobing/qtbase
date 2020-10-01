# Generate deployment tool json

# Locate newest Android sdk build tools revision
function(qt6_android_get_sdk_build_tools_revision out_var)
    if (NOT QT_ANDROID_SDK_BUILD_TOOLS_REVISION)
        file(GLOB android_build_tools
            LIST_DIRECTORIES true
            RELATIVE "${ANDROID_SDK_ROOT}/build-tools"
            "${ANDROID_SDK_ROOT}/build-tools/*")
        if (NOT android_build_tools)
            message(FATAL_ERROR "Could not locate Android SDK build tools under \"${ANDROID_SDK_ROOT}/build-tools\"")
        endif()
        list(SORT android_build_tools)
        list(REVERSE android_build_tools)
        list(GET android_build_tools 0 android_build_tools_latest)
    endif()
    set(${out_var} "${android_build_tools_latest}" PARENT_SCOPE)
endfunction()

if(NOT QT_NO_CREATE_VERSIONLESS_FUNCTIONS)
    function(qt_android_get_sdk_build_tools_revision)
        qt6_android_get_sdk_build_tools_revision(${ARGV})
    endfunction()
endif()

# Generate the deployment settings json file for a cmake target.
function(qt6_android_generate_deployment_settings target)
    # Information extracted from mkspecs/features/android/android_deployment_settings.prf
    if (NOT TARGET ${target})
        message(SEND_ERROR "${target} is not a cmake target")
        return()
    endif()

    get_target_property(target_type ${target} TYPE)

    if (NOT "${target_type}" STREQUAL "MODULE_LIBRARY")
        message(SEND_ERROR "QT_ANDROID_GENERATE_DEPLOYMENT_SETTINGS only works on Module targets")
        return()
    endif()

    get_target_property(target_source_dir ${target} SOURCE_DIR)
    get_target_property(target_binary_dir ${target} BINARY_DIR)
    get_target_property(target_output_name ${target} OUTPUT_NAME)
    if (NOT target_output_name)
        set(target_output_name ${target})
    endif()
    set(deploy_file "${target_binary_dir}/android-${target_output_name}-deployment-settings.json")

    set(file_contents "{\n")
    # content begin
    string(APPEND file_contents
        "   \"description\": \"This file is generated by cmake to be read by androiddeployqt and should not be modified by hand.\",\n")

    # Host Qt Android  install path
    if (NOT QT_BUILDING_QT OR QT_STANDALONE_TEST_PATH)
        set(qt_path "${QT6_INSTALL_PREFIX}")
        set(android_plugin_dir_path "${qt_path}/${QT6_INSTALL_PLUGINS}/platforms")
        set(glob_expression "${android_plugin_dir_path}/*qtforandroid*${CMAKE_ANDROID_ARCH_ABI}.so")
        file(GLOB plugin_dir_files LIST_DIRECTORIES FALSE "${glob_expression}")
        if (NOT plugin_dir_files)
            message(SEND_ERROR
                "Detected Qt installation does not contain qtforandroid_${CMAKE_ANDROID_ARCH_ABI}.so in the following dir:
${android_plugin_dir_path}
This is most likely due to the installation not being a Qt for Android build.
Please recheck your build configuration.")
            return()
        else()
            list(GET plugin_dir_files 0 android_platform_plugin_path)
            message(STATUS "Found android platform plugin at: ${android_platform_plugin_path}")
        endif()
        set(qt_android_install_dir "${qt_path}")
    else()
        # Building from source, use the same install prefix.
        set(qt_android_install_dir "${CMAKE_INSTALL_PREFIX}")
    endif()

    file(TO_NATIVE_PATH "${qt_android_install_dir}" qt_android_install_dir_native)
    string(APPEND file_contents
        "   \"qt\": \"${qt_android_install_dir_native}\",\n")

    # Android SDK path
    file(TO_NATIVE_PATH "${ANDROID_SDK_ROOT}" android_sdk_root_native)
    string(APPEND file_contents
        "   \"sdk\": \"${android_sdk_root_native}\",\n")

    # Android SDK Build Tools Revision
    qt6_android_get_sdk_build_tools_revision(QT_ANDROID_SDK_BUILD_TOOLS_REVISION)
    string(APPEND file_contents
        "   \"sdkBuildToolsRevision\": \"${QT_ANDROID_SDK_BUILD_TOOLS_REVISION}\",\n")

    # Android NDK
    file(TO_NATIVE_PATH "${ANDROID_NDK}" android_ndk_root_native)
    string(APPEND file_contents
        "   \"ndk\": \"${android_ndk_root_native}\",\n")

    # Setup LLVM toolchain
    string(APPEND file_contents
        "   \"toolchain-prefix\": \"llvm\",\n")
    string(APPEND file_contents
        "   \"tool-prefix\": \"llvm\",\n")
    string(APPEND file_contents
        "   \"useLLVM\": true,\n")

    # NDK Toolchain Version
    string(APPEND file_contents
        "   \"toolchain-version\": \"${CMAKE_ANDROID_NDK_TOOLCHAIN_VERSION}\",\n")

    # NDK Host
    string(APPEND file_contents
        "   \"ndk-host\": \"${ANDROID_NDK_HOST_SYSTEM_NAME}\",\n")

    if (CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
        set(arch_value "i686-linux-android")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
        set(arch_value "x86_64-linux-android")
    elseif (CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
        set(arch_value "aarch64-linux-android")
    else()
        set(arch_value "arm-linux-androideabi")
    endif()

    # Architecture
    string(APPEND file_contents
        "   \"architectures\": { \"${CMAKE_ANDROID_ARCH_ABI}\" : \"${arch_value}\" },\n")

    # deployment dependencies
    get_target_property(android_deployment_dependencies
        ${target} QT_ANDROID_DEPLOYMENT_DEPENDENCIES)
    if (android_deployment_dependencies)
        list(JOIN android_deployment_dependencies "," android_deployment_dependencies)
        string(APPEND file_contents
            "   \"deployment-dependencies\": \"${android_deployment_dependencies}\",\n")
    endif()

    # Extra plugins
    get_target_property(android_extra_plugins
        ${target} QT_ANDROID_EXTRA_PLUGINS)
    if (android_extra_plugins)
        list(JOIN android_extra_plugins "," android_extra_plugins)
        string(APPEND file_contents
            "   \"android-extra-plugins\": \"${android_extra_plugins}\",\n")
    endif()

    # Extra libs
    get_target_property(android_extra_libs
        ${target} QT_ANDROID_EXTRA_LIBS)
    if (android_extra_libs)
        list(JOIN android_extra_libs "," android_extra_libs)
        string(APPEND file_contents
            "   \"android-extra-libs\": \"${android_extra_libs}\",\n")
    endif()

    # package source dir
    get_target_property(android_package_source_dir
        ${target} QT_ANDROID_PACKAGE_SOURCE_DIR)
    if (android_package_source_dir)
        file(TO_NATIVE_PATH "${android_package_source_dir}" android_package_source_dir_native)
        string(APPEND file_contents
            "   \"android-package-source-directory\": \"${android_package_source_dir_native}\",\n")
endif()

    #TODO: ANDROID_VERSION_NAME, doesn't seem to be used?

    #TODO: ANDROID_VERSION_CODE, doesn't seem to be used?

    get_target_property(qml_import_path ${target} QT_QML_IMPORT_PATH)
    if (qml_import_path)
        file(TO_NATIVE_PATH "${qml_import_path}" qml_import_path_native)
        string(APPEND file_contents
            "   \"qml-import-path\": \"${qml_import_path_native}\",\n")
    endif()

    get_target_property(qml_root_path ${target} QT_QML_ROOT_PATH)
    if(NOT qml_root_path)
        set(qml_root_path "${target_source_dir}")
    endif()
    file(TO_NATIVE_PATH "${qml_root_path}" qml_root_path_native)
    string(APPEND file_contents
        "   \"qml-root-path\": \"${qml_root_path_native}\",\n")

    # App binary
    string(APPEND file_contents
        "   \"application-binary\": \"${target_output_name}\",\n")

    # App command-line arguments
    string(APPEND file_contents
        "   \"android-application-arguments\": \"${QT_ANDROID_APPLICATION_ARGUMENTS}\",\n")

    # Override qmlimportscanner binary path
    set(qml_importscanner_binary_path "${QT_HOST_PATH}/bin/qmlimportscanner")
    if (WIN32)
        string(APPEND qml_importscanner_binary_path ".exe")
    endif()
    file(TO_NATIVE_PATH "${qml_importscanner_binary_path}" qml_importscanner_binary_path_native)
    string(APPEND file_contents
        "   \"qml-importscanner-binary\" : \"${qml_importscanner_binary_path_native}\",\n")

    # Override rcc binary path
    set(rcc_binary_path "${QT_HOST_PATH}/bin/rcc")
    if (WIN32)
        string(APPEND rcc_binary_path ".exe")
    endif()
    file(TO_NATIVE_PATH "${rcc_binary_path}" rcc_binary_path_native)
    string(APPEND file_contents
        "   \"rcc-binary\" : \"${rcc_binary_path_native}\",\n")

    # Last item in json file

    # base location of stdlibc++, will be suffixed by androiddeploy qt
    # Sysroot is set by Android toolchain file and is composed of ANDROID_TOOLCHAIN_ROOT.
    set(android_ndk_stdlib_base_path "${CMAKE_SYSROOT}/usr/lib/")
    string(APPEND file_contents
        "   \"stdcpp-path\": \"${android_ndk_stdlib_base_path}\"\n")

    # content end
    string(APPEND file_contents "}\n")

    file(WRITE ${deploy_file} ${file_contents})

    set_target_properties(${target}
        PROPERTIES
            QT_ANDROID_DEPLOYMENT_SETTINGS_FILE ${deploy_file}
    )
endfunction()

if(NOT QT_NO_CREATE_VERSIONLESS_FUNCTIONS)
    function(qt_android_generate_deployment_settings)
        qt6_android_generate_deployment_settings(${ARGV})
    endfunction()
endif()

function(qt6_android_apply_arch_suffix target)
    get_target_property(target_type ${target} TYPE)
    if (target_type STREQUAL "SHARED_LIBRARY" OR target_type STREQUAL "MODULE_LIBRARY")
        set_property(TARGET "${target}" PROPERTY SUFFIX "_${CMAKE_ANDROID_ARCH_ABI}.so")
    elseif (target_type STREQUAL "STATIC_LIBRARY")
        set_property(TARGET "${target}" PROPERTY SUFFIX "_${CMAKE_ANDROID_ARCH_ABI}.a")
    endif()
endfunction()

if(NOT QT_NO_CREATE_VERSIONLESS_FUNCTIONS)
    function(qt_android_apply_arch_suffix)
        qt6_android_apply_arch_suffix(${ARGV})
    endfunction()
endif()

# Add custom target to package the APK
function(qt6_android_add_apk_target target)
    get_target_property(deployment_file ${target} QT_ANDROID_DEPLOYMENT_SETTINGS_FILE)
    if (NOT deployment_file)
        message(FATAL_ERROR "Target ${target} is not a valid android executable target\n")
    endif()

    # Create a top-level "apk" target for convenience, so that users can call 'ninja apk'.
    # It will trigger building all the target specific apk build targets that are added via this
    # function.
    # Allow opt-out.
    if(NOT QT_NO_GLOBAL_APK_TARGET)
        if(NOT TARGET apk)
            add_custom_target(apk
                DEPENDS ${target}_prepare_apk_dir
                COMMENT "Building all apks"
            )
        endif()
        set(should_add_to_global_apk TRUE)
    endif()

    set(deployment_tool "${QT_HOST_PATH}/bin/androiddeployqt")
    set(apk_dir "$<TARGET_PROPERTY:${target},BINARY_DIR>/android-build")
    add_custom_target(${target}_prepare_apk_dir
        DEPENDS ${target}
        COMMAND ${CMAKE_COMMAND}
            -E copy $<TARGET_FILE:${target}>
            "${apk_dir}/libs/${CMAKE_ANDROID_ARCH_ABI}/$<TARGET_FILE_NAME:${target}>"
        COMMENT "Copying ${target} binarty to apk folder"
    )

    add_custom_target(${target}_make_apk
        DEPENDS ${target}_prepare_apk_dir
        COMMAND  ${deployment_tool}
            --input ${deployment_file}
            --output ${apk_dir}
        COMMENT "Creating APK for ${target}"
    )

    if(should_add_to_global_apk)
        add_dependencies(apk "${target}_make_apk")
    endif()
endfunction()

if(NOT QT_NO_CREATE_VERSIONLESS_FUNCTIONS)
    function(qt_android_add_apk_target)
        qt6_android_add_apk_target(${ARGV})
    endfunction()
endif()
