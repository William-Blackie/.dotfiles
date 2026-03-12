return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "yamlls") then
        table.insert(opts.ensure_installed, "yamlls")
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}

      opts.servers.yamlls = {
        filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm" },
        settings = {
          yaml = {
            validate = true,
            keyOrdering = false,
            format = { enable = true },
            schemaStore = {
              enable = true,
              url = "https://www.schemastore.org/api/json/catalog.json",
            },
            schemas = {
              kubernetes = {
                "*.k8s.yaml",
                "*.k8s.yml",
                "k8s/**/*.yaml",
                "k8s/**/*.yml",
                "helm/**/*.yaml",
                "helm/**/*.yml",
                "charts/**/*.yaml",
                "charts/**/*.yml",
                "templates/**/*.yaml",
                "templates/**/*.yml",
                "deployment.yaml",
                "service.yaml",
                "ingress.yaml",
                "configmap.yaml",
                "secret.yaml",
              },
              ["https://json.schemastore.org/chart.json"] = {
                "Chart.yaml",
                "Chart.yml",
                "charts/**/Chart.yaml",
                "charts/**/Chart.yml",
              },
            },
          },
        },
      }
    end,
  },
}
