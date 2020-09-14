
-include local.mk

### Paths

SELF = $(firstword $(MAKEFILE_LIST))
SELFDIR = $(shell dirname $(realpath $(SELF)))
ROOT = $(realpath $(shell dirname "$(SELF)"))
RELPWD = $(abspath $(CURDIR:$(ROOT)%=%)/)

MAKESELF = make -f "$(SELF)"


### Tools

TEMPLATE = $(SELFDIR)/template.sh
GENINDEX = $(SELFDIR)/genindex.sh
HIGHLIGHT = highlight --line-numbers --anchors --no-doc --enclose-pre

KOBUGI_ENV_RECIPE = \
	KOBUGI_ROOT="$(ROOT)" \
	KOBUGI_PWD="$(RELPWD)" \
	KOBUGI_DEST="$@" \

HIGHLIGHT_RECIPE = \
	$(HIGHLIGHT) -o "$@" "$<"

GENINDEX_RECIPE = $(KOBUGI_ENV_RECIPE) $(GENINDEX)
TEMPLATE_RECIPE = $(KOBUGI_ENV_RECIPE) $(TEMPLATE)


### Files

SUBDIR = $(subst /,,$(shell ls -d */ 2>/dev/null))

DOCU_PATTERN += *.md *.run *.htm
VIEW_PATTERN += *.c *.js *.css *.sh Makefile *.mk
VIEW_EXCLUDE += local.% global.%

SRC_PAGE = $(wildcard $(DOCU_PATTERN))
SRC_VIEW = $(filter-out $(VIEW_EXCLUDE), $(wildcard $(VIEW_PATTERN)))

OPT_INDEXMAP = $(wildcard ./index.map)

DEST = $(addsuffix .html, $(basename $(SRC_PAGE)) $(SRC_VIEW))
DEST_INDEX = $(filter index.html, $(DEST))
DEST_PAGE  = $(filter-out index.html, $(DEST))


### Commands

all: $(SUBDIR)
	$(MAKESELF) gen-page
	$(MAKESELF) gen-index

clean: $(SUBDIR)
	rm -f *.html *.htmp

vars:
	@echo "SELF    = $(SELF)"
	@echo "SELFDIR = $(SELFDIR)"
	@echo "ROOT    = $(ROOT)"
	@echo "RELPWD  = $(RELPWD)"
	@echo
	@echo "SUBDIR = $(SUBDIR)"
	@echo
	@echo "SRC_PAGE = $(SRC_PAGE)"
	@echo "SRC_VIEW = $(SRC_VIEW)"
	@echo
	@echo "OPT_INDEXMAP = $(OPT_INDEXMAP)"
	@echo
	@echo "DEST       = $(DEST)"
	@echo "DEST_INDEX = $(DEST_INDEX)"
	@echo "DEST_PAGE  = $(DEST_PAGE)"

$(SUBDIR)::
	make -C "$@" -f "../$(SELF)" $(MAKECMDGOALS)


### Internal Commands

gen-page: $(DEST_PAGE)

gen-index:
	[ -z "$(DEST_INDEX)" ] && touch -r . index.htmp || true
	$(MAKESELF) index.html
	rm -f index.htmp


### Recipes

.INTERMEDIATE: index.htmp
index.html: index.htmp index.idxhtmp $(OPT_INDEXMAP) $(TEMPLATE) $(GENINDEX)
	cat index.idxhtmp | $(TEMPLATE_RECIPE)

.INTERMEDIATE: index.idxhtmp
index.idxhtmp: index.htmp $(GENINDEX)
	cat index.htmp | $(GENINDEX_RECIPE) $(OPT_INDEXMAP) > index.idxhtmp

%.html: %.htmp $(TEMPLATE)
	cat "$<" | $(TEMPLATE_RECIPE)

%.htmp: %.run
	"./$<" > "$@"

%.htmp: %.htm
	cp -l "$<" "$@"

%.htmp: %.md
	cmark-gfm "$<" > "$@"


%.c.htmp: %.c
	$(HIGHLIGHT_RECIPE)

%.css.htmp: %.css
	$(HIGHLIGHT_RECIPE)

%.js.htmp: %.js
	$(HIGHLIGHT_RECIPE)

%.sh.htmp: %.sh
	$(HIGHLIGHT_RECIPE)

%.mk.htmp: %.mk
	$(HIGHLIGHT_RECIPE)

.INTERMEDIATE: Makefile.htmp
Makefile.htmp: Makefile
	$(HIGHLIGHT_RECIPE)

