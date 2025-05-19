.PHONY: build push clean

REGISTRY ?= docker.io/primalivet
IMAGE_NAME ?= helloworld
IMAGE_TAG ?= latest
IMAGE_PLATFORMS ?= linux/amd64,linux/arm64

set_builder:
	docker buildx create --name homelab-builder --use || true

unset_builder:
	docker buildx use default || true
	docker buildx rm homelab-builder || true

build:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

push: build
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

multi_build: set_builder
	docker buildx build --platform $(IMAGE_PLATFORMS) -t $(IMAGE_NAME):$(IMAGE_TAG) --load .

multi_push: multi_build
	docker buildx build --platform $(IMAGE_PLATFORMS) -t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) --push .
	make unset_builder

clean:
	docker rmi $(IMAGE_NAME)/$(IMAGE_TAG) 2>/dev/null || true
	docker rmi $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) 2>/dev/null || true
