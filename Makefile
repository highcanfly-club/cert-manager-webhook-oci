OS ?= $(shell go env GOOS)
ARCH ?= $(shell go env GOARCH)

IMAGE_NAME := "cert-manager-webhook-oci"
IMAGE_TAG := "latest"

OUT := $(shell pwd)/deploy

KUBE_VERSION=1.27.0

$(shell mkdir -p "$(OUT)")
export TEST_ASSET_ETCD=.test/kubebuilder/bin/etcd
export TEST_ASSET_KUBE_APISERVER=.test/kubebuilder/bin/kube-apiserver
export TEST_ASSET_KUBECTL=.test/kubebuilder/bin/kubectl

test: .test/kubebuilder
	go test -v .

.test/kubebuilder:
	mkdir -p .test
	curl -fsSL https://go.kubebuilder.io/test-tools/$(KUBE_VERSION)/$(OS)/$(ARCH) -o .test/kubebuilder-tools.tar.gz
	tar -C .test -xvf .test/kubebuilder-tools.tar.gz
	rm .test/kubebuilder-tools.tar.gz

clean: clean-kubebuilder

clean-kubebuilder:
	rm -rf .test/kubebuilder

build:
	docker build -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

.PHONY: rendered-manifest.yaml
rendered-manifest.yaml:
	helm template \
	    cert-manager-webhook-oci \
        --set image.repository=$(IMAGE_NAME) \
        --set image.tag=$(IMAGE_TAG) \
		    --namespace cert-manager \
        deploy/cert-manager-webhook-oci > "$(OUT)/rendered-manifest.yaml"
