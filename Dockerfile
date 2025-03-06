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

RUN set -x; \
    TAG_MINOR=$(echo ${TAG} | awk -F. '{printf "%s.%s.\n", $1, $2}'); \
    K8S_VERSION=$(cat /tmp/list | grep -v - | grep ${TAG_MINOR} | sort -V | tail -n 1); \
    K8S_VERSION_MOD=$(echo ${K8S_VERSION} | awk -F. '{printf "v0.%s.%s\n", $2, $3}'); \
    go mod edit -replace github.com/docker/docker=github.com/docker/docker@v27.1.1+incompatible -replace k8s.io/kubernetes=k8s.io/kubernetes@${K8S_VERSION}; \
    for MODULE in $(go mod edit --json | jq -r '.Replace[] | select(.Old.Path | test("^k8s.io/")) | select(.Old.Path | test("^k8s.io/(kubernetes|klog|utils|kube-openapi)") | not) | .Old.Path'); do go mod edit --replace ${MODULE}=${MODULE}@${K8S_VERSION_MOD}; done; \
    for MODULE in $(go mod edit --json | jq -r '.Require[] | select(.Path | test("^k8s.io/")) | select(.Path | test("^k8s.io/(kubernetes|klog|utils|kube-openapi)") | not) | .Path'); do go mod edit --require ${MODULE}@${K8S_VERSION_MOD}; done;
