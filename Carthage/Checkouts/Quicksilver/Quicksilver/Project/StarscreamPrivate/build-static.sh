#!/bin/sh

# Merge Script

# 1
# Set bash script to exit immediately if any commands fail.
set -e

# 2
# Setup some constants for use later on.
PROEJCT_TO_BUILD="StarscreamPrivate.xcodeproj"
FRAMEWORK_NAME="StarscreamPrivate"
CUSTOM_BUILD_DIR="./build/starscream"
STATIC_LIB_DIR="."

echo "Start building starscream at ${CUSTOM_BUILD_DIR}"

# 3
# If remnants from a previous build exist, delete them.
if [ -d "$CUSTOM_BUILD_DIR" ]; then
rm -rf "$CUSTOM_BUILD_DIR"
fi

# 4
# Clean
xcodebuild -quiet -project $PROEJCT_TO_BUILD -scheme "${FRAMEWORK_NAME}" -derivedDataPath $CUSTOM_BUILD_DIR -configuration Release clean
# Build the framework for device and for simulator (using
# all needed architectures).
xcodebuild -quiet -project $PROEJCT_TO_BUILD -scheme "${FRAMEWORK_NAME}" -configuration Release -arch arm64 -arch armv7 -arch armv7s -arch arm64e only_active_arch=no BITCODE_GENERATION_MODE=bitcode defines_module=yes -derivedDataPath $CUSTOM_BUILD_DIR -sdk "iphoneos" MACH_O_TYPE="staticlib"
xcodebuild -quiet -project $PROEJCT_TO_BUILD -scheme "${FRAMEWORK_NAME}" -configuration Release -arch x86_64 -arch i386 only_active_arch=no BITCODE_GENERATION_MODE=bitcode defines_module=yes -derivedDataPath $CUSTOM_BUILD_DIR -sdk "iphonesimulator" MACH_O_TYPE="staticlib"

# 5
# Remove .framework file if exists in products from previous run.
if [ -d ${STATIC_LIB_DIR} ]; then
rm -rf ${STATIC_LIB_DIR}/${FRAMEWORK_NAME}.framework
else
	mkdir ${STATIC_LIB_DIR}
fi

PRODUCTS_ROOT="${CUSTOM_BUILD_DIR}/Build/Products"

# 6
# Copy the device version of framework to production.
cp -r "${PRODUCTS_ROOT}/Release-iphoneos/${FRAMEWORK_NAME}.framework" "${STATIC_LIB_DIR}/${FRAMEWORK_NAME}.framework"

# 7
# Replace the framework executable within the framework with
# a new version created by merging the device and simulator
# frameworks' executables with lipo.
lipo -create -output "${STATIC_LIB_DIR}/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${PRODUCTS_ROOT}/Release-iphoneos/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}" "${PRODUCTS_ROOT}/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME}"

# 8
# Copy the Swift module mappings for the simulator into the
# framework.  The device mappings already exist from step 6.
cp -r "${PRODUCTS_ROOT}/Release-iphonesimulator/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${STATIC_LIB_DIR}/${FRAMEWORK_NAME}.framework/Modules/${FRAMEWORK_NAME}.swiftmodule/"

# 9
# Delete the most recent build.
if [ -d "${CUSTOM_BUILD_DIR}" ]; then
rm -rf "${CUSTOM_BUILD_DIR}"
fi

