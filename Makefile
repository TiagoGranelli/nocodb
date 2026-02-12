IMAGE_TAG      ?= nocodb-local
GCR_PROJECT    ?= propelio-development
GCR_IMAGE      ?= gcr.io/$(GCR_PROJECT)/$(IMAGE_TAG)
PLATFORM       ?= linux/amd64
SERVICE_NAME   ?= nocodb
REGION         ?= europe-west1
CLOUDSQL_INST  ?= propelio-development:europe-west1:propelio-development-dwh

.PHONY: build tag push run deploy

gcloud-project:
	gcloud config set project $(GCR_PROJECT)

build:
	./build-local-docker-image-cross.sh $(PLATFORM)

tag:
	docker tag $(IMAGE_TAG) $(GCR_IMAGE)

push: gcloud-project tag
	docker push $(GCR_IMAGE)

run:
	gcloud run deploy $(SERVICE_NAME) \
		--image $(GCR_IMAGE) \
		--platform managed \
		--region $(REGION) \
		--port 8080 \
		--allow-unauthenticated \
		--add-cloudsql-instances $(CLOUDSQL_INST) \
		--memory 1Gi \
		--cpu 1 \
		--timeout 600 \
		--cpu-boost \
		--min-instances 1

deploy: build push run
