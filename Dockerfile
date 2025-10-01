FROM alpine:latest

LABEL maintainer="Nick [linickx.com]"
LABEL version="0.1"

# Install
RUN apk update \
    && apk add bash tzdata ca-certificates fetchmail msmtp \
    && rm -rf /var/cache/apk/*

RUN addgroup fetchmail-docker 
RUN adduser -G "fetchmail-docker" -s "/usr/bin/bash" -h "/etc/fetchmail" -D fetchmail-docker

# Setup empty config files and permissions
RUN touch /etc/fetchmail/fetchmailrc \
    && chmod 600 /etc/fetchmail/fetchmailrc
RUN touch /etc/fetchmail/msmtprc \
    && chmod 600 /etc/fetchmail/msmtprc
RUN chown -Rv fetchmail-docker:fetchmail-docker /etc/fetchmail

# Entry point
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Run as non-root user
USER fetchmail-docker
WORKDIR /etc/fetchmail
ENTRYPOINT ["/entrypoint.sh"]