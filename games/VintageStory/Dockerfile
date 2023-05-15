FROM mono:latest

LABEL       author="NickChillClub" maintainer="pterodactyl@nickhosting.club"


WORKDIR /home/container

RUN set -x \
    && apt-get update \
    && apt-get dist-upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && adduser --disabled-password --home /home/container container

USER container
ENV  USER=container HOME=/home/container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/sh", "/entrypoint.sh"]
