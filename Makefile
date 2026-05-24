.PHONY: build-hermes build-openclaw build-all run-hermes run-openclaw clean clean-all help

.DEFAULT_GOAL := help

# Image configuration
HERMES_IMAGE := polyglot-hermes:latest
OPENCLAW_IMAGE := polyglot-openclaw:latest
PLATFORM := linux/amd64

# Volumes config
HERMES_VOLUME := polyglot-hermes-data
OPENCLAW_VOLUME := polyglot-openclaw-data

help:
	@echo "========================================================================="
	@echo "                  Polyglot AI Agents Docker Workspace                    "
	@echo "========================================================================="
	@echo "Available Targets:"
	@echo "  build-hermes    : Build the Hermes Agent image (${HERMES_IMAGE})"
	@echo "  build-openclaw  : Build the OpenClaw Gateway image (${OPENCLAW_IMAGE})"
	@echo "  build-all       : Build both AI agent images"
	@echo "  run-hermes      : Run the Hermes Agent container interactively"
	@echo "  run-openclaw    : Run the OpenClaw Gateway container (port 18789)"
	@echo "  clean           : Prune dangling images and build cache"
	@echo "  clean-all       : Prune unused Docker system assets"
	@echo "========================================================================="

build-hermes:
	docker build -f Dockerfile.hermes -t $(HERMES_IMAGE) --platform $(PLATFORM) .

build-openclaw:
	docker build -f Dockerfile.openclaw -t $(OPENCLAW_IMAGE) --platform $(PLATFORM) .

build-all: build-hermes build-openclaw

run-hermes:
	@echo "Starting Hermes Agent. Interactive console runs by default."
	@echo "Ensure you mount a data volume for persistence if needed."
	docker run -it --rm \
		--name hermes-agent \
		-p 9119:9119 \
		-v $(HERMES_VOLUME):/opt/data \
		$(HERMES_IMAGE)

run-openclaw:
	@echo "Starting OpenClaw Gateway. Access UI at http://localhost:18789"
	docker run -it --rm \
		--name openclaw-gateway \
		-p 18789:18789 \
		-v $(OPENCLAW_VOLUME):/home/node/.openclaw \
		$(OPENCLAW_IMAGE)

clean:
	docker image prune -f

clean-all:
	docker system prune -f
