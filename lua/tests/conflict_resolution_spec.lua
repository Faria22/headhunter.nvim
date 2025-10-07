local headhunter = require("headhunter")

describe("headhunter conflict resolution", function()
    local bufnr

    before_each(function()
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(bufnr)
    end)

    it("takes HEAD block", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "<<<<<<< HEAD",
            "my change",
            "=======",
            "their change",
            ">>>>>>> branch",
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        headhunter.take_head()

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.are.same({ "my change" }, lines)
    end)

    it("takes ORIGIN block", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "<<<<<<< HEAD",
            "my change",
            "=======",
            "their change",
            ">>>>>>> branch",
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        headhunter.take_origin()

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.are.same({ "their change" }, lines)
    end)

    it("takes BOTH blocks", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "<<<<<<< HEAD",
            "my change",
            "=======",
            "their change",
            ">>>>>>> branch",
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        headhunter.take_both()

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.are.same({ "my change", "their change" }, lines)
    end)

    it("handles stash-style conflict markers", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "<<<<<<< Updated upstream",
            "upstream change",
            "=======",
            "stashed change",
            ">>>>>>> Stashed changes",
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        headhunter.take_head()

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        assert.are.same({ "upstream change" }, lines)
    end)

    it("writes resolved buffer to disk when auto_write enabled", function()
        local tmpfile = vim.fn.tempname()
        local file_buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_option(file_buf, "swapfile", false)
        vim.api.nvim_buf_set_name(file_buf, tmpfile)
        vim.api.nvim_buf_set_lines(file_buf, 0, -1, false, {
            "<<<<<<< HEAD",
            "my change",
            "=======",
            "their change",
            ">>>>>>> branch",
        })

        vim.api.nvim_set_current_buf(file_buf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        -- Explicitly set auto_write = true to test behavior when enabled, regardless of default.
        headhunter.setup({ auto_write = true, keys = false })
        headhunter.take_head()

        vim.api.nvim_buf_delete(file_buf, { force = true })
        local saved = vim.fn.readfile(tmpfile)
        assert.are.same({ "my change" }, saved)

        vim.loop.fs_unlink(tmpfile)
        vim.api.nvim_set_current_buf(bufnr)
    end)

    it("does not write buffer when auto_write disabled", function()
        local tmpfile = vim.fn.tempname()
        local file_buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_option(file_buf, "swapfile", false)
        vim.api.nvim_buf_set_name(file_buf, tmpfile)
        vim.api.nvim_buf_set_lines(file_buf, 0, -1, false, {
            "<<<<<<< HEAD",
            "my change",
            "=======",
            "their change",
            ">>>>>>> branch",
        })

        -- Write initial content to file
        vim.fn.writefile({ "initial content" }, tmpfile)

        vim.api.nvim_set_current_buf(file_buf)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        headhunter.setup({ auto_write = false, keys = false })
        headhunter.take_head()

        -- Buffer should be modified but not saved
        local lines = vim.api.nvim_buf_get_lines(file_buf, 0, -1, false)
        assert.are.same({ "my change" }, lines)

        -- File on disk should still have original content
        local saved = vim.fn.readfile(tmpfile)
        assert.are.same({ "initial content" }, saved)

        vim.api.nvim_buf_delete(file_buf, { force = true })
        vim.loop.fs_unlink(tmpfile)
        vim.api.nvim_set_current_buf(bufnr)
    end)
end)
