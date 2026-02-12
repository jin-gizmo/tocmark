
# Rocky linux has gawk by default. We need to install maek.

FROM rockylinux:9

SHELL ["/bin/bash", "-c"]

RUN \
    set -e ; \
    dnf update -y --quiet ; \
    dnf install epel-release -y --quiet ; \
    dnf install nawk make diffutils -y --quiet ;  \
    dnf clean all -y ; \
    ln -s /usr/bin/nawk /usr/local/bin/awk ; \
    groupadd -g 99999 tocmark ; \
    useradd -u 99999 -g tocmark -d /tocmark tocmark ; \
    awk --version ; \
    if [[ $(awk --version) = awk\ version* ]]; then echo true; else echo Is not nawk; exit 1; fi

USER tocmark

WORKDIR /tocmark
