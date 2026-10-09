# Dotfiles

## Rebase and guarded pushes

Refresh PR branches with rebase onto their actual base. `git pushfl [remote
[branch:destination]]` publishes an authorized rewrite with both lease and
include protection. It accepts only the current branch, one named remote and
one branch destination; protected branches, mirror remotes, multiple push URLs,
deletions and hook-bypass options are refused. Agent rewrites additionally require
`agent-work-claims` to confirm ownership of the destination. It never merges or
retries with weaker flags after a refusal. Missing tools or a policy denial must
be reported, not bypassed.

Enable the independent local history hook per repository:

```sh
~/.config/git/bin/git-history-guard install --base origin/master
```

Use the repository's actual default base. For stacked PRs explicitly set
`git config branch.<destination>.agentsKitBase origin/<parent>` before pushing;
the guard compares with that parent, including its proposed tip in a batch push.
`git-history-guard check --base origin/<parent> --head HEAD` is also usable before
opening a PR. `prkit open` checks its supplied PR base when this guard is enabled.
Fetch base refs before checking. Unknown bases fail closed. The hook preserves
existing hooks and their stdin; `uninstall` removes only its marked block and
leaves the repository's history policy setting in place. This is a local policy,
not a substitute for server-side protections or an authorization to bypass a
refusal. Native PR merges and deliberately non-linear workflows need a separately
agreed policy, not automatic exceptions invented by an agent.

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
- `envs` and `skate` for managed shell-variable loading
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
- `run_onchange_after_configure-gnome-input-sources.sh.tmpl` - configures GNOME XKB input sources as English/Russian with Latin Ctrl shortcuts
- `files/janus/` - legacy Vim/Janus plugins retained for `~/.janus`
- `install` - wrapper around `chezmoi --source <repo> --force apply`

## Local Overrides

Keep machine-specific settings and secrets outside the repo.

Common local files:

- `$HOME/.shell.local` for host-specific aliases and PATH entries
- `$HOME/.bash_env` and `$HOME/.bash_keys` for local environment/secrets
- `$HOME/.config/.chatgpt.key` for `ChatGPT.nvim`
- `$HOME/.gitconfig.local` for host-specific Git settings, such as the signing
  key or `commit.gpgsign = false` on a host without one

`dot_zshenv` puts asdf, Linuxbrew and, where installed, the Google Cloud SDK
on PATH for every zsh, then runs the `envs` loader. Stored environment values
remain in the local Skate `@env` database and must not be added to this repo.

Use `chezmoi diff` to inspect live drift. Use `chezmoi add <target>` or
`chezmoi re-add` only after reviewing the diff and deciding the live change
belongs in git.

## Development

Run focused checks for touched areas:

```bash
zsh -n dot_zshenv dot_zshrc
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
