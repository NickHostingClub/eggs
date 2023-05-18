#!/bin/sh
set -x
cd /mnt/server

# Download the CA bundle from Mozilla.
curl -O https://curl.se/ca/cacert.pem

# Select the appropriate URL based on the release branch.
if [ "${RELEASE_BRANCH}" = "stable" ]; then
    URL="https://api.vintagestory.at/stable.json"
elif [ ${RELEASE_BRANCH} = "unstable" ]; then
    URL="https://api.vintagestory.at/unstable.json"
elif [ ${RELEASE_BRANCH} = "pre" ]; then
    URL="https://api.vintagestory.at/pre.json"
else
    echo -e "Invalid release branch."
    exit 1
fi

# Retrieve JSON data.
JSON_DATA=$(curl -sS --cacert cacert.pem "$URL")

# Validate JSON data.
echo -e $JSON_DATA | jq empty > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "Received invalid JSON data"
    exit 1
fi

# If the release version is set to "latest," retrieve the latest version number.
if [ "${RELEASE_VERSION}" = "latest" ]; then
    LATEST_KEY=$(echo -e "$JSON_DATA" | jq -r 'to_entries[] | select(any(.value[]; .latest == 1)) | .key')
    if [ -z "$LATEST_KEY" ]; then
        echo -e "Latest version not found"
        exit 1
    else
        RELEASE_VERSION=$LATEST_KEY
    fi
fi

# Find the CDN and local URLs of the files to be downloaded.
CDN_URL=$(echo -e "$JSON_DATA" | jq -r --arg VERSION "$RELEASE_VERSION" '.[$VERSION].server.urls.cdn')
LOCAL_URL=$(echo -e "$JSON_DATA" | jq -r --arg VERSION "$RELEASE_VERSION" '.[$VERSION].server.urls.local')

# Retrieve the MD5 hash.
FILE_MD5=$(echo -e "$JSON_DATA" | jq -r --arg VERSION "$RELEASE_VERSION" '.[$VERSION].server.md5')

check_http_status() {
    local url="$1"
    local http_code=$(curl -sS --cacert cacert.pem -D - "$url" -o /dev/null | head -n 1 | awk '{print $2}')
    echo -e "$http_code"
}

# Verify if the CDN file exists.
HTTP_CODE=$(check_http_status "$CDN_URL")

# If the CDN file does not exist, check the local file.
if [ "$HTTP_CODE" != "200" ]; then
    HTTP_CODE=$(check_http_status "$LOCAL_URL")
    if [ "$HTTP_CODE" = "200" ]; then
        FILE_URL=$LOCAL_URL
    else
        echo -e "File not found"
        exit 1
    fi
else
    FILE_URL=$CDN_URL
fi

if [ ! -d "data" ]; then
  mkdir data
fi

# Check if serverconfig.json exists in the data directory, if not, download it.
if [ ! -f "data/serverconfig.json" ]; then
  curl -sS --cacert cacert.pem -o data/serverconfig.json "https://raw.githubusercontent.com/NickHostingClub/eggs/main/games/VintageStory/serverconfig.json"
fi

curl -sS --cacert cacert.pem "$FILE_URL" -o "vs_server.tar.gz"

# Verify the MD5 hash of the downloaded file.
DOWNLOADED_MD5=$(md5sum "vs_server.tar.gz" | awk '{print $1}')

if [ "$DOWNLOADED_MD5" != "$FILE_MD5" ]; then
    echo -e "MD5 hash does not match, the file may be corrupted or compromised"
    rm "vs_server.tar.gz"
    exit 1
fi

tar xz -f "vs_server.tar.gz"

# Remove the files
rm "vs_server.tar.gz"
rm "cacert.pem"
