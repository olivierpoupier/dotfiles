-- ─── Leader key (must be set before plugins) ────────────
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ─── Options ─────────────────────────────────────────────
vim.opt.number = true              -- Line numbers
vim.opt.relativenumber = true      -- Relative line numbers (makes vim motions way faster)
vim.opt.cursorline = true          -- Highlight current line
vim.opt.signcolumn = "yes"         -- Always show sign column (prevents layout shift)
vim.opt.termguicolors = true       -- True color support

vim.opt.tabstop = 4                -- Tab width
vim.opt.shiftwidth = 4             -- Indent width
vim.opt.expandtab = true           -- Spaces instead of tabs
vim.opt.smartindent = true

vim.opt.ignorecase = true          -- Case-insensitive search...
vim.opt.smartcase = true           -- ...unless you use a capital letter

vim.opt.splitright = true          -- New vertical splits go right
vim.opt.splitbelow = true          -- New horizontal splits go below

vim.opt.clipboard = "unnamedplus"  -- Use system clipboard (yank/paste works with macOS)
vim.opt.undofile = true            -- Persistent undo across sessions
vim.opt.scrolloff = 8              -- Keep 8 lines visible above/below cursor
vim.opt.updatetime = 250           -- Faster CursorHold events (for gitsigns etc.)

-- ─── Basic keymaps ───────────────────────────────────────
-- Better window navigation (Ctrl+h/j/k/l instead of Ctrl-w then h/j/k/l)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Clear search highlight with Escape
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Stay in visual mode when indenting
vim.keymap.set("v", "<", "<gv", { desc = "Indent left and reselect" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right and reselect" })

-- Move selected lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Buffer navigation
vim.keymap.set("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Close buffer" })

-- ─── Bootstrap lazy.nvim ─────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ─── Plugins ─────────────────────────────────────────────
require("lazy").setup({

    -- Theme: Dracula
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("dracula").setup({
                transparent_bg = true,
            })
            vim.cmd.colorscheme("dracula")
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "dracula",
                    section_separators = "",
                    component_separators = "│",
                },
            })
        end,
    },

    -- File tree (toggle with <leader>e)
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                filesystem = {
                    follow_current_file = { enabled = true },
                    use_libuv_file_watcher = true,
                    filtered_items = {
                        visible = true,       -- Show dotfiles dimmed
                        hide_dotfiles = false,
                        hide_gitignored = false,
                        hide_by_name = {
                            "node_modules",
                            ".git",
                            "bin",
                            "obj",
                        },
                    },
                },
                window = {
                    width = 35,
                    mappings = {
                        ["<space>"] = "none",  -- Don't conflict with leader
                    },
                },
            })
            vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle file tree" })
            vim.keymap.set("n", "<leader>o", "<cmd>Neotree focus<CR>", { desc = "Focus file tree" })
        end,
    },

    -- Fuzzy finder (the big one — replaces Ctrl+P and Ctrl+Shift+F)
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                defaults = {
                    layout_strategy = "horizontal",
                    layout_config = {
                        prompt_position = "top",
                    },
                    sorting_strategy = "ascending",
                    file_ignore_patterns = {
                        "node_modules/",
                        ".git/",
                        "bin/",
                        "obj/",
                        "%.dll",
                        "%.pdb",
                    },
                },
            })
            telescope.load_extension("fzf")

            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Grep across project" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find open buffers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
            vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Grep word under cursor" })
        end,
    },

    -- Which-key: shows available keybinds as you type
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            local wk = require("which-key")
            wk.setup({
                delay = 300,
            })
            wk.add({
                { "<leader>f", group = "find" },
                { "<leader>b", group = "buffer" },
            })
        end,
    },

    -- Highlight matching pairs, auto-close brackets
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Better syntax highlighting
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            vim.treesitter.language.register("html", "angular")

            -- Ensure parsers are installed
            local ensure_installed = {
                "lua", "c_sharp", "typescript", "javascript",
                "html", "css", "json", "yaml", "markdown",
                "bash", "sql", "dockerfile",
            }
            for _, lang in ipairs(ensure_installed) do
                pcall(function()
                    vim.treesitter.start(0, lang)
                end)
            end

            -- Auto-enable treesitter highlighting and indentation
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    pcall(vim.treesitter.start, args.buf)
                end,
            })
        end,
    },

    -- Indent guides (subtle vertical lines showing scope)
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            require("ibl").setup({
                indent = { char = "│" },
                scope = { enabled = true },
            })
        end,
    },

    -- Comment toggle (gcc for a line, gc in visual mode)
    {
        "numToStr/Comment.nvim",
        event = "VeryLazy",
        config = true,
    },

    -- Git signs in the gutter (added/changed/removed lines)
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = "│" },
                    change       = { text = "│" },
                    delete       = { text = "_" },
                    topdelete    = { text = "‾" },
                    changedelete = { text = "~" },
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local function map(mode, l, r, desc)
                        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                    end

                    map("n", "]h", gs.next_hunk, "Next git hunk")
                    map("n", "[h", gs.prev_hunk, "Previous git hunk")

                    map("n", "<leader>gp", gs.preview_hunk, "Preview hunk diff")
                    map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
                    map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
                    map("n", "<leader>gb", gs.blame_line, "Blame line")
                    map("n", "<leader>gd", gs.diffthis, "Diff against index")
                end,
            })
        end,
    },
})
