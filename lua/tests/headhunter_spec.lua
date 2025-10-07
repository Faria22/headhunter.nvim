local stub = require("luassert.stub")
describe("headhunter.nvim", function()
    local headhunter
    local keymap_set
    local command_create
    local notify_stub
    local cmd_stub

    local function load_plugin()
        package.loaded["headhunter"] = nil
        headhunter = require("headhunter")
    end

    before_each(function()
        load_plugin()
        keymap_set = stub(vim.keymap, "set")
        command_create = stub(vim.api, "nvim_create_user_command")
        notify_stub = nil
        cmd_stub = nil
    end)

    after_each(function()
        keymap_set:revert()
        command_create:revert()
        if notify_stub then
            notify_stub:revert()
            notify_stub = nil
        end
        if cmd_stub then
            cmd_stub:revert()
            cmd_stub = nil
        end
        package.loaded["headhunter"] = nil
    end)

    it("registers default keymaps", function()
        headhunter.setup()

        local seen = {}
        for _, call in ipairs(keymap_set.calls) do
            seen[call.vals[2]] = call.vals[3]
        end

        assert.are.equal(headhunter.prev_conflict, seen["[g"])
        assert.are.equal(headhunter.next_conflict, seen["]g"])
        assert.are.equal(headhunter.take_head, seen["<leader>gh"])
        assert.are.equal(headhunter.take_origin, seen["<leader>go"])
        assert.are.equal(headhunter.take_both, seen["<leader>gb"])
    end)

    it("allows overriding keymaps", function()
        headhunter.setup({
            keys = {
                next = "]c",
            },
        })

        local found_override = false
        for _, call in ipairs(keymap_set.calls) do
            local lhs = call.vals[2]
            local rhs = call.vals[3]
            if lhs == "]c" and rhs == headhunter.next_conflict then
                found_override = true
            end
        end

        assert.is_true(found_override)
    end)

    it("skips keymap when explicitly disabled", function()
        headhunter.setup({
            keys = {
                take_origin = false,
            },
        })

        local seen = {}
        for _, call in ipairs(keymap_set.calls) do
            seen[call.vals[2]] = true
        end

        assert.is_nil(seen["<leader>go"])
        assert.is_true(seen["[g"]) -- other defaults remain
    end)

    it("disables all keymaps when keys is false", function()
        headhunter.setup({ keys = false })

        assert.are.equal(0, #keymap_set.calls)
        assert.are.equal(0, #command_create.calls)
    end)

    it("skips setup when disabled", function()
        headhunter.setup({ enabled = false })

        assert.are.equal(0, #keymap_set.calls)
        assert.are.equal(0, #command_create.calls)
    end)

    it("rejects unknown key identifiers", function()
        local ok, err = pcall(function()
            headhunter.setup({ keys = { invalid = "]c" } })
        end)

        assert.is_false(ok)
        assert.matches("unknown key 'invalid'", err)

        headhunter.setup() -- reset state for later tests
    end)

    it("rejects non-string key values", function()
        local ok, err = pcall(function()
            headhunter.setup({ keys = { next = 123 } })
        end)

        assert.is_false(ok)
        assert.matches("expects a string or false", err)

        headhunter.setup() -- reset state for later tests
    end)

    it("rejects non-boolean auto_write", function()
        local ok, err = pcall(function()
            headhunter.setup({ auto_write = "yes" })
        end)

        assert.is_false(ok)
        assert.matches("auto_write", err)

        headhunter.setup()
    end)

    it("returns empty table when no conflicts", function()
        local conflicts = headhunter._get_conflicts_mock("")
        assert.are.same({}, conflicts)
    end)

    it("parses single conflict correctly", function()
        local sample = [[
file1.txt:3:<<<<<<< HEAD
file1.txt:5:=======
file1.txt:7:>>>>>>> branch
]]
        local conflicts = headhunter._get_conflicts_mock(sample)
        assert.are.equal(1, #conflicts)
        assert.are.equal("file1.txt", conflicts[1].file)
        assert.are.equal(3, conflicts[1].lnum)
    end)

    it("parses multiple conflicts correctly", function()
        local sample = [[
file1.txt:3:<<<<<<< HEAD
file1.txt:5:=======
file1.txt:7:>>>>>>> branch
file2.txt:10:<<<<<<< HEAD
file2.txt:12:=======
file2.txt:14:>>>>>>> branch
]]
        local conflicts = headhunter._get_conflicts_mock(sample)
        assert.are.equal(2, #conflicts)
        assert.are.equal("file1.txt", conflicts[1].file)
        assert.are.equal(3, conflicts[1].lnum)
        assert.are.equal("file2.txt", conflicts[2].file)
        assert.are.equal(10, conflicts[2].lnum)
    end)

    it("parses stash-style conflict markers", function()
        local sample = [[
file1.txt:3:<<<<<<< Updated upstream
file1.txt:5:=======
file1.txt:7:>>>>>>> Stashed changes
]]
        local conflicts = headhunter._get_conflicts_mock(sample)
        assert.are.equal(1, #conflicts)
        assert.are.equal("file1.txt", conflicts[1].file)
        assert.are.equal(3, conflicts[1].lnum)
    end)

    it("requires manual write when auto_write disabled", function()
        local tmpfile = vim.fn.tempname()
        local bufnr = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
        vim.api.nvim_buf_set_name(bufnr, tmpfile)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "<<<<<<< HEAD",
            "ours",
            "=======",
            "theirs",
            ">>>>>>> branch",
        })

        notify_stub = stub(vim, "notify")
        cmd_stub = stub(vim, "cmd")

        headhunter.setup({ auto_write = false, keys = false })

        local original_get_conflicts = headhunter._get_conflicts
        headhunter._get_conflicts = function()
            error("navigate_conflict should exit before fetching conflicts")
        end

        vim.api.nvim_set_current_buf(bufnr)
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        headhunter.take_head()
        headhunter.next_conflict()

        assert.stub(notify_stub).was_called()
        local message = notify_stub.calls[1].vals[1]
        assert.matches("write the buffer before jumping", message)
        assert.are.equal(0, #cmd_stub.calls)

        headhunter._get_conflicts = original_get_conflicts
        vim.api.nvim_buf_delete(bufnr, { force = true })
        vim.loop.fs_unlink(tmpfile)
    end)

    describe("strict no-hidden navigation", function()
        it("temporarily enables hidden during navigation", function()
            local tmpfile1 = vim.fn.tempname()
            local tmpfile2 = vim.fn.tempname()

            -- Create first file with conflict
            vim.fn.writefile({
                "<<<<<<< HEAD",
                "first",
                "=======",
                "other",
                ">>>>>>> branch",
            }, tmpfile1)

            -- Create second file with conflict
            vim.fn.writefile({
                "<<<<<<< HEAD",
                "second",
                "=======",
                "other",
                ">>>>>>> branch",
            }, tmpfile2)

            -- Mock get_conflicts to return our test files
            local original_get_conflicts = headhunter._get_conflicts
            headhunter._get_conflicts = function()
                return {
                    { file = tmpfile1, lnum = 1 },
                    { file = tmpfile2, lnum = 1 },
                }
            end

            -- Set hidden to false
            vim.o.hidden = false

            -- Open first file and modify it
            local bufnr1 = vim.api.nvim_create_buf(true, false)
            vim.api.nvim_buf_set_option(bufnr1, "swapfile", false)
            vim.api.nvim_buf_set_name(bufnr1, tmpfile1)
            vim.api.nvim_buf_set_lines(bufnr1, 0, -1, false, { "modified content" })
            vim.api.nvim_set_current_buf(bufnr1)

            -- Navigate to next conflict - should succeed even with modified buffer
            headhunter.setup({ keys = false })
            headhunter.next_conflict()

            -- Verify we navigated to the second file
            local current_buf = vim.api.nvim_get_current_buf()
            local current_name = vim.api.nvim_buf_get_name(current_buf)
            assert.are.equal(tmpfile2, current_name)

            -- Verify hidden was restored to false
            assert.is_false(vim.o.hidden)

            -- Clean up
            headhunter._get_conflicts = original_get_conflicts
            vim.api.nvim_buf_delete(bufnr1, { force = true })
            if vim.api.nvim_buf_is_valid(current_buf) then
                vim.api.nvim_buf_delete(current_buf, { force = true })
            end
            vim.loop.fs_unlink(tmpfile1)
            vim.loop.fs_unlink(tmpfile2)
        end)

        it("restores hidden option after navigation error", function()
            -- Set hidden to false
            vim.o.hidden = false

            -- Mock get_conflicts to return an invalid file
            local original_get_conflicts = headhunter._get_conflicts
            headhunter._get_conflicts = function()
                return {
                    { file = "/nonexistent/invalid/file.txt", lnum = 1 },
                }
            end

            notify_stub = stub(vim, "notify")
            headhunter.setup({ keys = false })

            -- Attempt navigation - should handle error gracefully
            headhunter.next_conflict()

            -- Verify hidden was restored to false even after error
            assert.is_false(vim.o.hidden)

            -- Verify error was notified
            assert.stub(notify_stub).was_called()

            -- Clean up
            headhunter._get_conflicts = original_get_conflicts
        end)

        it("preserves hidden=true when set by user", function()
            local tmpfile1 = vim.fn.tempname()
            local tmpfile2 = vim.fn.tempname()

            vim.fn.writefile({ "line1" }, tmpfile1)
            vim.fn.writefile({ "line2" }, tmpfile2)

            local original_get_conflicts = headhunter._get_conflicts
            headhunter._get_conflicts = function()
                return {
                    { file = tmpfile1, lnum = 1 },
                    { file = tmpfile2, lnum = 1 },
                }
            end

            -- Set hidden to true
            vim.o.hidden = true

            headhunter.setup({ keys = false })
            headhunter.next_conflict()

            -- Verify hidden is still true
            assert.is_true(vim.o.hidden)

            -- Clean up
            headhunter._get_conflicts = original_get_conflicts
            local current_buf = vim.api.nvim_get_current_buf()
            if vim.api.nvim_buf_is_valid(current_buf) then
                vim.api.nvim_buf_delete(current_buf, { force = true })
            end
            vim.loop.fs_unlink(tmpfile1)
            vim.loop.fs_unlink(tmpfile2)
        end)
    end)
end)
