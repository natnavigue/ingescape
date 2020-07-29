#####################################################################
#
# Generic (multi-platform) rules
#
#####################################################################

DEFINES += INGESCAPE_FROM_PRI

SOURCES += \
    $$PWD/../src/igs_core.c \
    $$PWD/../src/igs_definition.c \
    $$PWD/../src/igs_mapping.c \
    $$PWD/../src/igs_model.c \
    $$PWD/../src/igs_network.c \
    $$PWD/../src/igs_parser.c \
    $$PWD/../src/igs_admin.c \
    $$PWD/../src/igs_bus.c \
    $$PWD/../src/igs_call.c \
    $$PWD/../src/igs_license.c \
    $$PWD/../src/igs_monitor.c \
    $$PWD/../src/igs_json.c \
    $$PWD/../src/igs_performance.c \
    $$PWD/../src/igs_agent.c \
    $$PWD/../dependencies/yajl/src/yajl_alloc.c \
    $$PWD/../dependencies/yajl/src/yajl_buf.c \
    $$PWD/../dependencies/yajl/src/yajl_encode.c \
    $$PWD/../dependencies/yajl/src/yajl_gen.c \
    $$PWD/../dependencies/yajl/src/yajl_lex.c \
    $$PWD/../dependencies/yajl/src/yajl_parser.c \
    $$PWD/../dependencies/yajl/src/yajl_tree.c \
    $$PWD/../dependencies/yajl/src/yajl_version.c \
    $$PWD/../dependencies/yajl/src/yajl.c

HEADERS += \
    $$PWD/../src/include/uthash/uthash.h \
    $$PWD/../src/include/ingescape.h \
    $$PWD/../src/include/ingescape_advanced.h \
    $$PWD/../src/include/ingescape_private.h \
    $$PWD/../src/include/ingescape_agent.h \
    $$PWD/../dependencies/yajl/src/yajl_alloc.h\
    $$PWD/../dependencies/yajl/src/yajl_buf.h \
    $$PWD/../dependencies/yajl/src/yajl_bytestack.h \
    $$PWD/../dependencies/yajl/src/yajl_encode.h \
    $$PWD/../dependencies/yajl/src/yajl_lex.h \
    $$PWD/../dependencies/yajl/src/yajl_parser.h

INCLUDEPATH += $$PWD/../src/include \
               $$PWD/../dependencies/yajl/src/api

#CONFIG += object_parallel_to_source

#####################################################################
#
# Dependencies
#
#####################################################################

CONFIG(debug, debug|release) {
    # Include libsodium library
    !include(../../../third-party/libsodium/builds/qt/libsodium.pri) {
        error(Could not load libsodium.pri)
    }

    # Include ZeroMQ library
    !include(../../../third-party/libzmq/builds/qt/libzmq.pri) {
        error(Could not load libzmq.pri)
    }

    # Include C ZeroMQ library
    !include(../../../third-party/czmq/builds/qt/czmq.pri) {
        error(Could not load czmq.pri)
    }

    # Include zyre library
    !include(../../../third-party/zyre/builds/qt/zyre.pri) {
        error(Could not load zyre.pri)
    }
}




#####################################################################
#
# OS specific rules
#
#####################################################################


#add librairies zyre, czmq, zmq and configurate only for VS 2015 x86 (32 bits)
win32:{
    message("Scope is win32...")

    CONFIG(debug, debug|release){
        #configuration DEBUG
        DESTDIR = $$OUT_PWD/debug
    }else {
        #configuration RELEASE
        DESTDIR = $$OUT_PWD/release
    }

    #UNIX functions
    SOURCES += $$PWD/../dependencies/windows/unix/unixfunctions.c

    HEADERS += $$PWD/../dependencies/windows/unix/unixfunctions.h

    CONFIG(release, debug|release) {
        #Add librairies
        LIBS += -L$$(ProgramFiles)/ingescape/lib/ -lzyre -lczmq -llibsodium

        INCLUDEPATH += $$(ProgramFiles)/ingescape/include
    }

    #To get the Ip address into the network.c
    LIBS += -L$$C:/Windows/System32 -lwsock32 -lIPHLPAPI -lws2_32

    INCLUDEPATH += $$PWD/../dependencies/windows/unix
}



#
# Mac and iOS
#
mac:{
    message("Scope is macos...")

    CONFIG(release, debug|release) {
        #INCLUDEPATH += /usr/local/include
        INCLUDEPATH += $$(HOME)/builds/sysroot/usr/local/include
    }

    #
    # Option 1: generic version (relative paths)
    # - pros: add /usr/local/lib to the list of search directories of our application
    #         It can help it to find extra librairies
    #
    # - cons: may create a conflict with brew installs (libjpeg, libpng, libtiff)
    #LIBS += -L/usr/local/lib -lzmq -lczmq -lzyre -lyajl

    #
    # Option 2: specific version (absolute paths)
    # - pros: avoid to add /usr/local/lib to the list of search directories of our application
    #         It prevents conflict with brew installs (libjpeg, libpng, libtiff)
    #
    # - cons: all required librairies must be linked explictly
    #         AND does not work if libraries are installed in another directory
    LIBS += -framework CoreFoundation

    CONFIG(release, debug|release) {
        #LIBS += /usr/local/lib/libczmq.dylib
        #LIBS += /usr/local/lib/libzyre.dylib
        #LIBS += /usr/local/lib/libsodium.dylib
        LIBS += $$(HOME)/builds/sysroot/usr/local/lib/libczmq.dylib
        LIBS += $$(HOME)/builds/sysroot/usr/local/lib/libzyre.dylib
        LIBS += $$(HOME)/builds/sysroot/usr/local/lib/libsodium.dylib
    }
}

unix:!mac {
    CONFIG(release, debug|release) {
        INCLUDEPATH += /usr/local/include
        LIBS += -lczmq -lzyre -lsodium
    }
}

#
# Unix except macOS and iOS
#
unix:!mac {
    message("Scope is unix...")

    #TODO


    ############ Android ###########
    android {

        message("Compilation android scope...")

        INCLUDEPATH += /usr/local/include

        # Add librairies
        libs_path = $$PWD/../dependencies/android/libs-armeabi-v7a

        LIBS += $$quote(-L$$libs_path/) -lczmq -lzyre -llibsodium
    }
}
