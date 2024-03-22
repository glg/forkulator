# syntax=docker/dockerfile:1.3-labs
FROM ubuntu:14.04

# install shared packages that will be used by other steps
RUN <<DOC
apt-get update
apt-get install smbclient --assume-yes
apt-get install jq --assume-yes
apt-get install bc --assume-yes
apt-get install curl --assume-yes
apt-get install ssh --assume-yes
apt-get install unzip --assume-yes
rm -rf /var/lib/apt/lists/*
DOC

# Install AWS CLI v2
RUN <<DOC
  set -e
  curl -sL https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
  rm -rf /tmp/awscliv2.zip /tmp/aws
DOC

# Install Node 5.x
RUN <<DOC
#apt-get --assume-yes install nodejs npm
curl -fsSL https://deb.nodesource.com/setup_5.x | bash - &&\
apt-get install -y --force-yes nodejs
DOC

ENV TINI_VERSION v0.19.0
ARG TARGETARCH
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${TARGETARCH} /tini
RUN chmod +x /tini

WORKDIR /forkulator
COPY package.json .
RUN <<DOC
npm config set strict-ssl false
npm install
DOC
COPY server.coffee .

# have to use tini, or coffee below will not respect any signals
ENTRYPOINT ["/tini", "--"]
CMD ["./node_modules/.bin/coffee", "server.coffee"]
