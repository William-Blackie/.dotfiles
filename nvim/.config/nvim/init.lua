require("config.lazy")

-- Proper filetype detection for config/web files
vim.filetype.add({
  pattern = {
    ["docker-compose%.y[a]?ml"] = "yaml.docker-compose",
    ["compose%.y[a]?ml"] = "yaml.docker-compose",
    [".*gitlab%-ci%.y[a]?ml"] = "yaml.gitlab",
    ["helm/.*%.y[a]?ml"] = "yaml.helm",
    ["values%.y[a]?ml"] = "yaml.helm",
  },
})
