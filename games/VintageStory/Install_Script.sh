#!/bin/sh
set -x

# Download de CA-bundel van Mozilla
curl -O https://curl.se/ca/cacert.pem

# Kies de juiste URL op basis van de release branch
if [ "$RELEASE_BRANCH" = "stable" ]; then
    URL="https://api.vintagestory.at/stable.json"
elif [ "$RELEASE_BRANCH" = "unstable" ]; then
    URL="https://api.vintagestory.at/unstable.json"
elif [ "$RELEASE_BRANCH" = "pre" ]; then
    URL="https://api.vintagestory.at/pre.json"
else
    echo -e "Ongeldige release branch"
    exit 1
fi

# Haal JSON data op
JSON_DATA=$(curl -sS --cacert cacert.pem "$URL")

# Valideer JSON data
echo -e $JSON_DATA | jq empty > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "Ongeldige JSON data ontvangen"
    exit 1
fi

# Als de release version "latest" is, krijg de laatste versie nummer
if [ "$RELEASE_VERSION" = "latest" ]; then
    LATEST_KEY=$(echo -e "$JSON_DATA" | jq -r 'keys[] as $k | select(."$k".latest == 1) | $k')
    RELEASE_VERSION=${LATEST_KEY:-$(echo -e "$JSON_DATA" | jq -r 'keys[0]')}
fi

# Zoek de CDN en de lokale URL van de te downloaden bestanden
CDN_URL=$(echo -e "$JSON_DATA" | jq -r --arg VERSION "$RELEASE_VERSION" '.[$VERSION].server.urls.cdn')
LOCAL_URL=$(echo -e "$JSON_DATA" | jq -r --arg VERSION "$RELEASE_VERSION" '.[$VERSION].server.urls.local')

# Haal de MD5-hash op
FILE_MD5=$(echo -e "$JSON_DATA" | jq -r --arg VERSION "$RELEASE_VERSION" '.[$VERSION].server.md5')

check_http_status() {
    local url="$1"
    local http_code=$(curl -sS --cacert cacert.pem -D - "$url" -o /dev/null | head -n 1 | awk '{print $2}')
    echo -e "$http_code"
}

# Controleer of het CDN bestand bestaat
HTTP_CODE=$(check_http_status "$CDN_URL")

# Als het CDN bestand niet bestaat, controleer het lokale bestand
if [ "$HTTP_CODE" != "200" ]; then
    HTTP_CODE=$(check_http_status "$LOCAL_URL")
    if [ "$HTTP_CODE" = "200" ]; then
        FILE_URL=$LOCAL_URL
    else
        echo -e "Bestand niet gevonden"
        exit 1
    fi
else
    FILE_URL=$CDN_URL
fi

# Verwijder oude data, behalve de data map
#find . -maxdepth 1 ! -name 'data' ! -name '.' -exec rm -rf {} +

# Controleer of data map bestaat, zo niet, maak het aan
if [ ! -d "data" ]; then
  mkdir data
fi

# Controleer of serverconfig.json bestaat in de data map, zo niet, download het
if [ ! -f "data/serverconfig.json" ]; then
  curl -sS --cacert cacert.pem -o data/serverconfig.json "https://raw.githubusercontent.com/NickHostingClub/eggs/main/games/VintageStory/serverconfig.json"
fi

# Download het bestand
curl -sS --cacert cacert.pem "$FILE_URL" -o "vs_server.tar.gz"

# Controleer de MD5-hash van het gedownloade bestand
DOWNLOADED_MD5=$(md5sum "vs_server.tar.gz" | awk '{print $1}')

if [ "$DOWNLOADED_MD5" != "$FILE_MD5" ]; then
    echo -e "MD5-hash komt niet overeen, bestand is mogelijk beschadigd of gecompromitteerd"
    rm "vs_server.tar.gz"
    exit 1
fi

# Pak het bestand uit
tar xz -f "vs_server.tar.gz"

# Verwijder het gedownloade bestand
rm "vs_server.tar.gz"
