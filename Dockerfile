FROM ubuntu:noble-20240407.1

LABEL org.opencontainers.image.description="See https://github.com/pgulb/landlubber for usage."
ENV PATH="$PATH:/landlubber/bin"
ENV ANSIBLE_STDOUT_CALLBACK=yaml

RUN apt-get update && apt-get install openssh-client ca-certificates jq curl \
python3 python3-pip -y && \
rm -rf /var/lib/apt/lists/*
RUN pip install ansible --break-system-packages --no-cache-dir
RUN mkdir -p /landlubber
WORKDIR /landlubber
RUN mkdir -p /etc/ansible && echo '[defaults]\n' > /etc/ansible/ansible.cfg && \
echo 'stdout_callback = yaml' >> /etc/ansible/ansible.cfg
RUN sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d
ADD ./scripts/get_kubectl.sh .
RUN ./get_kubectl.sh && rm -f ./get_kubectl.sh
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
&& chmod +x get_helm.sh && ./get_helm.sh && rm -f ./get_helm.sh
COPY . .

CMD [ "./wrapper.sh" ]
