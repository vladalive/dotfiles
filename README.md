# Dotfiles

Personal dotfiles managed by [Dotbot](https://github.com/anishathalye/dotbot).

The repository is the source of truth. Files installed into `$HOME` are symlinks
created from `install.conf.yaml`.

## Prerequisites

Required for install:

- `git`
- `bash`
- `python3` 3.7 or newer
- network access to GitHub for submodules

Commonly used by the installed configuration:

- `zsh`
- `tmux`
- `nvim`
- `git-delta`
- `gpg`
- `xclip`
- `jq`, `curl`, `wget`, and `gh`
- Ruby tooling such as `ruby`, `bundle`, `rubocop`, and `rspec`
- Node 22 or newer for Copilot Neovim support

## Installation

```bash
git submodule update --init --recursive
./install
```

Use a dry run before changing an existing machine:

```bash
./install --dry-run
```

## Layout

- `install.conf.yaml` - Dotbot manifest
- `files/` - dotfile sources
- `files/zshrc`, `files/bashrc`, `files/bash_profile`, `files/bash_aliases` - shell config
- `files/gitconfig` - Git config
- `files/tmux.conf` - tmux config
- `files/nvim-init.lua` - Neovim entrypoint
- `files/nvim_core/` - core Neovim config
- `files/nvim_custom_plugins/` - Lazy.nvim plugin specs
- `files/janus/` - legacy Vim/Janus plugins
- `dotbot/` - Dotbot submodule
- `lazy-lock.json` - pinned Neovim plugin revisions

## Local Overrides

Keep machine-specific settings and secrets outside the repo.

Common local files:

- `$HOME/.shell.local` for host-specific aliases and PATH entries
- `$HOME/.bash_env` and `$HOME/.bash_keys` for local environment/secrets
- `$HOME/.config/.chatgpt.key` for `ChatGPT.nvim`

Do not edit installed symlinks directly. Edit files in this repo, then rerun
`./install` if needed.

## Development

Run focused checks for touched areas:

```bash
zsh -n files/zshrc
bash -n files/bashrc files/bash_profile files/bash_aliases
git config --file files/gitconfig --list >/dev/null
git submodule status --recursive
```

For Neovim changes, load the relevant Lazy plugin headlessly:

```bash
nvim --headless -u files/nvim-init.lua \
  '+lua require("lazy").load({ plugins = { "PLUGIN_NAME" } }); vim.wait(1000)' \
  '+qa'
```

See `AGENTS.md` for the fuller repo guide.
