
-include local.mk

### Paths

SELF := $(firstword $(MAKEFILE_LIST))
SELFDIR = $(shell dirname $(realpath $(SELF)))
ROOT = $(realpath $(shell dirname "$(SELF)"))
RELPWD = $(abspath $(CURDIR:$(ROOT)%=%)/)

MAKESELF = make -f "$(SELF)"


### Files
#
# There are two types of files in Kobugi: Page and View.
#
#   - "Page" files are markup files that needs to be converted to HTML. During
#   conversion, they lose their extension (e.g. hello.md -> hello.html)
#
#   - "View" files are something that can be "viewed" online, as long as there
#   are recipes. View files retain their extension during conversion (e.g.
#   hello.c -> hello.c.html)
#

PAT_PAGE := *.md *.run *.htm
PAT_CODE := *.c *.css *.js *.mk *.sh Makefile
PAT_VIEW := $(PAT_CODE)
PAT_EXCLUDE := local.% global.%

SRC_PAGE = $(filter-out $(PAT_EXCLUDE), $(wildcard $(PAT_PAGE)))
SRC_VIEW = $(filter-out $(PAT_EXCLUDE), $(wildcard $(PAT_VIEW)))

DEST = $(addsuffix .html, $(basename $(SRC_PAGE)) $(SRC_VIEW))
DEST_SANS_INDEX = $(filter-out index.html, $(DEST))

OPT_INDEXDOC = $(firstword $(wildcard $(subst *,index,$(PAT_PAGE))))
OPT_INDEXMAP = $(wildcard index.map)
OPT_INDEXHTMP = $(firstword $(patsubst %.html,%.htmp,$(filter index.html README.html, $(DEST))))

SUBDIR = $(subst /,,$(shell ls -d */ 2>/dev/null))


### Tools

TPL_BASE = $(SELFDIR)/template-base.sh
TPL_INDEX = $(SELFDIR)/template-index.sh

define KOBUGI_ENV_RECIPE
KOBUGI_ROOT="$(ROOT)" \
KOBUGI_PWD="$(RELPWD)" \
KOBUGI_SRC="$<" \
KOBUGI_DEST="$@"
endef

define BASE_RECIPE
$(KOBUGI_ENV_RECIPE) $(TPL_BASE)
endef

define HIGHLIGHT_RECIPE
highlight --replace-tabs=4 --no-doc --enclose-pre "$<" |\
$(SELFDIR)/highlight-lineno.sh |\
$(BASE_RECIPE)
endef

define INDEX_RECIPE
$(KOBUGI_ENV_RECIPE) $(TPL_INDEX) index.map |\
$(BASE_RECIPE)
endef


### Commands

all: $(SUBDIR)
	$(MAKESELF) gen-sans-index
	$(MAKESELF) gen-index

clean: $(SUBDIR)
	rm -f *.html

vars:
	@echo "SELF    = $(SELF)"
	@echo "SELFDIR = $(SELFDIR)"
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
	@echo "OPT_INDEXDOC = $(OPT_INDEXDOC)"
	@echo "OPT_INDEXMAP = $(OPT_INDEXMAP)"

$(SUBDIR)::
	make -C "$@" -f "../$(SELF)" $(MAKECMDGOALS)


### Internal Commands

gen-sans-index: $(DEST_SANS_INDEX)

gen-index: $(OPT_INDEXHTMP)
	case "x$(OPT_INDEXHTMP)" in \
		xindex.htmp) ;; \
		xREADME.htmp) cp README.htmp index.htmp ;; \
		x) touch -r . index.htmp ;; \
	esac
	$(MAKESELF) index.html
	rm -f index.htmp


### Recipe - Index

.INTERMEDIATE: index.htmp
index.html: index.htmp $(OPT_INDEXMAP)
	cat index.htmp | $(INDEX_RECIPE)


### Recipe - Page

%.html: %.htmp
	cat "$<" | $(BASE_RECIPE)

%.htmp: %.htm
	cp -l "$<" "$@"

%.htmp: %.md
	cmark-gfm "$<" > "$@"

%.htmp: %.run
	$(KOBUGI_ENV_RECIPE) ./"$<" > "$@"


### Recipe - View

define HIGHLIGHT_TARGET
$(1).html: $(1)
	$$(HIGHLIGHT_RECIPE)
endef

$(foreach ext, $(subst *,%,$(PAT_CODE)),\
	$(eval $(call HIGHLIGHT_TARGET,$(ext))))

