.POSIX:

ifndef VERBOSE
.SILENT:
MAKE_NOPRINTDIR:=--no-print-directory
endif

-include local.mk

### Paths

SELF := $(firstword $(MAKEFILE_LIST))
LIBPATH = $(shell dirname $(realpath $(SELF)))
ROOT = $(realpath $(shell dirname "$(SELF)"))
RELPWD = $(abspath $(CURDIR:$(ROOT)%=%)/)


### Files

PAT_PAGE := *.md *.run *.htm
PAT_CODE := *.c *.css *.js *.mk *.sh Makefile
PAT_VIEW := $(PAT_CODE)
PAT_EXCLUDE := local.% global.%

SRC_PAGE = $(filter-out $(PAT_EXCLUDE), $(wildcard $(PAT_PAGE)))
SRC_VIEW = $(filter-out $(PAT_EXCLUDE), $(wildcard $(PAT_VIEW)))

DEST = $(addsuffix .html, $(basename $(SRC_PAGE)) $(SRC_VIEW))
DEST_SANS_INDEX = $(filter-out index.html, $(DEST))

OPT_INDEXMAP = $(wildcard index.map)
OPT_INDEXHTMP = $(firstword $(patsubst %.html,%.htmp,$(filter index.html README.html, $(DEST))))

SUBDIR = $(subst /,,$(shell ls -d */ 2>/dev/null))


### Tools

TPL_BASE = $(LIBPATH)/template-base.sh
TPL_INDEX = $(LIBPATH)/template-index.sh

ifeq ($(wildcard /usr/bin/tput),)
define PROGRESS
	@printf " [%3s] $(RELPWD:%/=%)/$@: $?\n"
endef
else
	_B:=$(shell tput bold)
	_R:=$(shell tput sgr0)
	_U:=$(shell tput smul)
define PROGRESS
	@printf " $(_B)[%3s]$(_R) $(RELPWD:%/=%)/$(_U)$(_B)$@$(_R): $?\n"
endef
endif

define KOBUGI_ENV_RECIPE
KOBUGI_ROOT="$(ROOT)" \
KOBUGI_PWD="$(RELPWD)" \
KOBUGI_LIBPATH="$(LIBPATH)" \
KOBUGI_SRC="$<" \
KOBUGI_DEST="$@"
endef

define BASE_RECIPE
$(KOBUGI_ENV_RECIPE) $(TPL_BASE)
endef

define HIGHLIGHT_RECIPE
$(LIBPATH)/highlight.sh "$<" | $(BASE_RECIPE)
endef

define INDEX_RECIPE
$(KOBUGI_ENV_RECIPE) $(TPL_INDEX) index.map |\
$(BASE_RECIPE)
endef


### Commands

all: $(SUBDIR) $(DEST) index.html

clean: $(SUBDIR)
	rm -f *.html *.htmp

vars:
	@echo "SELF    = $(SELF)"
	@echo "LIBPATH = $(LIBPATH)"
	@echo "ROOT    = $(ROOT)"
	@echo "RELPWD  = $(RELPWD)"
	@echo
	@echo "SUBDIR = $(SUBDIR)"
	@echo
	@echo "PAT_PAGE    = $(PAT_PAGE)"
	@echo "PAT_CODE    = $(PAT_CODE)"
	@echo "PAT_VIEW    = $(PAT_VIEW)"
	@echo "PAT_EXCLUDE = $(PAT_EXCLUDE)"
	@echo
	@echo "SRC_PAGE = $(SRC_PAGE)"
	@echo "SRC_VIEW = $(SRC_VIEW)"
	@echo
	@echo "DEST = $(DEST)"
	@echo "DEST_SANS_INDEX = $(DEST_SANS_INDEX)"
	@echo
	@echo "OPT_INDEXMAP  = $(OPT_INDEXMAP)"
	@echo "OPT_INDEXHTMP = $(OPT_INDEXHTMP)"

$(SUBDIR)::
	make -C "$@" -f "../$(SELF)" $(MAKE_NOPRINTDIR) $(MAKECMDGOALS)


### Recipe - Index

.INTERMEDIATE: index.htmp
.INTERMEDIATE: README.htmp
index.html: $(OPT_INDEXHTMP) $(OPT_INDEXMAP) | $(DEST_SANS_INDEX)
	$(PROGRESS) IDX
	case "x$(OPT_INDEXHTMP)" in \
		xREADME.htmp) cp README.htmp index.htmp ;; \
		x) touch -r . index.htmp ;; \
	esac
	cat index.htmp | $(INDEX_RECIPE)
	case "x$(OPT_INDEXHTMP)" in \
		x|xREADME.htmp) rm index.htmp ;; \
	esac


### Recipe - Page

%.html: %.htmp
	$(PROGRESS) TPL
	cat "$<" | $(BASE_RECIPE)

%.htmp: %.htm
	$(PROGRESS) DOC
	cp -l "$<" "$@"

%.htmp: %.md
	$(PROGRESS) DOC
	cmark-gfm "$<" > "$@"

%.htmp: %.run
	$(PROGRESS) DOC
	$(KOBUGI_ENV_RECIPE) ./"$<" > "$@"


### Recipe - View

define HIGHLIGHT_TARGET
$(1).html: $(1)
	$$(PROGRESS) HGT
	$$(HIGHLIGHT_RECIPE)
endef

$(foreach ext, $(subst *,%,$(PAT_CODE)),\
	$(eval $(call HIGHLIGHT_TARGET,$(ext))))

