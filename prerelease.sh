#!/bin/bash

DEV=FALSE
TAG=""
# parse args for --dev flag or --tag flag
for arg in "$@"; do
    case $arg in
        --dev)
        DEV=TRUE
        shift
        ;;
        --tag=*)
        TAG="${arg#*=}"
        shift
        ;;
        *)
        # Unknown option
        ;;
    esac
done

if [ "$DEV" == "TRUE" ]; then
    echo "Running in development mode"
else
    echo "Running in production mode"
fi

# Determine current tag, if any
if [ -z "$TAG" ]; then
  TAG=$(git describe --tags --abbrev=0)
fi

PROJECT_NAME="pyZoLoaner"

# Pre-Release Checklist
VERSION_TAG=FALSE
MANIFEST=FALSE
CHANGELOG=FALSE
README=FALSE
SET_TAG=FALSE


if [ -z "$TAG" ]; then
    echo "No tags found in the repository. Please create an initial tag before running this script."
    exit 1
fi

# Generate the next release tag possibilities based on the current tag
RLS_PATCH=$(echo $TAG | awk -F. -v OFS=. '{$NF++;print}')
RLS_MINOR=$(echo $TAG | awk -F. -v OFS=. '{$(NF-1)++;$NF=0;print}')
RLS_MAJOR=$(echo $TAG | awk -F. -v OFS=. '{$1++;$2=0;$3=0;print}')

# search CHANGELOG.md and module.json for each RLS version
if grep -q "## \[$RLS_PATCH\]" CHANGELOG.md; then
    RLS_TYPE=1
elif grep -q "## \[$RLS_MINOR\]" CHANGELOG.md; then
    RLS_TYPE=2
elif grep -q "## \[$RLS_MAJOR\]" CHANGELOG.md; then
    RLS_TYPE=3
else
    RLS_TYPE=0
fi

# If no release type is found, prompt the user to select one
if [ $RLS_TYPE -eq 0 ]; then
    echo "No release type found. Please select one:"
    echo "0) Keep current version ($TAG)"
    echo "1) Patch Release ($RLS_PATCH)"
    echo "2) Minor Release ($RLS_MINOR)"
    echo "3) Major Release ($RLS_MAJOR)"
    read -p "Enter your choice (0/1/2/3): " RLS_TYPE
fi

# Set the release tag based on the selected type
case $RLS_TYPE in
    0)
        RELEASE_TAG=$TAG
        VERSION_TAG=TRUE
        RELEASE_TYPE="no"
        ;;
    1)
        RELEASE_TAG=$RLS_PATCH
        VERSION_TAG=TRUE
        RELEASE_TYPE="patch"
        ;;
    2)
        RELEASE_TAG=$RLS_MINOR
        VERSION_TAG=TRUE
        RELEASE_TYPE="minor"
        ;;
    3)
        RELEASE_TAG=$RLS_MAJOR
        VERSION_TAG=TRUE
        RELEASE_TYPE="major"
        ;;
    *)
        echo "Invalid choice. Exiting."
        VERSION_TAG=FALSE
        exit 1
        ;;
esac    

