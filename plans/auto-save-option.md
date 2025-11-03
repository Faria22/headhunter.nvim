# Auto-Save Option Plan

- Introduce `auto_save = false` in `defaultConfig` and validate user input so only booleans are accepted.
- Extend `apply_resolution` to check `config.auto_save`; when true, issue a silent, local buffer write via `vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent noautocmd write") end)`.
- Document the new configuration flag in `README.md`, noting the default and giving a sample `require("headhunter").setup` snippet.
