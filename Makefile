.PHONY: build smoke scan builder push all
IMAGENAME=mohankrishna999/grafana
VERSION=13.3.0-patched
BUILDER=patched-multiarch
build:
	IMAGE=${IMAGENAME}:${VERSION} sh build/build.sh
smoke: build
	docker run --rm ${IMAGENAME}:${VERSION} -v
scan: build
	trivy image --scanners vuln --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL --exit-code 1 ${IMAGENAME}:${VERSION}
	grype ${IMAGENAME}:${VERSION} --fail-on negligible
builder:
	docker buildx inspect ${BUILDER} >/dev/null 2>&1 || docker buildx create --name ${BUILDER} --driver docker-container >/dev/null
push: builder
	IMAGE=${IMAGENAME}:${VERSION} PLATFORMS=linux/amd64,linux/arm64 OUTPUT=--push sh build/build.sh
all: smoke scan push
