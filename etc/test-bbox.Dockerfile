
# Alpine has busybox awk

FROM alpine:3

RUN \
    apk update ; \
    apk upgrade ; \
    apk add bash make diffutils ncurses ; \
    addgroup -g 99999 tocmark ; \
    adduser -u 99999 -G tocmark -h /tocmark -D -s /bin/bash tocmark

SHELL ["/bin/bash", "-c"]

RUN \
    awk 2>&1 ; \
    if [[ $(awk 2>&1) == BusyBox* ]]; then echo true; else echo Is not BusyBox awk; exit 1; fi

USER tocmark

CMD ["/bin/bash"]
WORKDIR /tocmark
