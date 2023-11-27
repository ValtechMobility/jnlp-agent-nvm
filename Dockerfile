FROM ubuntu:22.04 as fetcher
ENV NVM_VERSION v0.39.5
RUN apt-get update && \
    apt-get install -y git && \
    git clone \
        --depth 1 \
        --branch $NVM_VERSION \
        https://github.com/nvm-sh/nvm.git

FROM jenkins/inbound-agent:alpine as jnlp

FROM jenkins/agent:latest-jdk17

ARG version
LABEL Description="This is a base image, which allows connecting Jenkins agents via JNLP protocols" Vendor="Jenkins project" Version="$version"

ARG user=jenkins

USER root

COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent

RUN chmod +x /usr/local/bin/jenkins-agent &&\
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

# we don't want to store cached files in the image
VOLUME /var/cache/apt

RUN apt-get update \
  && apt-get -y install \
    unzip \
    curl \
    rsync \
    openssh-client \
    ca-certificates-java \
    openjdk-17-jdk \
    graphviz

ENV NVM_DIR=/opt/nvm

# prepare place for binaries symlinks
RUN mkdir -p /home/jenkins/bin && \
    chown -R jenkins:jenkins /home/jenkins/bin
ENV PATH="$PATH:/home/jenkins/bin"

# don't store npm cache in the image
VOLUME ~/.npm

# copy the nvm
COPY --from=fetcher --chown=jenkins:jenkins nvm $NVM_DIR
# copy wrapper scripts
COPY bin /usr/local/bin

USER ${user}

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
