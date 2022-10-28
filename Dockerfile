# syntax=docker/dockerfile:1.3-labs
FROM ubuntu:14.04

RUN <<DOC
apt-get update
apt-get install smbclient --assume-yes
apt-get install awscli --assume-yes
apt-get install jq --assume-yes
apt-get install bc --assume-yes
# old version of aws cli doesn't support the features we need

## This is a working set of steps as of Nov 5, 2018 to get a modern
## version of the AWS Cli running on Ubuntu 14.04.  Every few months
## the endzone moves and upstream complications add complexity to the
## process.  As such, it's possible this will need more adjustments
## at a later date.  This may be removable when support for Ubuntu 14.04
## is deprecated.
set +e
## Because:  https://github.com/aws/aws-cli/issues/2999#issuecomment-356019306

pip uninstall boto3 -y
pip uninstall boto -y
pip uninstall botocore -y
# Fix bug caused by apt/ubuntu
rm -rf /usr/local/lib/python2.7/dist-packages/botocore-*.dist-info
pip install botocore --force-reinstall --upgrade
#######
## Because: https://github.com/aws/aws-cli/issues/3007#issuecomment-350797161
pip install --upgrade s3transfer
rm -rf /tmp/pip_build_root/PyYAML
apt-get install libyaml-dev
pip install awscli --force-reinstall --upgrade
set -e
DOC

RUN <<DOC
apt-get install -y curl ssh
#apt-get --assume-yes install nodejs npm
curl -fsSL https://deb.nodesource.com/setup_5.x | bash - &&\
apt-get install -y --force-yes nodejs
DOC

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
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
