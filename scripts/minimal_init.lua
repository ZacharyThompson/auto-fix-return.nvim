vim.opt.rtp:append(".")
vim.opt.rtp:append("./testbin/plenary.nvim/")
vim.opt.rtp:append("./testbin/")

-- Disable swap so ci does not fail randomly
vim.opt.swapfile = false

local plenary_files = vim.fn.globpath(vim.o.rtp, "plugin/plenary.vim", false, true)
for _, file in ipairs(plenary_files) do
  vim.cmd.source(file)
end

local fix_return_files = vim.fn.globpath(vim.o.rtp, "lua/auto-fix-return.lua", false, true)
for _, file in ipairs(fix_return_files) do
  vim.cmd.source(file)
end
