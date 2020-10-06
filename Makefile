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

# Configurables
export KOBUGI_PAGES := $(wildcard *.kbg *.htm *.md)
export KOBUGI_VIEWS :=
export KOBUGI_DIRS := $(subst /,,$(shell ls -d */ 2>/dev/null))
export KOBUGI_ASSETS := 

# Placeholders
export KOBUGI_HTMLS :=


########## Configs ##########

include $(KOBUGI_ROOT)/kobugi.mk
-include local.mk


########## Files ##########

KOBUGI_HTMLS := $(filter-out index.html, $(addsuffix .html, $(basename $(KOBUGI_PAGES)) $(KOBUGI_VIEWS)))

OPT_INDEXHTMP := $(addsuffix .htmp,$(basename $(INDEX)))
OPT_KOBUGIMAP := $(wildcard kobugimap)
OPT_KOBUGIMAP_HTMP := $(addsuffix .htmp, $(OPT_KOBUGIMAP))


########## Utils ##########

ifneq "$(TERM)" ""
ifneq "$(wildcard /usr/bin/tput)" ""
	_B:=$(shell tput bold)
	_R:=$(shell tput sgr0)
	_U:=$(shell tput smul)
endif
endif
define PROGRESS
	@printf " $(_B)[%3s]$(_R) $(KOBUGI_CWD:%/=%)/$(_U)$(_B)$@$(_R)\n"
endef


########## Commands ##########

.PHONY: all clean vars $(KOBUGI_DIRS)

all: $(KOBUGI_DIRS) $(KOBUGI_HTMLS) index.html
	-chmod 644 *.html 2>&- >&-
	-chmod 600 *.htmp 2>&- >&-

clean: $(KOBUGI_DIRS)
	rm -f *.html *.htmp

vars:
	@echo "This output is for debugging only."
	@echo
	@echo "INDEX           = $(INDEX)"
	@echo
	@echo "OPT_INDEXHTMP = $(OPT_INDEXHTMP)"
	@echo
	@env | grep ^KOBUGI_ | sed 's/=/\t= /'
	@echo

$(KOBUGI_DIRS)::
	make -C "$@" -f "$(KOBUGI_MAKEFILE)" $(SILENT) $(MAKECMDGOALS)


########## Rules ##########

%.html: %.htmp kobugimap.htmp $(TEMPLATE)
	$(PROGRESS) TPL
	$(TEMPLATE)

%.htmp: %.htm
	$(PROGRESS) DOC
	cp -l "$<" "$@"

%.htmp: %.kbg
	$(PROGRESS) DOC
	./"$<" > "$@"

%.htmp: %.md
	$(PROGRESS) MD
	$(MARKDOWN_RECIPE)

index.html: $(OPT_INDEXHTMP) kobugimap.htmp $(TEMPLATE)
	$(PROGRESS) TPL
	KOBUGI_INPUT="$(OPT_INDEXHTMP)" $(TEMPLATE)

kobugimap.htmp: $(OPT_KOBUGIMAP)
	$(PROGRESS) IDX
	"$(KOBUGI_LIB)/parse-kobugimap.sh"

define CODE_RULE
.INTERMEDIATE: $(1).htmp
$(1).htmp: $(1)
	$$(PROGRESS) HGT
	$$(HIGHLIGHT_RECIPE)
endef
$(foreach ext, $(subst *,%,$(CODE_PATTERN)),\
	$(eval $(call CODE_RULE,$(ext))))
