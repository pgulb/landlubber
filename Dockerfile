FROM ubuntu:noble-20240407.1

LABEL org.opencontainers.image.description "See https://github.com/pgulb/landlubber for usage."

RUN apt-get update && apt-get install openssh-client ca-certificates jq -y && \
rm -rf /var/lib/apt/lists/*
RUN mkdir -p /landlubber
WORKDIR /landlubber
COPY . .
ADD https://github.com/hetznercloud/cli/releases/download/v1.43.0/hcloud-linux-amd64.tar.gz .
RUN tar -xf hcloud-linux-amd64.tar.gz && rm hcloud-linux-amd64.tar.gz README.md LICENSE

CMD [ "./wrapper.sh" ]
