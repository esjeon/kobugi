
define BASE_RECIPE
$(TEMPLATE_PATH)/base.sh
endef

define INDEX_RECIPE
$(TEMPLATE_PATH)/index.sh index.map | $(BASE_RECIPE)
endef

