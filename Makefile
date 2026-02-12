SHELL:=/bin/bash

include etc/help.mk

REPO_URL=https://github.com/jin-gizmo/tocmark

#+ **Welcome to $(APP) (v$(VERSION))** - $(REPO_URL)

#- Help brought to you by **MakeHelp** - https://github.com/jin-gizmo/makehelp.

APP=TOCmark
VERSION:=$(shell ./tocmark -v)
V_MAJOR:=$(shell echo "$(VERSION)" | cut -d. -f1)

.PHONY: dist test test-all image-all clean
.DELETE_ON_ERROR:

SRC=tocmark markdown.vim
DIST=$(foreach f,$(SRC),dist/$f)

TESTENVS:=$(patsubst etc/test-%.Dockerfile,%,$(wildcard etc/*.Dockerfile))

# ------------------------------------------------------------------------------
## Diff program to use for test failures.
## Automatically reverts to **diff** as a last resort.
diff=difft --skip-unchanged --exit-code

draft=false

#:vcat Local system (read-only)
##
override OS:=$(shell \
	if [ -f /etc/os-release ]; then . /etc/os-release && echo "$$NAME $$VERSION_ID" ; \
	elif [ -f /etc/alpine-release ]; then echo "Alpine $$(cat /etc/alpine-release)" ; \
	else uname -sr ; \
	fi)

LEFT=(
##
override AWK_VERSION:=$(shell \
	set -o pipefail ; \
	awk --version 2>/dev/null | sed -e 's/ *[$(LEFT),].*//;q' ; \
	[ $$? -ne 0 ] && awk 2>&1 | sed -e 's/ *[$(LEFT),].*//;q' ; \
)

# ------------------------------------------------------------------------------
#:cat Build targets

dist/%:	% VERSION
	@mkdir -p dist
	sed -e 's/!VERSION!/$(VERSION)/' -e 's|!REPO!|$(REPO_URL)|' $< > $@
	if [ -x "$<" ]; then chmod u+x "$@" ; else true ; fi

## Make the distribution versions of the $(APP) components.
dist:	$(DIST)

_repo_is_clean:
	@if ! git diff-index --quiet HEAD --; \
	then \
		echo "Working directory not clean! Commit or stash first."; \
		exit 1; \
	fi

_on_master:
	@if [ "$$(git rev-parse --abbrev-ref HEAD)" != "master" ]; \
	then \
		echo "Not on master branch!"; \
		exit 1; \
	fi

## Create a github release. Set *draft* to either `true` or `false`.
## To force updating an existing full version tag, set *force* to `-f`.
#:opt draft force
release: _repo_is_clean _on_master
	git tag $(force) "v$(VERSION)"
	git push origin $(force) "v$(VERSION)"
	git tag -f "v$(V_MAJOR)"
	git push origin -f "v$(V_MAJOR)"
	@echo "Creating GitHub release ..."
	@if gh release view "v$(VERSION)" > /dev/null 2>&1 ; \
	then \
		echo "Updating existing release for tag v$(VERSION)" ; \
		gh release upload --clobber "v$(VERSION)" $(SRC) ; \
		gh release edit \
			--draft="$(draft)" \
			--verify-tag=false \
			--title "Version $(VERSION)" \
			--notes "$(REPO_URL)/tree/master?tab=readme-ov-file#release-notes" \
			"v$(VERSION)" ; \
	else \
		echo "Creating new release for tag v$(VERSION)" ; \
		gh release create \
			--draft="$(draft)" \
			--fail-on-no-commits \
			--verify-tag=false \
			--title "Version $(VERSION)" \
			--notes "$(REPO_URL)/tree/master?tab=readme-ov-file#release-notes" \
			"v$(VERSION)" \
			$(SRC) ; \
	fi
	@gh release view "v$(VERSION)"

# ------------------------------------------------------------------------------
#:cat Test Targets
_TE:=$(foreach env,$(TESTENVS), `$(env)`)

## Run tests in a docker container for the target environment.
## `%` must be one of $(_TE).
test.%:
	@if [ ! -f "etc/test-$*.Dockerfile" ] ; \
	then echo "Unknown test environment: $*" && exit 1 ; \
	else true ; \
	fi
	@docker run -t --rm -v "$$(pwd):/tocmark" "tocmark-test:$*" make test $(MAKEFLAGS)

## Build a docker image for running $(APP) tests for the target environment.
## `%` must be one of $(_TE).
image.%:
	@mkdir -p dist/empty
	docker buildx build --pull -f "etc/test-$*.Dockerfile" -t "tocmark-test:$*" dist/empty

## Build all available test images.
image-all: $(foreach env,$(TESTENVS),image.$(env))

## Run the tests on the local machine.
#:opt diff
test:
	@echo -e "\033[34mRunning tests for $(OS) / AWK=$(AWK_VERSION) ...\033[0m"
	@( \
		diff="$(diff)" ; \
		$$diff --help > /dev/null 2>&1 ; \
		[ $$? -eq 127 ] && diff=diff ; \
		for f in test/*.md ; \
		do \
			./tocmark "$$f" | $$diff - $${f%.md}.out ; \
			if [ $$? -eq 0 ] ; \
			then \
				echo -e "\033[32m$$f - OK\033[0m" ; \
			else \
				echo -e "\033[31m$$f - Failed\033[0m" ; \
				exit 1 ; \
			fi ; \
		done \
	)
	@echo


## Build the reference output for a given test Markdown file `%.md`.
## Usage is `make test/abc.out`.
%.out:	%.md
	./tocmark "$<" > "$@"

## Run tests on all available test environments.
test-all: test $(foreach env,$(TESTENVS),test.$(env))

# ------------------------------------------------------------------------------
#:cat Auxiliary targets

HELP_CATEGORY=Auxiliary targets

## Update the TOC in README.md
toc:
	@set -e ; \
	tmp=$$(mktemp) ; \
	z=1 ; \
	trap '/bin/rm -f $$tmp; exit $$z' 0 ; \
	./tocmark README.md > $$tmp || exit ; \
	if cmp -s README.md $$tmp ; \
	then \
		echo "README.md already up to date" ; \
	else \
		cp README.md README.md.bak ; \
		mv $$tmp README.md ; \
		echo "README.md TOC updated" ; \
	fi ; \
	z=0

## Delete built artefacts.
clean:
	$(RM) -r dist

## Delete built artefacts and the test docker images.
clobber:
	@docker images --filter=reference='tocmark-test:*' --format '{{.Repository}}:{{.Tag}}' | \
		while read -r img ; \
		do \
			docker rmi -f "$$img" ; \
		done

