local cwd = vim.fn.getcwd()

vim.opt.runtimepath:append(cwd)

pcall(vim.cmd, "packadd plenary.nvim")
