-- Godot engine integration
-- Server pipe, LSP formatting, treesitter parsers, breakpoint helpers

local M = {}

-- Detect if cwd (or parent) is a Godot project, return project root or nil
local function find_godot_root()
  local cwd = vim.fn.getcwd()
  for _, suffix in ipairs({ '/', '/../' }) do
    local dir = cwd .. suffix
    if vim.uv.fs_stat(dir .. 'project.godot') then
      return dir
    end
  end
  return nil
end

function M.setup()
  local godot_root = find_godot_root()
  if not godot_root then return end

  -- Start a named pipe server so Godot can open files in this nvim instance
  local pipe = godot_root .. 'server.pipe'
  if not vim.uv.fs_stat(pipe) then
    vim.fn.serverstart(pipe)
  end

  -- GDScript formatting via LSP (format-on-save handled by conform's lsp_format fallback)
  -- Add gdscript to conform so it explicitly uses LSP
  local ok, conform = pcall(require, 'conform')
  if ok then
    conform.formatters_by_ft.gdscript = { lsp_format = 'prefer' }
  end

  -- Breakpoint helpers
  vim.keymap.set('n', '<leader>bp', function()
    local line = vim.fn.line '.'
    vim.fn.append(line - 1, '\tbreakpoint')
  end, { desc = 'Godot: insert [B]reak[P]oint above' })

  vim.keymap.set('n', '<leader>bd', function()
    vim.cmd [[g/^\s*breakpoint\s*$/d]]
  end, { desc = 'Godot: [B]reakpoint [D]elete all in file' })
end

return M
