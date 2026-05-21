# Dotfiles

## Purpose

This repository contains personal dotfiles managed by Dotbot. The source of
truth is this repository; installed files in `$HOME` are symlinks created from
`install.conf.yaml`.

The repo covers shell startup files, Git, tmux, legacy Vim/Janus configuration,
Neovim/Lazy.nvim configuration, Ruby defaults, ctags, and mise/asdf-related
tooling.

## Prerequisites

Required for installation:

- `git`
- `bash`
- `python3` 3.7 or newer for Dotbot
- network access to GitHub for submodules and Neovim plugins

Expected by commonly used configs:

- `zsh`
- `tmux`
- `nvim`
- `git-delta` for the configured Git pager
- `gpg`, `gpgconf`, and `gpg-connect-agent` for signing helpers
- `xclip` for clipboard aliases and tmux copy-mode integration
- `jq`, `curl`, `wget`, and `gh` for shell helper functions
- `ruby`, `bundle`, `rubocop`, and `rspec` for Ruby helpers
- `node` 22 or newer for Copilot Neovim support
- `make` for native Neovim plugin builds where applicable

Optional or host-specific:

- Antigen at `ANTIGEN_PATH` or `/usr/share/zsh-antigen/antigen.zsh`
- Linuxbrew at `/home/linuxbrew/.linuxbrew`
- Snap at `/snap/bin`
- Yandex Cloud shell include at `$HOME/yandex-cloud/path.bash.inc`
- TPM at `$HOME/.tmux/plugins/tpm/tpm`
- `$HOME/.shell.local` for host-local PATH, aliases, and secrets
- `$HOME/.bash_env` and `$HOME/.bash_keys` for local environment/secrets
- `$HOME/.config/.chatgpt.key` for `ChatGPT.nvim`

## Installation

Initialize submodules and run Dotbot:

```bash
git submodule update --init --recursive
./install
```

Do not edit installed symlinks in `$HOME` directly. Edit the corresponding file
in this repository, then rerun `./install` if relinking is needed.

## Layout

- `install.conf.yaml` - Dotbot manifest for symlinks and install commands
- `files/` - repo-owned dotfile sources
- `files/bashrc`, `files/bash_profile`, `files/bash_aliases`, `files/zshrc` - shell configuration
- `files/gitconfig`, `files/gitignore` - Git configuration
- `files/tmux.conf` - tmux configuration
- `files/vimrc.local`, `files/janus/` - legacy Vim/Janus configuration
- `files/nvim-init.lua` - Neovim entrypoint
- `files/nvim_core/` - Neovim options, commands, keymaps, and autocmds
- `files/nvim_custom_plugins/` - Lazy.nvim plugin specs
- `files/mise.toml`, `files/asdfrc`, `files/default-gems` - language tooling defaults
- `dotbot/` - Dotbot submodule
- `lazy-lock.json` - pinned Neovim plugin revisions

## Usage

Keep machine-specific configuration out of this repository. Use
`$HOME/.shell.local` for local aliases, PATH additions, and host-specific
overrides. Use local secret files such as `$HOME/.bash_keys`,
`$HOME/.bash_env`, and `$HOME/.config/.chatgpt.key`; do not commit secrets.

Shell config is intentionally shared where practical. `zshrc`, `bashrc`, and
`bash_profile` may all source local files, so guard additions against duplicate
loading when needed.

## Development

Prefer changing repo-owned source files under `files/` and `install.conf.yaml`.

Do not edit dependency or vendored code under `dotbot/` or `files/janus/`
unless the task is explicitly to update that dependency. For legacy Vim plugins,
prefer submodule updates over direct source edits.

For Neovim changes:

- edit `files/nvim-init.lua`, `files/nvim_core/`, or `files/nvim_custom_plugins/`
- keep plugin configuration in focused files under `files/nvim_custom_plugins/`
- do not run `Lazy sync` as a verification step unless updating plugins is
  intentional
- treat `lazy-lock.json` changes as plugin updates, not incidental config edits

Keep commits small and coherent. Do not leave completed work uncommitted.

## Testing

Run focused checks for the area touched.

Shell:

```bash
zsh -n files/zshrc
bash -n files/bashrc files/bash_profile files/bash_aliases
```

Git config:

```bash
git config --file files/gitconfig --list >/dev/null
```

Submodules:

```bash
git submodule status --recursive
```

tmux:

```bash
tmux -L dotfiles-test -f files/tmux.conf start-server \; \
  source-file files/tmux.conf \; \
  kill-server
```

Neovim, for a specific Lazy plugin:

```bash
nvim --headless -u files/nvim-init.lua \
  '+lua require("lazy").load({ plugins = { "PLUGIN_NAME" } }); vim.wait(1000)' \
  '+qa'
```

Neovim, for core startup:

```bash
nvim --headless -u files/nvim-init.lua '+qa'
```

Formatting/linting tools such as `stylua`, `selene`, `shellcheck`, and
`rubocop` are useful when installed, but not every machine has all of them.
Prefer targeted checks that match the files changed.
