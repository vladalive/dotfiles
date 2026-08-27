# frozen_string_literal: true

RSpec.describe 'git branch-remove-merged' do
  let(:repo) { create_repo }

  def run(*args)
    run_script('git-branch-remove-merged', *args, chdir: repo)
  end

  def add_worktree(name, branch)
    path = File.join(sandbox, name)
    git!(repo, 'worktree', 'add', '-q', path, branch)
    File.realpath(path)
  end

  it 'removes a merged branch that has commits of its own' do
    merged_branch(repo, 'feature')

    stdout, _stderr, status = run

    expect(status).to be_success
    expect(stdout).to include('Removed feature')
    expect(stdout).to include('Removed 1 merged branch and 0 worktrees.')
    expect(local_branches(repo)).not_to include('feature')
  end

  it 'never touches a protected branch' do
    merged_branch(repo, 'develop')

    stdout, _stderr, = run

    expect(stdout).to include('No merged branches to remove.')
    expect(local_branches(repo)).to include('develop')
  end

  it 'never touches the branch that is checked out' do
    merged_branch(repo, 'feature')
    git!(repo, 'checkout', '-q', 'feature')

    stdout, _stderr, = run

    expect(stdout).to include('No merged branches to remove.')
    expect(local_branches(repo)).to include('feature')
  end

  # The failure that made this guard necessary: a branch created and claimed but
  # not yet committed to is an ancestor of master by definition, so "merged"
  # calls it disposable when it is the opposite.
  it 'skips a branch that has no commits of its own yet' do
    git!(repo, 'branch', 'claimed')

    stdout, _stderr, = run

    expect(stdout).to include('Skipping claimed: no commits of its own yet')
    expect(stdout).to include('Skipped 1 merged branch')
    expect(local_branches(repo)).to include('claimed')
  end

  it 'removes the worktree along with the branch' do
    merged_branch(repo, 'feature')
    worktree = add_worktree('feature-wt', 'feature')

    stdout, _stderr, = run

    expect(stdout).to include('Removed feature (and 1 worktree)')
    expect(local_branches(repo)).not_to include('feature')
    expect(Dir.exist?(worktree)).to be false
  end

  it 'skips a branch whose worktree has uncommitted work' do
    merged_branch(repo, 'feature')
    worktree = add_worktree('feature-wt', 'feature')
    File.write(File.join(worktree, 'scratch.txt'), "in progress\n")

    stdout, _stderr, = run

    expect(stdout).to include('Skipping feature: worktree has modified or untracked files')
    expect(local_branches(repo)).to include('feature')
    expect(Dir.exist?(worktree)).to be true
  end

  # The other half of the same failure: a worktree an agent opened a minute ago
  # is clean, and looks exactly like an abandoned one.
  it 'skips a branch whose clean worktree a live process is sitting in' do
    merged_branch(repo, 'feature')
    worktree = add_worktree('feature-wt', 'feature')

    stdout = with_process_in(worktree) { run.first }

    expect(stdout).to include('Skipping feature: a live process has its cwd inside the worktree')
    expect(local_branches(repo)).to include('feature')
    expect(Dir.exist?(worktree)).to be true
  end

  it 'reports without deleting under --dry-run' do
    merged_branch(repo, 'feature')
    worktree = add_worktree('feature-wt', 'feature')

    stdout, _stderr, status = run('--dry-run')

    expect(status).to be_success
    expect(stdout).to include('Would remove feature (and 1 worktree)')
    expect(stdout).to include('Would remove 1 merged branch and 1 worktree.')
    expect(local_branches(repo)).to include('feature')
    expect(Dir.exist?(worktree)).to be true
  end

  it 'rejects an unknown argument' do
    _stdout, stderr, status = run('--wat')

    expect(status).not_to be_success
    expect(stderr).to include('usage: git branch-remove-merged [--dry-run]')
  end
end
