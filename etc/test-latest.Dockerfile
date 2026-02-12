
# Fedora has most recent versions of awk and make

FROM fedora:latest

SHELL ["/bin/bash", "-c"]

RUN \
    dnf update -y --quiet ; \
    dnf install make diffutils -y --quiet ;  \
    dnf clean all -y ; \
    groupadd -g 99999 tocmark ; \
    useradd -u 99999 -g tocmark -d /tocmark tocmark ; \
    awk --version ; \
    if [[ $(awk --version) = GNU\ Awk* ]]; then echo true; else echo Is not gawk; exit 1; fi

USER tocmark

WORKDIR /tocmark
