# Docker Production Deployment

This document describes a production-oriented Docker deployment strategy for Nuxt applications.

---

## Goals

- Consistent deployments
- Portable runtime
- Health monitoring
- Easier scaling
- Improved operational reliability

---

## Included Files

- examples/docker/Dockerfile
- examples/docker/docker-compose.yml

---

## Build

```bash
docker build -t nuxt-app .