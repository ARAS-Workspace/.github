#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# Runner Setup Script - Installs dependencies for README animation workflow
# Invoked by generate-intro.yml on each run (GitHub-hosted ubuntu runner, requires root)
# ═══════════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "═══════════════════════════════════════════════════════════════════════════"
echo " ARAS-Workspace Runner Setup"
echo "═══════════════════════════════════════════════════════════════════════════"
echo

# ─────────────────────────────────────────────────────────────
# 1. Install asciinema
# ─────────────────────────────────────────────────────────────

echo "[1/3] Installing asciinema..."

if command -v asciinema &>/dev/null; then
    echo "  ✅ asciinema already installed: $(asciinema --version)"
else
    apt-get update
    apt-get install -y asciinema
    echo "  ✅ asciinema installed: $(asciinema --version)"
fi

# ─────────────────────────────────────────────────────────────
# 2. Install additional dependencies
# ─────────────────────────────────────────────────────────────

echo "[2/3] Installing dependencies (jq, bc, curl)..."

apt-get install -y jq bc curl
echo "  ✅ Dependencies installed"

# ─────────────────────────────────────────────────────────────
# 3. Build agg Docker image
# ─────────────────────────────────────────────────────────────

# Pinned agg commit (main, 2026-08-14). Bump deliberately and verify the GIF output.
AGG_REF="aae34b012382536c8c01c753e4b609424642a06d"

echo "[3/3] Building agg Docker image (${AGG_REF:0:7})..."

if docker images | grep -q "^agg "; then
    echo "  ⚠️  agg image exists, rebuilding..."
fi

docker build -t agg:latest "https://github.com/asciinema/agg.git#${AGG_REF}"

echo "  ✅ agg image built"

# ─────────────────────────────────────────────────────────────
# Verification
# ─────────────────────────────────────────────────────────────

echo
echo "═══════════════════════════════════════════════════════════════════════════"
echo " Verification"
echo "═══════════════════════════════════════════════════════════════════════════"

echo -n "asciinema: "
command -v asciinema && asciinema --version || echo "❌ NOT FOUND"

echo -n "docker: "
command -v docker && docker --version || echo "❌ NOT FOUND"

echo -n "agg image: "
docker images agg:latest --format "{{.Repository}}:{{.Tag}} ({{.Size}})" || echo "❌ NOT FOUND"

echo
echo "═══════════════════════════════════════════════════════════════════════════"
echo " ✅ Setup complete! Runner is ready for README animation workflow."
echo "═══════════════════════════════════════════════════════════════════════════"