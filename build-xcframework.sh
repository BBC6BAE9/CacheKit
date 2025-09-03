#!/bin/bash

# Universal XCFramework Build Script for Swift Package Manager
# Based on: https://davidwanderer.github.io/Blog/2024/05/12/%E5%A6%82%E4%BD%95%E5%B0%86Swift-Package%E7%BC%96%E8%AF%91%E6%88%90XCFramework/
# Supports: iOS, iOS Simulator, macOS, tvOS, tvOS Simulator, visionOS, visionOS Simulator

set -x
set -e

# Configuration
NAME=${1:-"CacheKit"}  # Pass scheme name as the first argument, default to CacheKit
BUILD_DIR="build"
XCFRAMEWORK_OUTPUT="${BUILD_DIR}/${NAME}.xcframework"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Clean build directory
clean_build_dir() {
    print_status "Cleaning build directory..."
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
    mkdir -p "$BUILD_DIR"
    print_success "Build directory cleaned"
}

# Backup and modify Package.swift for dynamic library
modify_package_swift() {
    print_status "Modifying Package.swift for dynamic library..."
    
    # Backup original Package.swift
    cp Package.swift Package.swift.backup
    
    # Remove existing type declarations and add dynamic type
    perl -i -p0e 's/type: \.static,//g' Package.swift
    perl -i -p0e 's/type: \.dynamic,//g' Package.swift
    perl -i -p0e 's/(library[^,]*,)/$1 type: .dynamic,/g' Package.swift
    
    print_success "Package.swift modified for dynamic library"
}

# Restore Package.swift
restore_package_swift() {
    print_status "Restoring original Package.swift..."
    if [ -f "Package.swift.backup" ]; then
        mv Package.swift.backup Package.swift
        print_success "Package.swift restored"
    fi
}

# Build framework for specific platform
build_framework() {
    local PLATFORM=$1
    local DESTINATION=$2
    local ARCHIVE_NAME=$3
    
    print_status "Building framework for $PLATFORM..."
    
    local ARCHIVE_PATH="${BUILD_DIR}/${ARCHIVE_NAME}.xcarchive"
    
    case $PLATFORM in
    "iOS")
        RELEASE_FOLDER="Release-iphoneos"
        ;;
    "iOS Simulator")
        RELEASE_FOLDER="Release-iphonesimulator"
        ;;
    "macOS")
        RELEASE_FOLDER="Release-macosx"
        ;;
    "tvOS")
        RELEASE_FOLDER="Release-appletvos"
        ;;
    "tvOS Simulator")
        RELEASE_FOLDER="Release-appletvsimulator"
        ;;
    "visionOS")
        RELEASE_FOLDER="Release-xros"
        ;;
    "visionOS Simulator")
        RELEASE_FOLDER="Release-xrsimulator"
        ;;
    *)
        print_error "Unknown platform: $PLATFORM"
        return 1
        ;;
    esac
    
    # Build the framework
    xcodebuild archive \
        -workspace . \
        -scheme "$NAME" \
        -destination "$DESTINATION" \
        -archivePath "$ARCHIVE_PATH" \
        -derivedDataPath "${BUILD_DIR}/.build" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    
    if [ $? -ne 0 ]; then
        print_error "Failed to build framework for $PLATFORM"
        return 1
    fi
    
    print_success "Successfully built framework for $PLATFORM"
    
    # Post-process the framework
    post_process_framework "$PLATFORM" "$ARCHIVE_PATH" "$RELEASE_FOLDER"
    
    return 0
}

