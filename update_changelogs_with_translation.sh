#!/bin/bash

# Enhanced script to update changelogs with automatic translation
# Usage: ./update_changelogs_with_translation.sh "version" "english_changelog_entry"
# ./update_changelogs_with_translation.sh 0.6.0 "- Version 0.6.0 release
# - Added new NFC features
# - Improved user interface
# - Bug fixes and performance improvements"
# Version can be semantic (0.6.0) or version code (10006)

# Load environment variables from .env file
set -a
source .env
set +a

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 version english_changelog_entry"
    echo "Example: $0 0.6.0 '- Added new NFC features\\n- Improved performance\\n- Bug fixes'"
    exit 1
fi

VERSION=$1
ENGLISH_CHANGELOG=$2

# Convert semantic version to version code if needed
if [[ $VERSION == *.* ]]; then
    # It's a semantic version, convert to version code
    IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    
    # Convert to version code (e.g., 0.6.0 -> 6000)
    VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + PATCH))
else
    # It's already a version code
    VERSION_CODE=$VERSION
fi

# Create directory structure
mkdir -p fastlane/metadata/android/en-US/changelogs

# Create English changelog first
ENGLISH_FILE="fastlane/metadata/android/en-US/changelogs/$VERSION_CODE.txt"
echo -e "$ENGLISH_CHANGELOG" > "$ENGLISH_FILE"
echo "Created English changelog: $ENGLISH_FILE"

# Language mappings for translation
declare -A LANGUAGE_CODES=(
    ["de-DE"]="de"
    ["es-ES"]="es"
    ["fr-FR"]="fr"
    ["it-IT"]="it"
)

# Function to translate text using OpenAI API
translate_text() {
    local text="$1"
    local target_lang="$2"
    
    curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer $OPENAI_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"gpt-4.1-mini\",
        \"messages\": [
        {\"role\": \"system\", \"content\": \"You are a helpful translator.\"},
        {\"role\": \"user\", \"content\": \"Translate the following text to $target_lang: $text\"}
        ]
    }" | jq -r '.choices[0].message.content'

}

# Create changelogs for other languages
for LANG in "${!LANGUAGE_CODES[@]}"; do
    TARGET_LANG=${LANGUAGE_CODES[$LANG]}
    
    # Create directory if it doesn't exist
    mkdir -p "fastlane/metadata/android/$LANG/changelogs"
    
    # Translate each line of the changelog
    TRANSLATED_CHANGELOG=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            translated_line=$(translate_text "$line" "$TARGET_LANG")
            TRANSLATED_CHANGELOG+="$translated_line\n"
        else
            TRANSLATED_CHANGELOG+="\n"
        fi
    done <<< "$ENGLISH_CHANGELOG"
    
    # Write translated changelog
    TRANSLATED_FILE="fastlane/metadata/android/$LANG/changelogs/$VERSION_CODE.txt"
    echo -e "$TRANSLATED_CHANGELOG" > "$TRANSLATED_FILE"
    echo "Created $LANG changelog: $TRANSLATED_FILE"
done

echo "Changelogs created for version $VERSION (code: $VERSION_CODE) across all languages"