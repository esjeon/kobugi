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

export KOBUGI_INPUT  = $<
export KOBUGI_OUTPUT = $@


### Configs

include $(KOBUGI_ROOT)/kobugi.mk
-include local.mk


### Files

EXCLUDE_PATTERN := $(subst *,%,$(EXCLUDE_PATTERN))
PAGES = $(filter-out $(EXCLUDE_PATTERN) $(INDEX), $(wildcard $(PAGE_PATTERN)))
CODES = $(filter-out $(EXCLUDE_PATTERN) $(INDEX), $(wildcard $(CODE_PATTERN)))

HTMLS = $(filter-out index.html, $(addsuffix .html, $(basename $(PAGES)) $(CODES)))
OPT_INDEXHTMP = $(addsuffix .htmp,$(firstword $(wildcard $(INDEX))))

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
	@echo "INDEX           = $(INDEX)"

vars:
	@echo "This output is for debugging only."
	@echo
	@echo "SUBDIR = $(SUBDIR)"
	@echo "PAGES = $(PAGES)"
	@echo "CODES = $(CODES)"
	@echo "HTMLS = $(HTMLS)"
	@echo "OPT_INDEXHTMP = $(OPT_INDEXHTMP)"

env:
	@env | grep KOBUGI_
	@echo

$(SUBDIR)::
	make -C "$@" -f "../$(KOBUGI_MK)" $(MAKE_NOPRINTDIR) $(MAKECMDGOALS)


### Recipe - Index

index.html: index.htmp | $(HTMLS)
	$(PROGRESS) IDX
	cat index.htmp | $(INDEX_RECIPE)

.INTERMEDIATE: index.htmp $(OPT_INDEXHTMP)
index.htmp: $(OPT_INDEXHTMP)
	$(PROGRESS) IDX
	if [ -n '$<' ]; \
	then rm -f '$@' && cp -l '$<' '$@'; \
	else touch -r . '$@'; \
	fi


### Recipe - Page

%.html: %.htmp
	$(PROGRESS) TPL
	cat "$<" | $(BASE_RECIPE)

define PAGE_RULE
%.html: %.$(1).htmp
	$$(PROGRESS) REN
	cp -l "$$<" "$$@"
endef
$(foreach ext, htm kbg md, $(eval $(call PAGE_RULE,$(ext))))

%.htm.htmp: %.htm
	$(PROGRESS) DOC
	cp -l "$<" "$@"

%.kbg.htmp: %.kbg
	$(PROGRESS) DOC
	./"$<" > "$@"

%.md.htmp: %.md
	$(PROGRESS) MD
	$(MARKDOWN_RECIPE)


### Recipe - View

define CODE_RULE
$(1).html: $(1)
	$$(PROGRESS) HGT
	$$(HIGHLIGHT_RECIPE)
endef

$(foreach ext, $(subst *,%,$(CODE_PATTERN)),\
	$(eval $(call CODE_RULE,$(ext))))

