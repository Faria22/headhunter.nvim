local headhunter = require("headhunter")

describe("headhunter quickfix integration", function()
    local original_get_conflicts

    before_each(function()
        original_get_conflicts = headhunter._get_conflicts
        vim.fn.setqflist({})
        pcall(vim.cmd, "cclose")
    end)

    after_each(function()
        headhunter._get_conflicts = original_get_conflicts
        vim.fn.setqflist({})
        pcall(vim.cmd, "cclose")
    end)

    it("populates quickfix with conflicts", function()
        local file = vim.fn.fnamemodify("lua/headhunter/init.lua", ":p")
        headhunter._get_conflicts = function()
            return {
                { file = file, lnum = 12 },
            }
        end

        headhunter.populate_quickfix()

        local items = vim.fn.getqflist()
        assert.are.equal(1, #items)
        local listed_path = items[1].filename
            or vim.fn.fnamemodify(vim.fn.bufname(items[1].bufnr), ":.")
        assert.are.equal(vim.fn.fnamemodify(file, ":."), listed_path)
        assert.are.equal(12, items[1].lnum)
        assert.are.equal("Merge conflict marker", items[1].text)
    end)

    it("clears quickfix when no conflicts", function()
        headhunter._get_conflicts = function()
            return {}
        end
        vim.fn.setqflist({
            {
                filename = "dummy.lua",
                lnum = 1,
            },
        })

        headhunter.populate_quickfix()

        local items = vim.fn.getqflist()
        assert.are.equal(0, #items)
    end)

    it("keeps quickfix entries updated after refresh", function()
        local file = vim.fn.fnamemodify("lua/headhunter/init.lua", ":p")
        local conflicts = {
            { file = file, lnum = 12 },
            { file = file, lnum = 42 },
        }
        headhunter._get_conflicts = function()
            return vim.deepcopy(conflicts)
        end

        headhunter.populate_quickfix()
        assert.are.equal(2, #vim.fn.getqflist())

        conflicts = {
            { file = file, lnum = 42 },
        }

        headhunter.populate_quickfix()

        local items = vim.fn.getqflist()
        assert.are.equal(1, #items)
        assert.are.equal(42, items[1].lnum)
    end)

    it("clears quickfix automatically after resolving conflicts", function()
        local file = vim.fn.tempname() .. ".txt"
        local conflicts = {
            { file = file, lnum = 1 },
        }
        headhunter._get_conflicts = function()
            return vim.deepcopy(conflicts)
        end

        headhunter.populate_quickfix()
        assert.are.equal(1, #vim.fn.getqflist())

        conflicts = {}

        local bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_name(bufnr, file)
        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "<<<<<<< HEAD",
            "my change",
            "=======",
            "their change",
            ">>>>>>> branch",
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })

        headhunter.take_head()

        local items = vim.fn.getqflist()
        assert.are.equal(0, #items)

        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
end)
