cmake_minimum_required(VERSION 3.22)
project(orbis VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)

set(QT_MIN_VERSION "6.6.0")
set(KF_MIN_VERSION "6.0.0")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Core Qml DBus Gui)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS CoreAddons I18n Config)
find_package(Plasma REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(PIPEWIRE REQUIRED IMPORTED_TARGET libpipewire-0.3)

include_directories(backend/include)

set(QML_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/qml")

qt6_add_qml_module(audioequalizer_backend
    URI "org.kde.audioequalizer"
    VERSION 1.0
    OUTPUT_DIRECTORY "${QML_OUTPUT_DIR}/org/kde/audioequalizer"
    SOURCES
        backend/include/backend_manager.h
        backend/src/backend_manager.cpp
        backend/include/audio_engine.h
        backend/src/audio_engine.cpp
)

set_target_properties(audioequalizer_backendplugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${QML_OUTPUT_DIR}/org/kde/audioequalizer"
)

target_include_directories(audioequalizer_backend
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/backend/include
)

target_link_libraries(audioequalizer_backend
    PRIVATE
        Qt6::Core
        Qt6::Qml
        Qt6::DBus
        Qt6::Gui
        KF6::I18n
        KF6::ConfigCore
        Plasma::Plasma
        PkgConfig::PIPEWIRE
)


set(_orbis_qml_install_dir
    "${KDE_INSTALL_QMLDIR}/org/kde/audioequalizer"
)

set_target_properties(audioequalizer_backend PROPERTIES
    INSTALL_RPATH "$ORIGIN"
)

if(TARGET audioequalizer_backendplugin)
    set_target_properties(audioequalizer_backendplugin PROPERTIES
        INSTALL_RPATH "$ORIGIN"
    )

    install(TARGETS
        audioequalizer_backend
        audioequalizer_backendplugin
        LIBRARY DESTINATION "${_orbis_qml_install_dir}"
    )
else()
    message(FATAL_ERROR
        "O Qt não criou o target audioequalizer_backendplugin. "
        "Verifique a configuração do módulo QML."
    )
endif()

install(
    DIRECTORY "${QML_OUTPUT_DIR}/org/kde/audioequalizer/"
    DESTINATION "${_orbis_qml_install_dir}"
    FILES_MATCHING
        PATTERN "qmldir"
        PATTERN "*.qmltypes"
        PATTERN "*.so"
)

plasma_install_package(plasmoid org.kde.audioequalizer applet)
