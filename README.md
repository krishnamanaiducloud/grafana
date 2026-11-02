# Grafana hardened source build

Grafana OSS 13.3.0 built from the verified upstream source commit using Grafana's own
multi-stage Dockerfile and `final-distroless` target. The build changes only the final
runtime base to the digest-pinned Chainguard static image. Published as
`mohankrishna999/grafana:13.3.0-patched` for amd64 and arm64.

The standard Grafana paths, UID 472, port 3000, plugin loading, provisioning, and command
line remain compatible. The image has no shell; install plugins through provisioning or
`GF_PLUGINS_PREINSTALL`, not an interactive shell.
