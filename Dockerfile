FROM ubuntu:noble-20240407.1

LABEL org.opencontainers.image.description="See https://github.com/pgulb/landlubber for usage."

RUN apt-get update && apt-get install openssh-client ca-certificates jq curl \
python3 python3-pip -y && \
rm -rf /var/lib/apt/lists/*
RUN pip install ansible --break-system-packages --no-cache-dir
RUN mkdir -p /landlubber
WORKDIR /landlubber
RUN curl -LO https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl \
&& chmod +x kubectl && mv kubectl /usr/local/bin
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
&& chmod +x get_helm.sh && ./get_helm.sh && rm -f ./get_helm.sh
COPY . .
ADD https://github.com/hetznercloud/cli/releases/download/v1.43.0/hcloud-linux-amd64.tar.gz .
RUN tar -xf hcloud-linux-amd64.tar.gz && rm hcloud-linux-amd64.tar.gz README.md LICENSE

CMD [ "./wrapper.sh" ]
