#!/bin/bash

echo "Fixing Firebase header files..."

# Fix FirebaseAppCheckInterop.h
APP_CHECK_HEADER="Pods/FirebaseAppCheckInterop/FirebaseAppCheck/Interop/Public/FirebaseAppCheckInterop/FirebaseAppCheckInterop.h"
if [ -f "$APP_CHECK_HEADER" ]; then
    echo "Fixing $APP_CHECK_HEADER"
    sed -i '' 's/"FIRAppCheckInterop.h"/<FirebaseAppCheckInterop\/FIRAppCheckInterop.h>/g' "$APP_CHECK_HEADER"
    sed -i '' 's/"FIRAppCheckTokenResultInterop.h"/<FirebaseAppCheckInterop\/FIRAppCheckTokenResultInterop.h>/g' "$APP_CHECK_HEADER"
    echo "Fixed $APP_CHECK_HEADER"
fi

# Fix umbrella header
UMBRELLA_HEADER="Pods/Target Support Files/FirebaseAppCheckInterop/FirebaseAppCheckInterop-umbrella.h"
if [ -f "$UMBRELLA_HEADER" ]; then
    echo "Fixing $UMBRELLA_HEADER"
    sed -i '' 's/"FIRAppCheckInterop.h"/<FirebaseAppCheckInterop\/FIRAppCheckInterop.h>/g' "$UMBRELLA_HEADER"
    sed -i '' 's/"FIRAppCheckTokenResultInterop.h"/<FirebaseAppCheckInterop\/FIRAppCheckTokenResultInterop.h>/g' "$UMBRELLA_HEADER"
    sed -i '' 's/"FirebaseAppCheckInterop.h"/<FirebaseAppCheckInterop\/FirebaseAppCheckInterop.h>/g' "$UMBRELLA_HEADER"
    echo "Fixed $UMBRELLA_HEADER"
fi

echo "Header fixes completed!"
