
define BASE_RECIPE
$(KOBUGI_ENV) $(TEMPLATE_PATH)/base.sh
endef

define INDEX_RECIPE
$(KOBUGI_ENV) $(TEMPLATE_PATH)/index.sh index.map | $(BASE_RECIPE)
endef

