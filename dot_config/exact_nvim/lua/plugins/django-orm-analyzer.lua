---@type LazyPluginSpec
return {
  dir = vim.fn.stdpath("config") .. "/lua/django-orm-analyzer",
  name = "django-orm-analyzer",
  lazy = false,
  config = function()
    local utils = require("lib.utils")

    require("django-orm-analyzer").setup({
      docker_container = utils.env_or_default(
        "DJANGO_ORM_ANALYZER_DOCKER_CONTAINER",
        "django-admin"
      ),
      docker_project_root = utils.env_or_default(
        "DJANGO_ORM_ANALYZER_DOCKER_PROJECT_ROOT",
        "/www/mabyduck/django"
      ),
    })
  end,
}