LATEST_CHANGELOG=""
# Add the CHANGELOG entry header if it doesn't exist
# if grep -q "## \[$RELEASE_TAG\]" CHANGELOG.md; then
maxtag=$(grep -oE '## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)
MAX_MAJOR=$(echo $maxtag | cut -d. -f1)
MAX_MINOR=$(echo $maxtag | cut -d. -f2)
MAX_PATCH=$(echo $maxtag | cut -d. -f3)
NEW_MAJOR=$(echo $RELEASE_TAG | cut -d. -f1)
NEW_MINOR=$(echo $RELEASE_TAG | cut -d. -f2)
NEW_PATCH=$(echo $RELEASE_TAG | cut -d. -f3)
LOG_PROBLEM=TRUE
if [ "$NEW_MAJOR" -gt "$MAX_MAJOR" ]; then
    LOG_PROBLEM=FALSE
elif [ "$NEW_MAJOR" -eq "$MAX_MAJOR" ] && [ "$NEW_MINOR" -gt "$MAX_MINOR" ]; then
    LOG_PROBLEM=FALSE
elif [ "$NEW_MAJOR" -eq "$MAX_MAJOR" ] && [ "$NEW_MINOR" -eq "$MAX_MINOR" ] && [ "$NEW_PATCH" -gt "$MAX_PATCH" ]; then
    LOG_PROBLEM=FALSE
elif [ "$NEW_MAJOR" -eq "$MAX_MAJOR" ] && [ "$NEW_MINOR" -eq "$MAX_MINOR" ] && [ "$NEW_PATCH" -eq "$MAX_PATCH" ]; then
    echo "CHANGELOG entry for $RELEASE_TAG already exists"
    LOG_PROBLEM=FALSE
    CHANGELOG=TRUE
    # Grab the complete entry for the current release tag (H2 header and all content until the next H2 header)
    LATEST_CHANGELOG=$(sed -n "/## \[$RELEASE_TAG\]/,/^## /p" CHANGELOG.md | sed '1d')
    # demote the H2 header to H3 for inclusion in README.md
    LATEST_CHANGELOG=$(echo "$LATEST_CHANGELOG" | sed 's/^## /### /')
fi

if ! $LOG_PROBLEM && ! $CHANGELOG; then
    echo "Adding CHANGELOG entry for $RELEASE_TYPE release $RELEASE_TAG"
    echo -e "\n\n## [$RELEASE_TAG](https://github.com/yorkshirelandscape/$PROJECT_NAME/tree/$RELEASE_TAG)<sup>[&Delta;](https://github.com/yorkshirelandscape/$PROJECT_NAME/compare/$(git describe --tags --abbrev=0)...$RELEASE_TAG)</sup> &mdash;&mdash; *$(date +%Y-%m-%d)*\n- <Changes>" >> CHANGELOG.md
    CHANGELOG=FALSE
elif $CHANGELOG && ! $LOG_PROBLEM; then
  if ! grep -q "### \[$RELEASE_TAG\]" README.md; then
    # Grab the complete entry for the current release tag (H2 header and all content until the next H2 header)
    LATEST_CHANGELOG=$(sed -n "/## \[$RELEASE_TAG\]/,/^## /p" CHANGELOG.md | sed '1d')
    # demote the H2 header to H3 for inclusion in README.md
    LATEST_CHANGELOG=$(echo "$LATEST_CHANGELOG" | sed 's/^## /### /')
    echo "Adding CHANGELOG entry for $RELEASE_TAG in README.md"  
    echo "Removing last CHANGELOG entry in README.md"
    # Store everything below the ## Changelog header as REMAINING_CHANGELOG
    REMAINING_CHANGELOG=$(sed -n '/## Changelog/,$p' README.md | sed '1d')
    # Remove the final H2 header and everything below it
    REMAINING_CHANGELOG=$(echo "$REMAINING_CHANGELOG" | sed '/^### /,$d')
    # Append LATEST and REMAINING to the ## Changelog section at the end of README.md
    echo -e "\n\n$LATEST_CHANGELOG\n$REMAINING_CHANGELOG" > README.md
    echo "Changelog updated in README.md"
    README=FALSE
  elif grep -q "### \[$RELEASE_TAG\]" README.md; then
    echo "Changelog entry for $RELEASE_TAG already exists in README.md"
    README=TRUE
  else
    echo "CHANGELOG entry not ready for addition to README.md"
    README=FALSE
  fi
elif $LOG_PROBLEM; then
    echo "CHANGELOG entry for $RELEASE_TAG is missing or out of order. Please update CHANGELOG.md."
    CHANGELOG=FALSE
fi

if $VERSION_TAG && $CHANGELOG && $README; then
    echo "Pre-release checks passed successfully."
    echo "Ready to create release tag: $RELEASE_TAG"
    if [ "$DEV" = "TRUE" ]; then
      echo "DEVELOPMENT MODE: No changes will be committed or tags created."
      echo "Current tag: $TAG"
      echo "Release tag: $RELEASE_TAG"
      echo "Changelog entry added: $CHANGELOG"
      echo "README.md updated with changelog: $README"
      echo "Set tag: $SET_TAG"    
    else
      echo "Ready to release version $RELEASE_TAG?"
      read -p "Press Enter to continue or Ctrl+C to cancel: "
      echo "Committing changes and creating release tag..."
      git add .
      git commit -m "Prepare for release $RELEASE_TAG"
      git push
      echo "Creating release tag: $RELEASE_TAG"
      git tag "$RELEASE_TAG"
      git push --tags
      echo "Release tag $RELEASE_TAG created and pushed successfully."
    fi
else
    echo "Pre-release checks failed. Please review the following:"
    if ! $VERSION_TAG; then echo "- Version tag not set or already exists."; fi
    if ! $CHANGELOG; then echo "- Changelog entry not added."; fi
    if ! $README; then echo "- README.md not updated with changelog."; fi
    exit 1
fi
    
