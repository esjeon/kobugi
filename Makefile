.POSIX:

# force set the main target to `all`
all:

ifndef VERBOSE
.SILENT:
MAKE_NOPRINTDIR:=--no-print-directory
endif


### Environments

export KOBUGI_MK   := $(firstword $(MAKEFILE_LIST))
export KOBUGI_LIB  := $(dir $(realpath $(KOBUGI_MK)))
export KOBUGI_ROOT := $(realpath $(shell dirname "$(KOBUGI_MK)"))
export KOBUGI_CWD  := $(abspath $(CURDIR:$(KOBUGI_ROOT)%=%)/)

export KOBUGI_SRC  = $<
export KOBUGI_DEST = $@


### Configurables

INDEX_RECIPE = cat > "$@"
HIGHLIGHT_RECIPE = ( echo '<pre>'; cat "$<"; echo '</pre>' ) > "$@"
BASE_RECIPE = cat "$<" > "$@"

include $(KOBUGI_ROOT)/kobugi.mk
-include local.mk


### Files

EXCLUDE_PATTERN := $(subst *,%,$(EXCLUDE_PATTERN))
PAGES = $(filter-out $(EXCLUDE_PATTERN), $(wildcard $(PAGE_PATTERN)))
CODES = $(filter-out $(EXCLUDE_PATTERN), $(wildcard $(CODE_PATTERN)))

HTMLS = $(addsuffix .html, $(basename $(PAGES)) $(CODES))
HTMLS_NOINDEX = $(filter-out index.html, $(HTMLS))

OPT_INDEXMAP = $(wildcard index.map)
OPT_INDEXHTMP = $(firstword $(patsubst %.html,%.htmp,$(filter index.html README.html, $(HTMLS))))

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


### Commands

all: $(SUBDIR) $(HTMLS) index.html

clean: $(SUBDIR)
	rm -f *.html *.htmp

config:
	@echo "PAGE_PATTERN    = $(PAGE_PATTERN)"
	@echo "CODE_PATTERN    = $(CODE_PATTERN)"
	@echo "EXCLUDE_PATTERN = $(EXCLUDE_PATTERN)"

vars:
	@echo "This output is for debugging only."
	@echo
	@echo "SUBDIR = $(SUBDIR)"
	@echo "PAGES = $(PAGES)"
	@echo "CODES = $(CODES)"
	@echo
	@echo "HTMLS = $(HTMLS)"
	@echo "HTMLS_NOINDEX = $(HTMLS_NOINDEX)"
	@echo
	@echo "OPT_INDEXMAP  = $(OPT_INDEXMAP)"
	@echo "OPT_INDEXHTMP = $(OPT_INDEXHTMP)"

env:
	@env | grep KOBUGI_
	@echo

$(SUBDIR)::
	make -C "$@" -f "../$(KOBUGI_MK)" $(MAKE_NOPRINTDIR) $(MAKECMDGOALS)


### Recipe - Index

.INTERMEDIATE: index.htmp
.INTERMEDIATE: README.htmp
index.html: $(OPT_INDEXHTMP) $(OPT_INDEXMAP) | $(HTMLS_NOINDEX)
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

%.htmp: %.kbg
	$(PROGRESS) DOC
	./"$<" > "$@"

%.htmp: %.md
	$(PROGRESS) MD
	$(MARKDOWN_RECIPE)


### Recipe - View

define HIGHLIGHT_TARGET
$(1).html: $(1)
	$$(PROGRESS) HGT
	$$(HIGHLIGHT_RECIPE)
endef

$(foreach ext, $(subst *,%,$(CODE_PATTERN)),\
	$(eval $(call HIGHLIGHT_TARGET,$(ext))))