# Post-process framework to add modules and resources
post_process_framework() {
    local PLATFORM=$1
    local ARCHIVE_PATH=$2
    local RELEASE_FOLDER=$3
    
    print_status "Post-processing framework for $PLATFORM..."
    
    local FRAMEWORK_PATH="$ARCHIVE_PATH/Products/usr/local/lib/$NAME.framework"
    local MODULES_PATH="$FRAMEWORK_PATH/Modules"
    
    # Create Modules directory
    mkdir -p "$MODULES_PATH"
    
    local BUILD_PRODUCTS_PATH="${BUILD_DIR}/.build/Build/Intermediates.noindex/ArchiveIntermediates/$NAME/BuildProductsPath"
    local RELEASE_PATH="$BUILD_PRODUCTS_PATH/$RELEASE_FOLDER"
    local SWIFT_MODULE_PATH="$RELEASE_PATH/$NAME.swiftmodule"
    local RESOURCES_BUNDLE_PATH="$RELEASE_PATH/${NAME}_${NAME}.bundle"
    
    # Copy Swift modules
    if [ -d "$SWIFT_MODULE_PATH" ]; then
        cp -r "$SWIFT_MODULE_PATH" "$MODULES_PATH"
        print_success "Swift modules copied for $PLATFORM"
    else
        # In case there are no modules, assume C/ObjC library and create module map
        echo "module $NAME { export * }" > "$MODULES_PATH/module.modulemap"
        print_warning "No Swift modules found for $PLATFORM, created basic module map"
    fi
    
    # Copy resources bundle, if exists
    if [ -e "$RESOURCES_BUNDLE_PATH" ]; then
        cp -r "$RESOURCES_BUNDLE_PATH" "$FRAMEWORK_PATH"
        print_success "Resources bundle copied for $PLATFORM"
    fi
    
    # Copy additional Swift module files
    local DERIVED_DATA_DIR="${BUILD_DIR}/.build"
    find "$DERIVED_DATA_DIR" -name "${NAME}.swiftinterface" -exec cp {} "$MODULES_PATH/" \; 2>/dev/null || true
    find "$DERIVED_DATA_DIR" -name "${NAME}.swiftdoc" -exec cp {} "$MODULES_PATH/" \; 2>/dev/null || true
    find "$DERIVED_DATA_DIR" -name "${NAME}.swiftsourceinfo" -exec cp {} "$MODULES_PATH/" \; 2>/dev/null || true
    find "$DERIVED_DATA_DIR" -name "${NAME}.abi.json" -exec cp {} "$MODULES_PATH/" \; 2>/dev/null || true
    
    # Copy Swift generated header
    local HEADERS_PATH="$FRAMEWORK_PATH/Headers"
    mkdir -p "$HEADERS_PATH"
    find "$DERIVED_DATA_DIR" -name "${NAME}-Swift.h" -exec cp {} "$HEADERS_PATH/" \; 2>/dev/null || true
    
    print_success "Framework post-processing completed for $PLATFORM"
}

# Check if platform SDK is available
check_platform_sdk() {
    local platform=$1
    xcodebuild -showsdks | grep -q "$platform" 2>/dev/null
    return $?
}

