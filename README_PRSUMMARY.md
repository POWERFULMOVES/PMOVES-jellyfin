# PMOVES Integration – Jellyfin Docker + GHCR

Publishes a custom Jellyfin image to GHCR and adds a pmoves-net compose file so the service can be launched within a PMOVES mesh.

Usage:
```bash
docker network create pmoves-net || true
docker compose -f docker-compose.pmoves-net.yml up -d
# UI: http://localhost:8096
```

Image: `ghcr.io/POWERFULMOVES/PMOVES-jellyfin:main`.
