FROM eclipse-temurin:25

RUN apt-get update && apt-get install -y --no-install-recommends \
	wget \
	unzip \
	gettext \
	curl \
	jq \
	gosu \
	vim \
	less \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN userdel -r ubuntu

VOLUME ["/data"]
WORKDIR /data

COPY --chmod=755 ./scripts /scripts
COPY --chmod=755 ./templates /templates

ENV UID=1000 GID=1000
EXPOSE 5520/udp
HEALTHCHECK --start-period=2m \
			--interval=30s \
			CMD pgrep -f "Server/HytaleServer.jar" > /dev/null || exit 1
ENTRYPOINT ["/scripts/entry.sh"]
