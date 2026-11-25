#!/bin/sh
set -eu

version="${GRAFANA_VERSION:-13.3.0}"
commit="${GRAFANA_COMMIT:-752e3462ff71a43a5c1fb62d00a482fa2dc0ee6a}"
image="${IMAGE:-mohankrishna999/grafana:${version}-patched}"
platforms="${PLATFORMS:-linux/amd64}"
output="${OUTPUT:---load}"
workspace="$(mktemp -d)"
trap 'rm -rf "$workspace"' EXIT

git -c advice.detachedHead=false clone --quiet --depth 1 --branch "v${version}" \
  https://github.com/grafana/grafana.git "$workspace/grafana"
test "$(git -C "$workspace/grafana" rev-parse HEAD)" = "$commit"

# Grafana's upstream Dockerfile already has a source-build distroless target. Replace only
# its runtime base with Chainguard static; all upstream build stages and assets stay intact.
sed -i 's|FROM golang:1.27.3-alpine AS go-builder-base|FROM cgr.dev/chainguard/go:latest-dev@sha256:9b20546aae743fadb0adb5b4801188b79061de7299f074d82ca6c939c7f80772 AS go-builder-base|' \
  "$workspace/grafana/Dockerfile"
sed -i 's|FROM gcr.io/distroless/static-debian13 AS distroless-base|FROM cgr.dev/chainguard/static:latest@sha256:fc42af33e643f20d08baf03cddcc1c02ba57052dfb02edb0d79f3fc47bcea8d9 AS distroless-base|' \
  "$workspace/grafana/Dockerfile"

# Refresh modules inherited from the v13.3.0 graph before Docker copies go.mod/go.sum.
(
  cd "$workspace/grafana"
  go mod edit \
    -require=go.opentelemetry.io/otel/sdk/log@v1.47.0 \
    -require=go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploggrpc@v0.23.0 \
    -require=go.opentelemetry.io/otel/exporters/otlp/otlplog/otlploghttp@v0.23.0 \
    -require=go.opentelemetry.io/otel/exporters/stdout/stdoutlog@v0.23.0 \
    -require=golang.org/x/net@v0.62.0 \
    -require=golang.org/x/crypto@v0.59.0
  go mod download
)

# shellcheck disable=SC2086
docker buildx build --platform "$platforms" --target final-distroless \
  --build-arg COMMIT_SHA="$commit" \
  --build-arg BUILD_BRANCH="v${version}" \
  --label "org.opencontainers.image.version=${version}-patched" \
  --label "org.opencontainers.image.revision=${commit}" \
  --tag "$image" $output "$workspace/grafana"
