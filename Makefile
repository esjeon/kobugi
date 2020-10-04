.POSIX:

# force set the main target to `all`
all:

KOBUGI_ROOT ?= $(CURDIR)
ifeq "$(wildcard $(KOBUGI_ROOT)/kobugi.mk)" ""
$(error $(KOBUGI_ROOT)/kobugi.mk doesn't exist.)
endif

ifndef VERBOSE
.SILENT:
SILENT:=--no-print-directory
endif


########## Environments ##########

export KOBUGI_ROOT := $(realpath $(KOBUGI_ROOT))
export KOBUGI_CWD := $(abspath /$(CURDIR:$(KOBUGI_ROOT)%=%)/)

export KOBUGI_MAKEFILE := $(realpath $(firstword $(MAKEFILE_LIST)))
export KOBUGI_LIB := $(dir $(KOBUGI_MAKEFILE))

export KOBUGI_INPUT  = $<
export KOBUGI_OUTPUT = $@

# Placeholder. The actual value comes from config file.
export KOBUGI_PAGES := $(wildcard *.kbg *.htm *.md)
export KOBUGI_VIEWS :=
export KOBUGI_DIRS := $(subst /,,$(shell ls -d */ 2>/dev/null))
export KOBUGI_ASSETS := 


########## Configs ##########

include $(KOBUGI_ROOT)/kobugi.mk
-include local.mk


########## Files ##########

HTMLS := $(filter-out index.html, $(addsuffix .html, $(basename $(KOBUGI_PAGES)) $(KOBUGI_VIEWS)))

OPT_INDEXHTMP := $(addsuffix .htmp,$(basename $(firstword $(wildcard $(INDEX)))))
OPT_KOBUGIMAP := $(wildcard kobugimap)


########## Utils ##########

ifneq "$(TERM)" ""
ifneq "$(wildcard /usr/bin/tput)" ""
	_B:=$(shell tput bold)
	_R:=$(shell tput sgr0)
	_U:=$(shell tput smul)
endif
endif
define PROGRESS
	@printf " $(_B)[%3s]$(_R) $(KOBUGI_CWD:%/=%)/$(_U)$(_B)$@$(_R): $?\n"
endef


########## Commands ##########

all: $(KOBUGI_DIRS) $(HTMLS) index.html

clean: $(KOBUGI_DIRS)
	rm -f *.html *.htmp

vars:
	@echo "This output is for debugging only."
	@echo
	@echo "INDEX           = $(INDEX)"
	@echo
	@echo "HTMLS = $(HTMLS)"
	@echo "OPT_INDEXHTMP = $(OPT_INDEXHTMP)"
	@echo
	@env | grep ^KOBUGI_ | sed 's/=/\t= /'
	@echo

$(KOBUGI_DIRS)::
	make -C "$@" -f "$(KOBUGI_MAKEFILE)" $(SILENT) $(MAKECMDGOALS)


########## Rules ##########

%.html: %.htmp
	$(PROGRESS) TPL
	$(BASE_RECIPE)

%.htmp: %.htm
	$(PROGRESS) DOC
	cp -l "$<" "$@"

%.htmp: %.kbg
	$(PROGRESS) DOC
	./"$<" > "$@"

%.htmp: %.md
	$(PROGRESS) MD
	$(MARKDOWN_RECIPE)

index.html: index.full.htmp
	$(PROGRESS) TPL
	$(BASE_RECIPE)

.INTERMEDIATE: index.full.htmp $(OPT_INDEXHTMP)
index.full.htmp: $(OPT_INDEXHTMP) $(OPT_KOBUGIMAP) | $(HTMLS)
	$(PROGRESS) IDX
	KOBUGI_INPUT="$(OPT_INDEXHTMP)" "$(KOBUGI_LIB)/genindex.sh"

define CODE_RULE
.INTERMEDIATE: $(1).htmp
$(1).htmp: $(1)
	$$(PROGRESS) HGT
	$$(HIGHLIGHT_RECIPE)
endef
$(foreach ext, $(subst *,%,$(CODE_PATTERN)),\
	$(eval $(call CODE_RULE,$(ext))))