# Main execution
main() {
    print_status "Starting Universal XCFramework build process..."
    print_status "============================================================"
    print_status "Target: $NAME"
    print_status "Based on: https://davidwanderer.github.io/Blog/2024/05/12/如何将Swift-Package编译成XCFramework/"
    print_status "============================================================"
    
    # Clean build directory
    clean_build_dir
    
    # Modify Package.swift for dynamic library
    modify_package_swift
    
    # Trap to restore Package.swift on exit
    trap restore_package_swift EXIT
    
    # Arrays to store framework paths
    FRAMEWORK_PATHS=()
    
    print_status "Building frameworks for all available platforms..."
    
    # iOS Device
    if build_framework "iOS" "generic/platform=iOS" "ios-device"; then
        FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/ios-device.xcarchive/Products/usr/local/lib/$NAME.framework")
    fi
    
    # iOS Simulator
    if build_framework "iOS Simulator" "generic/platform=iOS Simulator" "ios-simulator"; then
        FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/ios-simulator.xcarchive/Products/usr/local/lib/$NAME.framework")
    fi
    
    # macOS
    if build_framework "macOS" "generic/platform=macOS" "macos"; then
        FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/macos.xcarchive/Products/usr/local/lib/$NAME.framework")
    fi
    
    # tvOS Device (only if SDK is available)
    if check_platform_sdk "tvos"; then
        if build_framework "tvOS" "generic/platform=tvOS" "tvos-device"; then
            FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/tvos-device.xcarchive/Products/usr/local/lib/$NAME.framework")
        fi
    else
        print_warning "tvOS SDK not available, skipping tvOS Device build"
    fi
    
    # tvOS Simulator (only if SDK is available)
    if check_platform_sdk "tvos"; then
        if build_framework "tvOS Simulator" "generic/platform=tvOS Simulator" "tvos-simulator"; then
            FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/tvos-simulator.xcarchive/Products/usr/local/lib/$NAME.framework")
        fi
    else
        print_warning "tvOS SDK not available, skipping tvOS Simulator build"
    fi
    
    # visionOS Device (only if SDK is available)
    if check_platform_sdk "xros"; then
        if build_framework "visionOS" "generic/platform=visionOS" "visionos-device"; then
            FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/visionos-device.xcarchive/Products/usr/local/lib/$NAME.framework")
        fi
    else
        print_warning "visionOS SDK not available, skipping visionOS Device build"
    fi
    
    # visionOS Simulator (only if SDK is available)
    if check_platform_sdk "xros"; then
        if build_framework "visionOS Simulator" "generic/platform=visionOS Simulator" "visionos-simulator"; then
            FRAMEWORK_PATHS+=("-framework" "${BUILD_DIR}/visionos-simulator.xcarchive/Products/usr/local/lib/$NAME.framework")
        fi
    else
        print_warning "visionOS SDK not available, skipping visionOS Simulator build"
    fi
    
    # Create XCFramework
    if [ ${#FRAMEWORK_PATHS[@]} -eq 0 ]; then
        print_error "No frameworks were successfully built"
        exit 1
    fi
    
    print_status "Creating XCFramework with ${#FRAMEWORK_PATHS[@]} frameworks..."
    
    xcodebuild -create-xcframework \
        "${FRAMEWORK_PATHS[@]}" \
        -output "$XCFRAMEWORK_OUTPUT"
    
    if [ $? -eq 0 ]; then
        print_success "============================================================"
        print_success "XCFramework created successfully!"
        print_success "Output: $XCFRAMEWORK_OUTPUT"
        print_success "============================================================"
        
        # Show XCFramework info
        print_status "XCFramework contents:"
        find "$XCFRAMEWORK_OUTPUT" -name "*.framework" | while read framework; do
            platform=$(basename "$(dirname "$framework")")
            print_status "  ✅ $platform: $(basename "$framework")"
        done
        
        # Get file size
        XCFRAMEWORK_SIZE=$(du -h "$XCFRAMEWORK_OUTPUT" | cut -f1)
        print_status "XCFramework size: $XCFRAMEWORK_SIZE"
        
        # Create ZIP archive for distribution
        print_status "Creating ZIP archive for distribution..."
        ZIP_OUTPUT="${BUILD_DIR}/${NAME}.xcframework.zip"
        
        cd "$BUILD_DIR"
        zip -r "${NAME}.xcframework.zip" "${NAME}.xcframework"
        cd - > /dev/null
        
        if [ -f "$ZIP_OUTPUT" ]; then
            ZIP_SIZE=$(du -h "$ZIP_OUTPUT" | cut -f1)
            print_success "ZIP archive created: $ZIP_OUTPUT (Size: $ZIP_SIZE)"
            
            # Calculate and display checksum
            print_status "Calculating SHA256 checksum..."
            CHECKSUM=$(shasum -a 256 "$ZIP_OUTPUT" | cut -d' ' -f1)
            print_status "SHA256 Checksum: $CHECKSUM"
            echo "$CHECKSUM" > "${ZIP_OUTPUT}.checksum"
            print_status "Checksum saved to: ${ZIP_OUTPUT}.checksum"
        else
            print_error "Failed to create ZIP archive"
        fi
        
        print_success ""
        print_success "🎉 Build completed successfully!"
        print_success ""
        print_status "Generated files:"
        print_status "  📦 XCFramework: $XCFRAMEWORK_OUTPUT"
        print_status "  🗜️ ZIP Archive: $ZIP_OUTPUT"
        print_status "  🔐 Checksum: ${ZIP_OUTPUT}.checksum"
        print_success ""
        print_status "Next steps:"
        print_status "1. Drag $XCFRAMEWORK_OUTPUT to your Xcode project"
        print_status "2. Add to 'Frameworks, Libraries, and Embedded Content'"
        print_status "3. Set embedding option as needed"
        print_status "4. Import $NAME in your Swift files"
        print_status "5. For SPM binary target, use $ZIP_OUTPUT"
        print_success ""
        print_status "Based on tutorial: https://davidwanderer.github.io/Blog/2024/05/12/如何将Swift-Package编译成XCFramework/"
    else
        print_error "Failed to create XCFramework"
        exit 1
    fi
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [SCHEME_NAME]"
    echo "Example: $0 CacheKit"
    echo ""
    echo "This script builds a universal XCFramework for Swift Package Manager projects."
    echo "Based on: https://davidwanderer.github.io/Blog/2024/05/12/如何将Swift-Package编译成XCFramework/"
    echo ""
    echo "Supported platforms:"
    echo "  - iOS Device (arm64)"
    echo "  - iOS Simulator (arm64, x86_64)"
    echo "  - macOS (arm64, x86_64)"
    echo "  - tvOS Device (arm64) - if SDK available"
    echo "  - tvOS Simulator (arm64, x86_64) - if SDK available"
    echo "  - visionOS Device (arm64) - if SDK available"
    echo "  - visionOS Simulator (arm64, x86_64) - if SDK available"
    echo ""
    exit 1
fi

# Run main function
main "$@"
