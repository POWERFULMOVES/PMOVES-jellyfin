# PMOVES-Jellyfin - Hardened Architecture Dockerfile
# Extends upstream Jellyfin with PMOVES branded defaults

ARG JELLYFIN_UPSTREAM=ghcr.io/jellyfin/jellyfin:latest
FROM ${JELLYFIN_UPSTREAM}

# PMOVES branded labels
LABEL maintainer="PMOVES.AI <ops@cataclysmstudios.com>"
LABEL description="PMOVES-enhanced Jellyfin media server with dual-mode operation"
LABEL org.pmoves.version="1.0.0-hardened"
LABEL org.pmoves.mode="standalone-docked"

# Set PMOVES branded default user
# Note: Container uses internal user, volumes are mapped with correct permissions
USER jellyfin

# Health check (uses upstream health check)
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -fSs http://localhost:8096/health || exit 1

# Expose web UI
EXPOSE 8096

# Default entrypoint uses upstream
ENTRYPOINT ["/jellyfin/jellyfin"]
CMD ["--webdir", "/jellyfin/web"]
