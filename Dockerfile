# PMOVES-Jellyfin - Hardened Architecture Dockerfile
# Extends upstream Jellyfin with PMOVES branded defaults

ARG JELLYFIN_UPSTREAM=ghcr.io/jellyfin/jellyfin:latest
FROM ${JELLYFIN_UPSTREAM}

# PMOVES branded labels
LABEL maintainer="PMOVES.AI <ops@cataclysmstudios.com>"
LABEL description="PMOVES-enhanced Jellyfin media server with dual-mode operation"
LABEL org.pmoves.version="1.0.0-hardened"
LABEL org.pmoves.mode="standalone-docked"

# --- PMOVES SSO: bake the Ezeqielle OIDC plugin (RS256/JWKS OIDC client) ---
# Staged OUTSIDE /config because /config is a runtime bind-mount that would
# shadow a plugin baked into /config/plugins. pmoves-entrypoint.sh copies it
# into /config/plugins on start. Pin the release; oidc-rbac.zip is a FLAT zip
# (plugin dll + Microsoft.IdentityModel/System.IdentityModel dlls + meta.json).
USER root
ARG JELLYFIN_OIDC_PLUGIN_VERSION=v1.0.8
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip curl ca-certificates; \
    mkdir -p /opt/pmoves/oidc-plugin; \
    curl -fSsL -o /tmp/oidc.zip \
      "https://github.com/Ezeqielle/jellyfin-plugin-oidc/releases/download/${JELLYFIN_OIDC_PLUGIN_VERSION}/oidc-rbac.zip"; \
    unzip /tmp/oidc.zip -d /opt/pmoves/oidc-plugin; \
    rm /tmp/oidc.zip; \
    chmod -R a+rX /opt/pmoves; \
    rm -rf /var/lib/apt/lists/*
COPY pmoves-entrypoint.sh /usr/local/bin/pmoves-entrypoint.sh
RUN chmod +x /usr/local/bin/pmoves-entrypoint.sh

# Set PMOVES branded default user
# Note: Container uses internal user, volumes are mapped with correct permissions
USER jellyfin

# Health check (uses upstream health check)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fSs http://localhost:8096/health || exit 1

# Expose web UI
EXPOSE 8096

# PMOVES entrypoint copies the baked OIDC plugin into the /config bind-mount on
# start, then hands off to the upstream jellyfin binary unchanged.
ENTRYPOINT ["/usr/local/bin/pmoves-entrypoint.sh"]
CMD ["--webdir", "/jellyfin/web"]
