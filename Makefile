.EXPORT_ALL_VARIABLES:
.ONESHELL:
SHELL = /bin/bash

define . =
	source .mkdkr
	$(eval JOB_NAME=$(shell bash -c 'source .mkdkr; .... $(@)'))
	.... $(JOB_NAME)
endef

# END OF MAKE DEFINITIONS, CREATE YOUR JOBS BELOW

.PHONY: small shellcheck service dind brainfuck scenarios

scenarios: small service dind

small:
	$(call .)
	... job alpine --cpus 1 --memory 32MB
	.. echo "Hello darkness, my old friend"
	.

shellcheck:
	$(call .)
	... job ubuntu:18.04
	.. apt-get update '&&' \
		apt-get install -y shellcheck
	.. shellcheck -e SC1088 -e SC2068 -e SC2086 .mkdkr
	.. shellcheck generator/gitlab-ci
	.

service:
	$(call .)
	... service nginx
	... job alpine --link service_$$JOB_NAME:nginx
	.. apk add curl
	.. curl -s nginx
	.

dind:
	$(call .)
	... privileged docker:19
	.. docker build -t rosiney/mkdkr .
	.

brainfuck:
	$(call .)
	... privileged docker:19
	.. apk add make bash
	.. make pipeline
	.

generator/gitlab:
	$(call .)
	... job rosineygp/mkdkr
	.. gitlab-ci lint=shellcheck \
		scenarios=small,service,dind > .gitlab-ci.yml
	.

pipeline:
	make shellcheck
	make scenarios -j3