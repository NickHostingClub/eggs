#!/bin/ash
set -e

URL="https://cdn.vintagestory.at/gamefiles/stable/vs_server_${VINTAGE_STORY_VERSION}.tar.gz"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL || exit 1)

if [ $HTTP_CODE -eq 200 ]; then
    echo -e "Version number is valid for version ${VINTAGE_STORY_VERSION}. Continuing installation"
else
    echo -e "Version is not valid for version ${VINTAGE_STORY_VERSION}."
    exit 1
fi

cd /mnt/server

# Remove all old files except for 'data' directory
find . -maxdepth 1 ! -name 'data' ! -name '.' -exec rm -rf {} +

echo -e "Downloading version ${URL}"

curl -sSl ${URL} | tar xz

if [ ! -d "data" ]; then
  mkdir data
fi

if [ ! -f data/serverconfig.json ]; then
    echo -e "Downloading Vintage Story serverconfig.json"
    curl -o data/serverconfig.json https://raw.githubusercontent.com/NickHostingClub/eggs/main/games/VintageStory/serverconfig.json
fi
