
IGNORE := _%
CODE_PATTERN :=

# Pages are document files or `*.kbg` executables which output HTML code.
#
# The generated HTML file will lose the original file extension.
# (e.g. `hello.md` -> `hello.html`)
#
# The default value includes *.md, *.kbg, *.htm files
#
KOBUGI_PAGES := $(filter-out $(IGNORE), $(KOBUGI_PAGES))

# Views are files that can be *viewed* online. The examples include source code
# and multimedia files.
#
# The generated HTML file retains the original extension.
# (e.g. `main.c` -> `main.c.html`)
#
# The default value is empty.
#
KOBUGI_VIEWS :=

# Assets are files that are NOT viewable, thus no HTML will be generated, but
# will be included in auto-generated index list.
#
KOBUGI_ASSETS :=

# The list of sub-directories.
#
KOBUGI_DIRS  := $(filter-out $(IGNORE), $(KOBUGI_DIRS))

# The name(s) of directory index file. Ealier the name appears, higher the
# priority is.
#
INDEX := $(firstword $(wildcard index.kbg index.htm index.md README.md))

TEMPLATE := $(KOBUGI_LIB)/template.sh

define MARKDOWN_RECIPE
	cmark "$<" > '$@'
endef

define HIGHLIGHT_RECIPE
$(KOBUGI_LIB)/highlight.sh
endef
