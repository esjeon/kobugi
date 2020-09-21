
PAT_PAGE := *.run *.htm
PAT_CODE :=
PAT_EXCLUDE := local.* global.*

TEMPLATE := explorer

include $(KOBUGI_LIB)/markdown.mk
include $(KOBUGI_LIB)/gnu-highlight.mk
