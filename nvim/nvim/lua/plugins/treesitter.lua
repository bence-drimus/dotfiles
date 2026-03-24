return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
	highlight = {
	    enable = true,
	},
	indent = { enable = true },
	autotag = { enable = true },
	ensure_installed = {
	    "lua",
	    "tsx",
	    "typescript",
	    "javascript",
	    "go",
	    "python",
	},
	auto_install = false,
    },
}
