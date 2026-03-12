vim.filetype.add({
  extension = {
    tpl = function(path, bufnr)
      -- Handle files like "config.yaml.tpl" by looking at the second to last extension
      -- "path" is the full path. We want to extract "yaml" from "something.yaml.tpl"
      local name = vim.fn.fnamemodify(path, ":t") -- get filename only
      local parts = vim.split(name, ".", { plain = true })
      if #parts > 2 then
        -- It has at least two dots, e.g., ["config", "yaml", "tpl"]
        -- Return the second to last part as the filetype
        return parts[#parts - 1]
      end
      -- Default fallback if it's just "something.tpl"
      return "text"
    end,
  },
  pattern = {
    -- Also handle hidden files or edge cases if needed
    [".*%.(%a+)%.tpl"] = function(path, bufnr, capture)
      return capture
    end,
  },
})
