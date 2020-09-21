
PAT_PAGE := *.kbg *.htm *.md
PAT_CODE :=
PAT_EXCLUDE := local.* global.*

TEMPLATE := explorer

define MARKDOWN_RECIPE
cmark "$<" > "$@"
endef

define HIGHLIGHT_RECIPE
$(KOBUGI_LIB)/gnu-highlight.sh "$<" | $(BASE_RECIPE)
endef
