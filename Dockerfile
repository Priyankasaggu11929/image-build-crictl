#!UseOBSRepositories

#!BuildTag: rancher/image-build-crictl:v1.31.0
#!BuildTag: rancher/image-build-crictl:latest
#!BuildName: image-build-crictl

ARG GO_IMAGE=rancher/image-build-base:latest
FROM ${GO_IMAGE} as builder
# setup required packages
RUN set -euo pipefail; \
    zypper -n install --no-recommends \
    jq \
    # file \
    gcc \
    # git \
    libselinux-devel \
    libseccomp-devel \
    make; \
    zypper -n clean; \
    rm -rf {/target,}/var/log/{alternatives.log,lastlog,tallylog,zypper.log,zypp/history,YaST2}
    
# setup the build
ARG PKG="github.com/kubernetes-sigs/cri-tools"
ARG SRC="github.com/kubernetes-sigs/cri-tools"
ARG TAG="v1.31.0"
ARG ARCH="amd64"

RUN mkdir -p ${GOPATH}/src/${PKG}
COPY cri-tools-1.31.0 ${GOPATH}/src/${PKG}

WORKDIR ${GOPATH}/src/${PKG}

#!RemoteAssetUrl: https://proxy.golang.org/k8s.io/kubernetes/@v/list
COPY list /tmp/list
RUN cat /tmp/list
RUN cat /tmp/list | grep -v - | grep ${TAG_MINOR} | sort -V | tail -n 1
