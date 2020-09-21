# gnu-highlight.mk - A syntax highlight plugin for Kobugi based on GNU highlight
#
# This plugin enables syntax highlight for **some** files.
#
# This file declares:
#   - PAT_CODE (append)
#   - HIGHLIGHT_RECIPE
#

PAT_CODE := $(PAT_CODE) $(addprefix *., \
	cs css fs gdb go hs html ini java js json jsp jsx jl kt kts ldif lua \
	mk mpl m nim pl php rb scss sh sql ts tsx vim vue xml yaml \
)
PAT_CODE := $(PAT_CODE) Makefile Dockerfile

define HIGHLIGHT_RECIPE
$(KOBUGI_LIB)/gnu-highlight.sh "$<" | $(BASE_RECIPE)
endef
