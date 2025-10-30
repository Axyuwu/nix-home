vim.keymap.set('n', ' ', '<Nop>')
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
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
vim.opt.scrolloff = 3
vim.opt.foldmethod = 'indent'
vim.opt.cmdheight = 0
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true
vim.opt.mouse = ""

local wk = require 'which-key'
wk.setup {}

wk.add({
    { "<leader>?", function() wk.show() end, desc = "Buffer Local Keymaps (which-key)" },
    {
        { "<leader>w", "<cmd>w<cr>", desc = "Write" },
    },
    {
        { "<leader>d", function() vim.diagnostic.open_float(nil, { focus = true, scope = "cursor" }) end, desc = "Hover diagnostics" },
    },
    {
        { "<leader>l",  group = "LSP" },
        { "<leader>la", function() vim.lsp.buf.code_action() end,                         desc = "Code Action" },
        { "<leader>lq", function() vim.lsp.buf.code_action { only = { "quickfix" } } end, desc = "Quick Fix" },
        { "<leader>lr", function() vim.lsp.buf.rename() end,                              desc = "Rename Symbol" },
    },
})

local gitsigns = require 'gitsigns'
gitsigns.setup {}

local guessindent = require 'guess-indent'
guessindent.setup {}

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
wk.add({
    { "gd",        function() fzf.lsp_definitions { jump1 = true } end, desc = "Fzf to definition" },
    { "<leader>o", function() fzf.files() end,                          desc = "Fzf files" },
    { "<leader>F", function() fzf.blines() end,                         desc = "Fzf in file" },
    { "<leader>f", function() fzf.lsp_document_symbols() end,           desc = "Fzf lsp buffer symbols" },
    { "<leader>O", function() fzf.lsp_workspace_symbols() end,          desc = "Fzf lsp workspace symbols" },
    { "<leader>u", function() fzf.lsp_references() end,                 desc = "Fzf lsp references" },
    { "<leader>U", function() fzf.lsp_implementations() end,            desc = "Fzf lsp implementations" },
    { "<leader>b", function() fzf.buffers() end,                        desc = "Fzf buffers" },
})

local lualine = require 'lualine'
lualine.setup {}

local barbar = require 'barbar'
barbar.setup {}
wk.add({
    { "<leader>x", "<Cmd>BufferClose<CR>",                      desc = "Close current buffer" },
    { "<leader>X", "<Cmd>BufferCloseAllButCurrentOrPinned<CR>", desc = "Close all buffers but current or pinned" },
})

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
    },
    mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    }, {
        { name = 'buffer' },
    }),
}

cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    }, {
        { name = 'cmdline' }
    }),
    matching = { disallow_symbol_nonprefix_matching = false }
})

local capabilities = require 'cmp_nvim_lsp'.default_capabilities()

local lspformat = require 'lsp-format'
lspformat.setup {}
local on_attach = lspformat.on_attach

require 'lspconfig'

vim.lsp.enable('nixd')
vim.lsp.config('nixd', {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
        formatting = {
            command = { "nixfmt" },
        },
    },
})
vim.lsp.enable('rust_analyzer')
vim.lsp.config('rust_analyzer', {
    on_attach = on_attach,
    capabilities = capabilities,
})
vim.lsp.enable('lua_ls')
vim.lsp.config('lua_ls', {
    on_attach = on_attach,
    capabilities = capabilities,
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc') then
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
        Lua = {
            format = {
                enable = true,
                defaultConfig = {
                    indent_style = "space",
                    indent_size = "4",
                },
            }
        }
    }
})

local ft_header = require '42header'
ft_header.setup {
    auto_update = true,
    user = "agilliar",
    mail = "agilliar@student.42mulhouse.fr",
}
