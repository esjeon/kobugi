
PAT_PAGE := *.kbg *.htm *.md
PAT_CODE :=
PAT_EXCLUDE := local.* global.*

TEMPLATE := explorer

define MARKDOWN_RECIPE
cmark "$<" > "$@"
endef

include $(KOBUGI_LIB)/gnu-highlight.mk
