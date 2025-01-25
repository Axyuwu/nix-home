vim.keymap.set('n', ' ', '<Nop>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.mouse = 'a'
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.cmdheight = 0;

local ts = require 'nvim-treesitter.configs'
ts.setup {}

local devicons = require 'nvim-web-devicons'
devicons.setup {
    color_incons = true,
    default = true,
}

local fzf = require 'fzf-lua'
fzf.setup {}
fzf.register_ui_select()

local lualine = require 'lualine'
lualine.setup {}

local luasnip = require 'luasnip'
luasnip.setup {}

local cmp = require 'cmp'
cmp.setup {
    snippet = {
        exapnd = function(args)
	    luasnip.lsp_expand(args.body)
	end,
    },
    window = {
      completion = cmp.config.window.bordered(),
      documentation = cmp.config.window.bordered(),
    },
    sources = cmp.config.sources({
	{ name = 'nvim_lsp' },
	{ name = 'luasnip' },
    }, {
	{ name = 'buffer' },
    })
}

local wk = require 'which-key'
wk.setup {}
wk.add({
    {"<leader>?", function() wk.show() end, desc = "Buffer Local Keymaps (which-key)"},
    {
        {"<leader>w", "<cmd>w<cr>", desc = "Write"},
    },
    {
        {"gd", function() vim.lsp.buf.definition() end, desc = "Jump to definition"},
	{"<leader>d", function() vim.diagnostic.open_float(nil, {focus=true, scope = "cursor"}) end, desc = "Hover diagnostics"},
    },
    {
        {"<leader>l", group = "LSP"},
        {"<leader>la", function() vim.lsp.buf.code_action() end, desc = "Code Action"},
        {"<leader>lq", function() vim.lsp.buf.code_action {only = {"quickfix"}} end, desc = "Quick Fix"},
        {"<leader>lr", function() vim.lsp.buf.rename() end, desc = "Rename Symbol"},
    },
})

local lspconfig = require 'lspconfig'
lspconfig.nixd.setup {}
lspconfig.rust_analyzer.setup {}
lspconfig.lua_ls.setup {
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if vim.loop.fs_stat(path..'/.luarc.json') or vim.loop.fs_stat(path..'/.luarc.jsonc') then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
                version = 'LuaJIT'
            },

            workspace = {
                checkThirdParty = false,
                library = {
                    vim.env.VIMRUNTIME,
		    "${3rd}/luv/library"
                }
            }
        })
    end,
    settings = {
        Lua = {}
    }
}
