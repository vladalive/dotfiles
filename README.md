# Dotfiles

Personal dotfiles managed by [chezmoi](https://www.chezmoi.io/).

The repository is the source of truth. Chezmoi applies source-state files from
this repo into `$HOME`. Most installed files are real files; legacy
compatibility symlinks are kept only where they preserve existing behavior.

## Prerequisites

Required for install:

- `git`
- `bash`
- `chezmoi`
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

On an existing checkout:

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

## Layout

- `.chezmoiignore` - excludes repo docs, legacy dotbot layout, and vendored code from chezmoi target state
- `dot_*` - source-state files applied into `$HOME`
- `private_dot_config/` - source-state files applied into `$HOME/.config`
- `symlink_dot_dotfiles.tmpl` - keeps `~/.dotfiles` pointing at the chezmoi source repo
- `symlink_dot_janus.tmpl` - preserves the legacy Janus plugin symlink
- `files/` - legacy dotbot source layout retained during migration
- `dotbot/`, `install.conf.yaml` - legacy dotbot installer retained until cutover cleanup

## Local Overrides

Keep machine-specific settings and secrets outside the repo.

Common local files:

- `$HOME/.shell.local` for host-specific aliases and PATH entries
- `$HOME/.bash_env` and `$HOME/.bash_keys` for local environment/secrets
- `$HOME/.config/.chatgpt.key` for `ChatGPT.nvim`

Use `chezmoi diff` to inspect live drift. Use `chezmoi add <target>` or
`chezmoi re-add` only after reviewing the diff and deciding the live change
belongs in git.

## Development

Run focused checks for touched areas:

```bash
zsh -n dot_zshrc
bash -n dot_bashrc dot_bash_profile dot_bash_aliases
git config --file dot_gitconfig --list >/dev/null
git submodule status --recursive
```

For Neovim changes, load the relevant Lazy plugin headlessly:

```bash
nvim --headless -u private_dot_config/nvim/init.lua \
  '+lua require("lazy").load({ plugins = { "PLUGIN_NAME" } }); vim.wait(1000)' \
  '+qa'
```

See `AGENTS.md` for the fuller repo guide.
