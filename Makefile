SHELL:=/usr/bin/env bash -euo pipefail -c
NAME:=forkulator
LABEL:=$(NAME):latest

main:
	echo $(LABEL)
	@>&2 echo "no supported default option"; false

build:
	# https://www.docker.com/blog/introduction-to-heredocs-in-dockerfiles/
	# https://www.stereolabs.com/docs/docker/building-arm-container-on-x86/
	DOCKER_BUILDKIT=1 \
		docker build \
		--tag "$(LABEL)" \
		.

# attach to the running debug instance
shell:
	docker exec \
		--interactive \
		--tty \
		"$(NAME)" \
		"/bin/bash"

# run the container using only the shell
run-shell:
	docker run \
		--interactive \
		--tty \
		--rm \
		--volume "$(shell pwd)/../forkulator-commands:/forkulator/commands:ro" \
		--entrypoint '' \
		"$(NAME)" \
		"/bin/bash"

debug: build
	# LOCAL_PORT:CONTAINER_PORT
	docker run \
		--interactive \
		--tty \
		--rm \
		--env FORKULATOR_TEMP=/tmp \
		--name "$(NAME)" \
		--publish 9000:3000 \
		--volume "$(shell pwd)/../forkulator-commands:/forkulator/commands:ro" \
		"$(LABEL)"

.PHONY: main build shell run-shell debug
