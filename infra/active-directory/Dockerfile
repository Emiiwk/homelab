# Samba AD DC para el homelab
# Construido desde cero para ver exactamente que se instala y que se ejecuta.
FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="homelab Samba AD DC" \
      org.opencontainers.image.description="Controlador de dominio Samba para homelab.local"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      samba \
      samba-common-bin \
      smbclient \
      krb5-user \
      dnsutils \
      ldap-utils \
      acl \
      iputils-ping \
      net-tools \
      procps \
      curl \
      ca-certificates \
      jq \
 && rm -rf /var/lib/apt/lists/*

# Evitar que el init de Debian arranque servicios dentro del contenedor
RUN printf '#!/bin/sh\nexit 0\n' > /usr/sbin/policy-rc.d \
 && chmod +x /usr/sbin/policy-rc.d \
 && update-rc.d samba disable || true

WORKDIR /opt/ad
COPY config/ /opt/ad/config/
COPY scripts/ /opt/ad/scripts/
RUN chmod +x /opt/ad/scripts/*.sh

# 389 LDAP, 636 LDAPS, 88 Kerberos, 464 kpasswd, 53 DNS, 445 SMB
EXPOSE 53 88 389 445 464 636

VOLUME ["/var/lib/samba"]

ENTRYPOINT ["/opt/ad/scripts/entrypoint.sh"]
CMD ["samba"]
