FROM ubuntu:22.04

ENV VSH_VERSION="0.2.1"

RUN apt update && \
    apt install -y openssh-server unzip sudo mysql-client && \
    wget -q https://releases.hashicorp.com/vault-ssh-helper/${VSH_VERSION}/vault-ssh-helper_${VSH_VERSION}_linux_arm.zip && \
    unzip vault-ssh-helper_${VSH_VERSION}_linux_arm.zip -d /usr/local/bin/ && \
    mkdir /etc/vault-helper.d/ /var/run/sshd/ && \
    apt clean

COPY helper-config.hcl /etc/vault-helper.d/config.hcl

RUN useradd -m -s /bin/bash admin && \
    useradd -m -s /bin/bash developer && \
    echo "admin     ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers

RUN sed -i -e 's/^@include common-auth/#@include common-auth/g' /etc/pam.d/sshd && \
    echo 'auth requisite pam_exec.so quiet expose_authtok log=/tmp/vaultssh.log /usr/local/bin/vault-ssh-helper -dev -config=/etc/vault-helper.d/config.hcl' | tee -a /etc/pam.d/sshd && \
    echo 'auth optional pam_unix.so not_set_pass use_first_pass nodelay' | tee -a /etc/pam.d/sshd && \
    sed -i -e 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config && \
    sed -i -e 's/UsePAM no/UsePAM yes/g' /etc/ssh/sshd_config && \
    sed -i -e 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
