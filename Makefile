.POSIX:

# force set the main target to `all`
all:

ifndef VERBOSE
.SILENT:
MAKE_NOPRINTDIR:=--no-print-directory
endif


### Paths

KOBUGI_MK  := $(firstword $(MAKEFILE_LIST))
KOBUGI_LIB  = $(shell dirname $(realpath $(KOBUGI_MK)))
KOBUGI_ROOT = $(realpath $(shell dirname "$(KOBUGI_MK)"))
KOBUGI_CWD  = $(abspath $(CURDIR:$(KOBUGI_ROOT)%=%)/)


### Configurables

DEFAULT_PAT_PAGE := *.md *.run *.htm
DEFAULT_PAT_CODE := *.c *.css *.js *.mk *.sh Makefile
DEFAULT_PAT_EXCLUDE := local.% global.%
DEFAULT_TEMPLATE := explorer

PAT_PAGE := $(DEFAULT_PAT_PAGE)
PAT_CODE := $(DEFAULT_PAT_CODE)
PAT_EXCLUDE := $(DEFAULT_PAT_EXCLUDE)
TEMPLATE := $(DEFAULT_TEMPLATE)

TEMPLATE = explorer
TEMPLATE_PATH = $(KOBUGI_LIB)/$(TEMPLATE)

INDEX_RECIPE = cat > "$@"
HIGHLIGHT_RECIPE = ( echo '<pre>'; cat "$<"; echo '</pre>' ) > "$@"
BASE_RECIPE = cat "$<" > "$@"

include $(KOBUGI_ROOT)/config.mk
-include local.mk
include $(KOBUGI_LIB)/$(TEMPLATE)/template.mk


### Files

SRC_PAGE = $(filter-out $(PAT_EXCLUDE), $(wildcard $(PAT_PAGE)))
SRC_CODE = $(filter-out $(PAT_EXCLUDE), $(wildcard $(PAT_CODE)))

DEST = $(addsuffix .html, $(basename $(SRC_PAGE)) $(SRC_CODE))
DEST_SANS_INDEX = $(filter-out index.html, $(DEST))

OPT_INDEXMAP = $(wildcard index.map)
OPT_INDEXHTMP = $(firstword $(patsubst %.html,%.htmp,$(filter index.html README.html, $(DEST))))

SUBDIR = $(subst /,,$(shell ls -d */ 2>/dev/null))


### Tools

ifneq "$(wildcard /usr/bin/tput)" ""
	_B:=$(shell tput bold)
	_R:=$(shell tput sgr0)
	_U:=$(shell tput smul)
endif
define PROGRESS
	@printf " $(_B)[%3s]$(_R) $(KOBUGI_CWD:%/=%)/$(_U)$(_B)$@$(_R): $?\n"
endef

define KOBUGI_ENV
KOBUGI_MK="$(KOBUGI_MK)" \
KOBUGI_LIB="$(KOBUGI_LIB)" \
KOBUGI_ROOT="$(KOBUGI_ROOT)" \
KOBUGI_CWD="$(KOBUGI_CWD)" \
KOBUGI_SRC="$<" \
KOBUGI_DEST="$@"
endef


### Commands

all: $(SUBDIR) $(DEST) index.html

clean: $(SUBDIR)
	rm -f *.html *.htmp

config:
	@echo "PAT_PAGE    = $(PAT_PAGE)"
	@echo "PAT_CODE    = $(PAT_CODE)"
	@echo "PAT_EXCLUDE = $(PAT_EXCLUDE)"
	@echo "TEMPLATE    = $(TEMPLATE)"

vars:
	@echo "This output is for debugging only."
	@echo
	@echo "KOBUGI_MK   = $(KOBUGI_MK)"
	@echo "KOBUGI_LIB  = $(KOBUGI_LIB)"
	@echo "KOBUGI_ROOT = $(KOBUGI_ROOT)"
	@echo "KOBUGI_CWD  = $(KOBUGI_CWD)"
	@echo
	@echo "SUBDIR = $(SUBDIR)"
	@echo "SRC_PAGE = $(SRC_PAGE)"
	@echo "SRC_CODE = $(SRC_CODE)"
	@echo
	@echo "DEST = $(DEST)"
	@echo "DEST_SANS_INDEX = $(DEST_SANS_INDEX)"
	@echo
	@echo "OPT_INDEXMAP  = $(OPT_INDEXMAP)"
	@echo "OPT_INDEXHTMP = $(OPT_INDEXHTMP)"

$(SUBDIR)::
	make -C "$@" -f "../$(KOBUGI_MK)" $(MAKE_NOPRINTDIR) $(MAKECMDGOALS)


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
	$(KOBUGI_ENV) ./"$<" > "$@"


### Recipe - View

define HIGHLIGHT_TARGET
$(1).html: $(1)
	$$(PROGRESS) HGT
	$$(HIGHLIGHT_RECIPE)
endef

$(foreach ext, $(subst *,%,$(PAT_CODE)),\
	$(eval $(call HIGHLIGHT_TARGET,$(ext))))

