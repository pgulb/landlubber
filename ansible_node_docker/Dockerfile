FROM eniocarboni/docker-rockylinux-systemd:9

RUN dnf install openssh-server selinux-policy -y
RUN ssh-keygen -A
RUN echo '123' | passwd --stdin root 
ADD sshd_config /etc/ssh/sshd_config
EXPOSE 22
