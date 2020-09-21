
PAT_PAGE := *.kbg *.htm *.md
PAT_CODE :=
PAT_EXCLUDE := local.* global.*

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
