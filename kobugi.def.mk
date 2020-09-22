
PAGE_PATTERN := *.kbg *.htm *.md
CODE_PATTERN :=
EXCLUDE_PATTERN := local.* global.*

INDEX := index.kbg index.htm index.md README.md

define BASE_RECIPE
$(KOBUGI_LIB)/base.sh
endef

define INDEX_RECIPE
$(KOBUGI_LIB)/index.sh index.map | $(BASE_RECIPE)
endef

define MARKDOWN_RECIPE
cmark "$<" > "$@"
endef

define HIGHLIGHT_RECIPE
$(KOBUGI_LIB)/gnu-highlight.sh "$<" | $(BASE_RECIPE)
endef
