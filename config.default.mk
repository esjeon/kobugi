
PAT_PAGE := *.md *.run *.htm
PAT_CODE :=
PAT_EXCLUDE := local.* global.*

TEMPLATE := explorer

include $(KOBUGI_LIB)/gnu-highlight.mk
