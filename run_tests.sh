#!/bin/bash
# GDUnit4 Test Runner
# Usage: ./run_tests.sh [options]

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try to find Godot executable
if command -v godot &> /dev/null; then
    GODOT="godot"
elif [ -f "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
    echo "Error: Godot executable not found"
    echo "Please install Godot or add it to your PATH"
    exit 1
fi

# Run GDUnit4 tests
echo "Running GDUnit4 tests..."
echo "Godot: $GODOT"
echo "Project: $SCRIPT_DIR"
echo ""

# If no arguments provided, run all tests in tests/ directory
if [ $# -eq 0 ]; then
    "$GODOT" -s "$SCRIPT_DIR/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
        --path "$SCRIPT_DIR" \
        --add "$SCRIPT_DIR/tests" \
        --continue
else
    # Pass through any arguments
    "$GODOT" -s "$SCRIPT_DIR/addons/gdUnit4/bin/GdUnitCmdTool.gd" \
        --path "$SCRIPT_DIR" \
        "$@"
fi

# Capture exit code
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All tests passed!"
else
    echo "❌ Tests failed with exit code: $EXIT_CODE"
fi

exit $EXIT_CODE
