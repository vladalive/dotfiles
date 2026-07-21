# Dotfiles

## Purpose

This repository contains personal dotfiles managed by chezmoi. The source of
truth is this repository; chezmoi applies source-state files from this repo into
`$HOME`. Most installed files are real files. Legacy symlinks are kept only when
they preserve existing behavior.

The repo covers shell startup files, Git, tmux, legacy Vim/Janus configuration,
Neovim/Lazy.nvim configuration, Ruby defaults, ctags, and mise/asdf-related
tooling.

## Prerequisites

Required for installation:

- `git`
- `bash`
- `chezmoi`
- network access to GitHub for submodules and Neovim plugins

Expected by commonly used configs:

- `zsh`
- `tmux`
- `nvim`
- `git-delta` for the configured Git pager
- `gpg`, `gpgconf`, and `gpg-connect-agent` for signing helpers
- `xclip` for clipboard aliases and tmux copy-mode integration
- `jq`, `curl`, `wget`, and `gh` for shell helper functions
- `envs` and `skate` for managed shell-variable loading
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

On an existing checkout, preview and apply chezmoi:

```bash
./install --dry-run
./install
```

On a new machine:

```bash
chezmoi init git@github.com:vladalive/dotfiles.git
chezmoi diff
chezmoi apply
```

Use `chezmoi diff` to inspect live drift. Use `chezmoi add <target>` or
`chezmoi re-add` only after deciding the live change belongs in git.

## Layout

- `.chezmoiignore` - excludes repo docs, legacy dotbot layout, and vendored code from chezmoi target state
- `dot_*` - source-state files applied into `$HOME`
- `private_dot_config/` - source-state files applied into `$HOME/.config`
- `symlink_dot_dotfiles.tmpl` - keeps `~/.dotfiles` pointing at the chezmoi source repo
- `symlink_dot_janus.tmpl` - preserves the legacy Janus plugin symlink
- `files/janus/` - legacy Vim/Janus plugins retained for `~/.janus`
- `install` - wrapper around `chezmoi --source <repo> --force apply`

## Usage

Keep machine-specific configuration out of this repository. Use
`$HOME/.shell.local` for local aliases, PATH additions, and host-specific
overrides. Use local secret files such as `$HOME/.bash_keys`,
`$HOME/.bash_env`, and `$HOME/.config/.chatgpt.key`; do not commit secrets.

Shell config is intentionally shared where practical. `zshrc`, `bashrc`, and
`bash_profile` may all source local files, so guard additions against duplicate
loading when needed.

`dot_zshenv` contains only the `envs` loader. Stored environment values
remain in the local Skate `@env` database and must not be added to this repo.

## Development

Prefer changing chezmoi source-state files such as `dot_zshenv`, `dot_zshrc`,
`dot_gitconfig`, and `private_dot_config/nvim/init.lua`.

Do not edit dependency or vendored code under `files/janus/` unless the task is
explicitly to update that dependency. For legacy Vim plugins, prefer submodule
updates over direct source edits.

For Neovim changes:

- edit `private_dot_config/nvim/init.lua`, `private_dot_config/nvim/nvim_core/`, or `private_dot_config/nvim/lua/custom/my/`
- keep plugin configuration in focused files under `private_dot_config/nvim/lua/custom/my/`
- do not run `Lazy sync` as a verification step unless updating plugins is
  intentional
- treat `lazy-lock.json` changes as plugin updates, not incidental config edits

Keep commits small and coherent. Do not leave completed work uncommitted.

## Testing

Run focused checks for the area touched.

Shell:

```bash
zsh -n dot_zshenv dot_zshrc
bash -n dot_bashrc dot_bash_profile dot_bash_aliases
```

Git config:

```bash
git config --file dot_gitconfig --list >/dev/null
```

Submodules:

```bash
git submodule status --recursive
```

tmux:

```bash
tmux -L dotfiles-test -f dot_tmux.conf start-server \; \
  source-file dot_tmux.conf \; \
  kill-server
```

Neovim, for a specific Lazy plugin:

```bash
nvim --headless -u private_dot_config/nvim/init.lua \
  '+lua require("lazy").load({ plugins = { "PLUGIN_NAME" } }); vim.wait(1000)' \
  '+qa'
```

Neovim, for core startup:

```bash
nvim --headless -u private_dot_config/nvim/init.lua '+qa'
```

Formatting/linting tools such as `stylua`, `selene`, `shellcheck`, and
`rubocop` are useful when installed, but not every machine has all of them.
Prefer targeted checks that match the files changed.
