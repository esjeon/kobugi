# cmark.mk - Common Markdown plugin for Kobugi
#
# Add support for Markdown Pages to Kobugi. By default, `cmark` is used as the
# parser, but this behavior can be configured by redefining `MARKDOWN_RECIPE`.
#
#
# This file declares:
#   - PAT_PAGE (append)
#   - MARKDOWN_RECIPE
#   - %.md -> %.htmp rule
#

PAT_PAGE := $(PAT_PAGE) *.md

define MARKDOWN_RECIPE
cmark "$<" > "$@"
endef

%.htmp: %.md
	$(PROGRESS) MD
	$(MARKDOWN_RECIPE)

