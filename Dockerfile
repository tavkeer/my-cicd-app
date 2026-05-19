# ── BASE IMAGE ──────────────────────────────────────────────────────────────
# We start from the official Node.js image, Alpine variant.
# Alpine is a minimal Linux distro (~5MB vs ~900MB for full Ubuntu).
# "18-alpine" means Node.js version 18 on Alpine Linux.
FROM node:18-alpine

# ── WORKING DIRECTORY ────────────────────────────────────────────────────────
# All subsequent commands (COPY, RUN, CMD) will execute inside this folder.
# If the folder doesn't exist inside the container, Docker creates it.
WORKDIR /app

# ── COPY PACKAGE FILES FIRST (layer caching trick) ───────────────────────────
# We copy ONLY package.json before copying the rest of the source code.
# Why? Docker builds in layers. If package.json hasn't changed, Docker reuses
# the cached "npm install" layer — making rebuilds much faster.
COPY package*.json ./

# ── INSTALL DEPENDENCIES ─────────────────────────────────────────────────────
# Runs inside the container. Installs only production dependencies.
# --omit=dev skips devDependencies (like nodemon) — keeps the image lean.
RUN npm install --omit=dev

# ── COPY APPLICATION SOURCE ──────────────────────────────────────────────────
# Now copy the rest of the code. This layer changes every time code changes,
# but since node_modules is already cached above, npm install won't re-run.
COPY . .

# ── EXPOSE PORT ──────────────────────────────────────────────────────────────
# Documents that the container listens on port 3000 at runtime.
# This does NOT actually publish the port — that's done in docker-compose.yml.
# Think of it as metadata / documentation.
EXPOSE 3000

# ── START COMMAND ────────────────────────────────────────────────────────────
# The command that runs when the container starts.
# Using array form (exec form) — avoids wrapping in a shell, so signals like
# SIGTERM (for graceful shutdown) go directly to node, not to a shell process.
CMD ["node", "src/server.js"]
