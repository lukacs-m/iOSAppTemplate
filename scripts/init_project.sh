#!/bin/bash

# =============================================================================
# iOS App Template - Project Initialization Script
# =============================================================================
# This script initializes the iOS App Template project with a new name and bundle ID.
# It updates all necessary files, folders, configurations, app groups, and removes
# the template's git remote origin so you can set up your own repository.
#
# Usage: ./scripts/init_project.sh <NewProjectName> <com.company.bundleid>
#
# Example: ./scripts/init_project.sh MyAwesomeApp com.mycompany.myawesomeapp
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Current template values
OLD_PROJECT_NAME="iOSAppTemplate"
OLD_BUNDLE_ID="com.mlukacs.iOSAppTemplate"
OLD_APP_GROUP="group.${OLD_BUNDLE_ID}"

# Print functions
print_info() {
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

print_step() {
    echo -e "\n${GREEN}==> ${NC}$1"
}

# Validation functions
validate_project_name() {
    local name="$1"
    
    # Check if empty
    if [[ -z "$name" ]]; then
        print_error "Project name cannot be empty"
        return 1
    fi
    
    # Check if starts with a letter
    if [[ ! "$name" =~ ^[A-Za-z] ]]; then
        print_error "Project name must start with a letter"
        return 1
    fi
    
    # Check for valid characters (letters, numbers, no spaces or special chars)
    if [[ ! "$name" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
        print_error "Project name can only contain letters and numbers (no spaces or special characters)"
        return 1
    fi
    
    # Check minimum length
    if [[ ${#name} -lt 2 ]]; then
        print_error "Project name must be at least 2 characters long"
        return 1
    fi
    
    return 0
}

validate_bundle_id() {
    local bundle_id="$1"
    
    # Check if empty
    if [[ -z "$bundle_id" ]]; then
        print_error "Bundle ID cannot be empty"
        return 1
    fi
    
    # Check format (reverse domain notation)
    if [[ ! "$bundle_id" =~ ^[a-zA-Z][a-zA-Z0-9-]*(\.[a-zA-Z][a-zA-Z0-9-]*)+$ ]]; then
        print_error "Bundle ID must be in reverse domain notation (e.g., com.company.appname)"
        return 1
    fi
    
    return 0
}

# Usage information
show_usage() {
    echo "Usage: $0 <NewProjectName> <BundleIdentifier>"
    echo ""
    echo "Arguments:"
    echo "  NewProjectName    The new name for your project (e.g., MyAwesomeApp)"
    echo "                    - Must start with a letter"
    echo "                    - Can only contain letters and numbers"
    echo "                    - No spaces or special characters"
    echo ""
    echo "  BundleIdentifier  The bundle identifier for your app (e.g., com.company.myapp)"
    echo "                    - Must be in reverse domain notation"
    echo "                    - Each segment must start with a letter"
    echo ""
    echo "Example:"
    echo "  $0 MyAwesomeApp com.mycompany.myawesomeapp"
    echo ""
}

# Check arguments
if [[ $# -ne 2 ]]; then
    print_error "Invalid number of arguments"
    echo ""
    show_usage
    exit 1
fi

NEW_PROJECT_NAME="$1"
NEW_BUNDLE_ID="$2"
NEW_APP_GROUP="group.${NEW_BUNDLE_ID}"

# Validate inputs
print_info "Validating inputs..."

if ! validate_project_name "$NEW_PROJECT_NAME"; then
    echo ""
    show_usage
    exit 1
fi

if ! validate_bundle_id "$NEW_BUNDLE_ID"; then
    echo ""
    show_usage
    exit 1
fi

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if we're in the right directory
if [[ ! -d "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj" ]]; then
    print_error "Could not find $OLD_PROJECT_NAME.xcodeproj in $PROJECT_ROOT"
    print_error "Make sure you're running this script from the project root or scripts folder"
    exit 1
fi

# Check if already renamed
if [[ ! -d "$PROJECT_ROOT/$OLD_PROJECT_NAME" ]]; then
    print_error "Project appears to have already been initialized (source folder '$OLD_PROJECT_NAME' not found)"
    exit 1
fi

echo ""
echo "=============================================="
echo "  iOS App Template - Project Initialization"
echo "=============================================="
echo ""
echo "  Current project name: $OLD_PROJECT_NAME"
echo "  New project name:     $NEW_PROJECT_NAME"
echo ""
echo "  Current bundle ID:    $OLD_BUNDLE_ID"
echo "  New bundle ID:        $NEW_BUNDLE_ID"
echo ""
echo "  Current app group:    $OLD_APP_GROUP"
echo "  New app group:        $NEW_APP_GROUP"
echo ""
echo "  Project root:         $PROJECT_ROOT"
echo ""
echo "  Git remote origin will be removed"
echo ""
echo "=============================================="
echo ""

# Confirmation prompt
read -p "Do you want to proceed with the initialization? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Operation cancelled"
    exit 0
fi

echo ""

# -----------------------------------------------------------------------------
# Step 1: Replace content in files
# -----------------------------------------------------------------------------
print_step "Step 1: Replacing content in files..."

# Function to safely replace content in a file
replace_in_file() {
    local file="$1"
    local old="$2"
    local new="$3"
    
    if [[ -f "$file" ]]; then
        if grep -q "$old" "$file" 2>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|$old|$new|g" "$file"
            else
                sed -i "s|$old|$new|g" "$file"
            fi
            print_info "Updated: $file"
        fi
    fi
}

# Replace bundle identifiers first (more specific strings)
print_info "Replacing bundle identifiers..."

# Main bundle ID
replace_in_file "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/project.pbxproj" \
    "$OLD_BUNDLE_ID" "$NEW_BUNDLE_ID"

# Tests bundle ID (derived from main)
OLD_TESTS_BUNDLE="${OLD_BUNDLE_ID}Tests"
NEW_TESTS_BUNDLE="${NEW_BUNDLE_ID}Tests"
replace_in_file "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/project.pbxproj" \
    "$OLD_TESTS_BUNDLE" "$NEW_TESTS_BUNDLE"

# UI Tests bundle ID
OLD_UITESTS_BUNDLE="${OLD_BUNDLE_ID}UITests"
NEW_UITESTS_BUNDLE="${NEW_BUNDLE_ID}UITests"
replace_in_file "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/project.pbxproj" \
    "$OLD_UITESTS_BUNDLE" "$NEW_UITESTS_BUNDLE"

# App Group identifier
print_info "Replacing app group identifiers..."
replace_in_file "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/project.pbxproj" \
    "$OLD_APP_GROUP" "$NEW_APP_GROUP"
replace_in_file "$PROJECT_ROOT/$OLD_PROJECT_NAME/$OLD_PROJECT_NAME.entitlements" \
    "$OLD_APP_GROUP" "$NEW_APP_GROUP"

# Replace project names in all relevant files
print_info "Replacing project names..."

# List of files to update (order matters - longer matches first)
FILES_TO_UPDATE=(
    "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/project.pbxproj"
    "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/xcshareddata/xcschemes/$OLD_PROJECT_NAME.xcscheme"
    "$PROJECT_ROOT/.swiftlint.yml"
    "$PROJECT_ROOT/.periphery.yml"
    "$PROJECT_ROOT/fastlane/Fastfile"
    "$PROJECT_ROOT/TestPlan/$OLD_PROJECT_NAME.xctestplan"
    "$PROJECT_ROOT/$OLD_PROJECT_NAME/${OLD_PROJECT_NAME}App.swift"
    "$PROJECT_ROOT/${OLD_PROJECT_NAME}Tests/${OLD_PROJECT_NAME}Tests.swift"
    "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests/${OLD_PROJECT_NAME}UITests.swift"
    "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests/${OLD_PROJECT_NAME}UITestsLaunchTests.swift"
)

# Replace longer strings first to avoid partial replacements
# Order: UITestsLaunchTests > UITests > Tests > App > Base
for file in "${FILES_TO_UPDATE[@]}"; do
    if [[ -f "$file" ]]; then
        # Replace in order from longest to shortest match
        replace_in_file "$file" "${OLD_PROJECT_NAME}UITestsLaunchTests" "${NEW_PROJECT_NAME}UITestsLaunchTests"
        replace_in_file "$file" "${OLD_PROJECT_NAME}UITests" "${NEW_PROJECT_NAME}UITests"
        replace_in_file "$file" "${OLD_PROJECT_NAME}Tests" "${NEW_PROJECT_NAME}Tests"
        replace_in_file "$file" "${OLD_PROJECT_NAME}App" "${NEW_PROJECT_NAME}App"
        replace_in_file "$file" "${OLD_PROJECT_NAME}" "${NEW_PROJECT_NAME}"
    fi
done

print_success "Content replacement complete"

# -----------------------------------------------------------------------------
# Step 2: Rename files
# -----------------------------------------------------------------------------
print_step "Step 2: Renaming files..."

# Rename Swift files
rename_file() {
    local old_path="$1"
    local new_path="$2"
    
    if [[ -f "$old_path" ]]; then
        mv "$old_path" "$new_path"
        print_info "Renamed: $(basename "$old_path") -> $(basename "$new_path")"
    elif [[ -d "$old_path" ]]; then
        mv "$old_path" "$new_path"
        print_info "Renamed: $(basename "$old_path")/ -> $(basename "$new_path")/"
    fi
}

# Rename source files
rename_file "$PROJECT_ROOT/$OLD_PROJECT_NAME/${OLD_PROJECT_NAME}App.swift" \
            "$PROJECT_ROOT/$OLD_PROJECT_NAME/${NEW_PROJECT_NAME}App.swift"

rename_file "$PROJECT_ROOT/$OLD_PROJECT_NAME/${OLD_PROJECT_NAME}.entitlements" \
            "$PROJECT_ROOT/$OLD_PROJECT_NAME/${NEW_PROJECT_NAME}.entitlements"

rename_file "$PROJECT_ROOT/${OLD_PROJECT_NAME}Tests/${OLD_PROJECT_NAME}Tests.swift" \
            "$PROJECT_ROOT/${OLD_PROJECT_NAME}Tests/${NEW_PROJECT_NAME}Tests.swift"

rename_file "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests/${OLD_PROJECT_NAME}UITests.swift" \
            "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests/${NEW_PROJECT_NAME}UITests.swift"

rename_file "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests/${OLD_PROJECT_NAME}UITestsLaunchTests.swift" \
            "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests/${NEW_PROJECT_NAME}UITestsLaunchTests.swift"

# Rename scheme file
rename_file "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/xcshareddata/xcschemes/$OLD_PROJECT_NAME.xcscheme" \
            "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj/xcshareddata/xcschemes/$NEW_PROJECT_NAME.xcscheme"

# Rename test plan
rename_file "$PROJECT_ROOT/TestPlan/$OLD_PROJECT_NAME.xctestplan" \
            "$PROJECT_ROOT/TestPlan/$NEW_PROJECT_NAME.xctestplan"

print_success "File renaming complete"

# -----------------------------------------------------------------------------
# Step 3: Rename folders
# -----------------------------------------------------------------------------
print_step "Step 3: Renaming folders..."

# Rename folders (order matters - rename inner folders before outer)
rename_file "$PROJECT_ROOT/${OLD_PROJECT_NAME}UITests" \
            "$PROJECT_ROOT/${NEW_PROJECT_NAME}UITests"

rename_file "$PROJECT_ROOT/${OLD_PROJECT_NAME}Tests" \
            "$PROJECT_ROOT/${NEW_PROJECT_NAME}Tests"

rename_file "$PROJECT_ROOT/$OLD_PROJECT_NAME" \
            "$PROJECT_ROOT/$NEW_PROJECT_NAME"

# Rename xcodeproj last
rename_file "$PROJECT_ROOT/$OLD_PROJECT_NAME.xcodeproj" \
            "$PROJECT_ROOT/$NEW_PROJECT_NAME.xcodeproj"

print_success "Folder renaming complete"

# -----------------------------------------------------------------------------
# Step 4: Update any remaining references in renamed files
# -----------------------------------------------------------------------------
print_step "Step 4: Updating references in renamed files..."

# Update the test plan reference to the renamed test plan
replace_in_file "$PROJECT_ROOT/$NEW_PROJECT_NAME.xcodeproj/xcshareddata/xcschemes/$NEW_PROJECT_NAME.xcscheme" \
    "$OLD_PROJECT_NAME.xctestplan" "$NEW_PROJECT_NAME.xctestplan"

# Update the entitlements file reference
replace_in_file "$PROJECT_ROOT/$NEW_PROJECT_NAME.xcodeproj/project.pbxproj" \
    "$OLD_PROJECT_NAME.entitlements" "$NEW_PROJECT_NAME.entitlements"

# Make sure project.pbxproj has all references updated
PBXPROJ="$PROJECT_ROOT/$NEW_PROJECT_NAME.xcodeproj/project.pbxproj"
if [[ -f "$PBXPROJ" ]]; then
    replace_in_file "$PBXPROJ" "${OLD_PROJECT_NAME}UITestsLaunchTests" "${NEW_PROJECT_NAME}UITestsLaunchTests"
    replace_in_file "$PBXPROJ" "${OLD_PROJECT_NAME}UITests" "${NEW_PROJECT_NAME}UITests"
    replace_in_file "$PBXPROJ" "${OLD_PROJECT_NAME}Tests" "${NEW_PROJECT_NAME}Tests"
    replace_in_file "$PBXPROJ" "${OLD_PROJECT_NAME}App" "${NEW_PROJECT_NAME}App"
    replace_in_file "$PBXPROJ" "${OLD_PROJECT_NAME}" "${NEW_PROJECT_NAME}"
fi

print_success "Reference updates complete"

# -----------------------------------------------------------------------------
# Step 5: Remove git remote origin
# -----------------------------------------------------------------------------
print_step "Step 5: Removing git remote origin..."

cd "$PROJECT_ROOT"
if git remote | grep -q "^origin$"; then
    git remote remove origin
    print_success "Git remote 'origin' removed"
else
    print_info "No git remote 'origin' found, skipping"
fi

# -----------------------------------------------------------------------------
# Complete
# -----------------------------------------------------------------------------
echo ""
echo "=============================================="
echo -e "${GREEN}  Project initialized successfully!${NC}"
echo "=============================================="
echo ""
echo "  New project name: $NEW_PROJECT_NAME"
echo "  New bundle ID:    $NEW_BUNDLE_ID"
echo "  New app group:    $NEW_APP_GROUP"
echo ""
echo "  Next steps:"
echo "  1. Open $NEW_PROJECT_NAME.xcodeproj in Xcode"
echo "  2. Clean build folder (Cmd+Shift+K)"
echo "  3. Build the project (Cmd+B)"
echo "  4. Update fastlane/Appfile with your Apple ID and team settings"
echo "  5. Add your new git remote: git remote add origin <your-repo-url>"
echo ""
echo "=============================================="
echo ""

print_success "Done!"
