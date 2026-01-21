FROM eclipse-temurin:25

RUN apt-get update && apt-get install -y --no-install-recommends \
	wget \
	unzip \
	gettext \
	curl \
	jq \
	vim \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN userdel -r ubuntu
RUN addgroup --gid 1000 hytale
RUN adduser --system --shell /bin/false --uid 1000 --ingroup hytale --home /data hytale

RUN chown hytale:hytale /data
VOLUME ["/data"]
WORKDIR /data

COPY --chmod=755 ./scripts /scripts
COPY --chmod=755 ./templates /templates
RUN /scripts/root/setup_machine_id.sh

USER hytale
EXPOSE 5520/udp
HEALTHCHECK --start-period=2m \
			--interval=30s \
			CMD pgrep -f "Server/HytaleServer.jar" > /dev/null || exit 1
ENTRYPOINT ["/scripts/entry.sh"]
