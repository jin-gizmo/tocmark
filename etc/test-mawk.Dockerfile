
# Ubuntu has mawk

FROM ubuntu:24.04

SHELL ["/bin/bash", "-c"]

RUN \
    apt-get update ; \
    apt-get upgrade -y --quiet ; \
    apt install make diffutils -y --quiet ;  \
    apt clean ; \
    groupadd -g 99999 tocmark ; \
    useradd -u 99999 -g tocmark -d /tocmark tocmark ; \
    awk --version ; \
    if [[ $(awk --version) = mawk* ]]; then echo true; else echo Is not mawk; exit 1; fi

USER tocmark

WORKDIR /tocmark
