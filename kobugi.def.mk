
PAGE_PATTERN := *.kbg *.htm *.md
CODE_PATTERN :=
EXCLUDE_PATTERN := local.* global.*

INDEX := index.kbg index.htm index.md README.md

define BASE_RECIPE
$(KOBUGI_LIB)/base.sh
endef

define MARKDOWN_RECIPE
{ echo '<content>'; cmark "$<"; echo '</content>' } > "$@"
endef

define HIGHLIGHT_RECIPE
$(KOBUGI_LIB)/gnu-highlight.sh
endef
