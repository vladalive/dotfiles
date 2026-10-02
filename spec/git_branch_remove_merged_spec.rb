# frozen_string_literal: true

RSpec.describe 'git branch-remove-merged' do
  let(:repo) { create_repo }

  # No real gh by default: the examples below that care about squash merges hand
  # the script a stand-in, and the rest must not depend on a GitHub login.
  def run(*args, env: {})
    run_script('git-branch-remove-merged', *args, chdir: repo,
                                                   env: { 'BRANCH_REMOVE_MERGED_GH' => 'false' }.merge(env))
  end

  # A gh that answers `pr list` with the given merged PRs.
  def fake_gh(prs)
    path = File.join(sandbox, 'fake-gh')
    File.write(path, "#!/bin/sh\ncat <<'JSON'\n#{JSON.generate(prs)}\nJSON\n")
    File.chmod(0o755, path)
    path
  end

  def branch_created(name, days:)
    git!(repo, 'branch', name, env: { 'GIT_COMMITTER_DATE' => days_ago(days) })
  end

  # Merge a branch the way a squash-merge PR does: its commits never become
  # ancestors of master, so `--merged` cannot see it.
  def squash_merged_branch(name)
    git!(repo, 'checkout', '-q', '-b', name)
    write_commit(repo, "#{name}.txt", "#{name}\n", "work on #{name}")
    tip = git!(repo, 'rev-parse', name).strip
    git!(repo, 'checkout', '-q', 'master')
    git!(repo, 'merge', '--squash', '-q', name)
    git!(repo, 'commit', '-q', '-m', "squash #{name}")
    tip
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

  describe 'a branch with no commits of its own' do
    it 'is removed with its clean worktree once it is older than 48 hours' do
      branch_created('abandoned', days: 3)
      worktree = add_worktree('abandoned-wt', 'abandoned')

      stdout, _stderr, = run

      expect(stdout).to include('Removed abandoned (and 1 worktree)')
      expect(local_branches(repo)).not_to include('abandoned')
      expect(Dir.exist?(worktree)).to be false
    end

    it 'is kept while it is younger than 48 hours' do
      branch_created('recent', days: 1)

      stdout, _stderr, = run

      expect(stdout).to include('Skipping recent: no commits of its own yet')
      expect(local_branches(repo)).to include('recent')
    end

    it 'is kept when its worktree has uncommitted work, however old' do
      branch_created('abandoned', days: 10)
      worktree = add_worktree('abandoned-wt', 'abandoned')
      File.write(File.join(worktree, 'scratch.txt'), "in progress\n")

      stdout, _stderr, = run

      expect(stdout).to include('Skipping abandoned: worktree has modified or untracked files')
      expect(Dir.exist?(worktree)).to be true
    end

    it 'is kept when a live process is sitting in its worktree, however old' do
      branch_created('abandoned', days: 10)
      worktree = add_worktree('abandoned-wt', 'abandoned')

      stdout = with_process_in(worktree) { run.first }

      expect(stdout).to include('Skipping abandoned: a live process has its cwd inside the worktree')
      expect(Dir.exist?(worktree)).to be true
    end
  end

  # git itself does not count ignored files as dirt, so `worktree remove` would
  # delete them without a word - and an ignored file can be the only copy of
  # something (a plan, a note, a local database).
  describe 'ignored files in a worktree' do
    before do
      write_commit(repo, '.gitignore', "notes.txt\nlog/\n.env.local\n", 'ignore things')
      merged_branch(repo, 'feature')
    end

    it 'keeps the worktree when one holds something nothing can regenerate' do
      worktree = add_worktree('feature-wt', 'feature')
      File.write(File.join(worktree, 'notes.txt'), "only copy\n")

      stdout, _stderr, = run

      expect(stdout).to include('Skipping feature: worktree holds ignored files')
      expect(stdout).to include('notes.txt')
      expect(Dir.exist?(worktree)).to be true
    end

    it 'removes the worktree when the ignored files are regenerable build output' do
      worktree = add_worktree('feature-wt', 'feature')
      FileUtils.mkdir_p(File.join(worktree, 'log'))
      File.write(File.join(worktree, 'log', 'test.log'), "noise\n")

      stdout, _stderr, = run

      expect(stdout).to include('Removed feature (and 1 worktree)')
      expect(Dir.exist?(worktree)).to be false
    end

    it 'removes the worktree when the ignored file is a symlink' do
      worktree = add_worktree('feature-wt', 'feature')
      File.symlink(File.join(repo, 'README.md'), File.join(worktree, '.env.local'))

      stdout, _stderr, = run

      expect(stdout).to include('Removed feature (and 1 worktree)')
    end

    # The real .worktrees.yml is untracked, so it exists only in the main
    # checkout and no worktree of it carries a copy.
    it 'finds an untracked .worktrees.yml in the main checkout' do
      File.write(File.join(repo, '.worktrees.yml'), "copy:\n- notes.txt\n")
      worktree = add_worktree('feature-wt', 'feature')
      File.write(File.join(worktree, 'notes.txt'), "provisioned\n")

      stdout, _stderr, = run

      expect(stdout).to include('Removed feature (and 1 worktree)')
      expect(Dir.exist?(worktree)).to be false
    end

    it 'removes the worktree when the ignored file is one .worktrees.yml provisions' do
      write_commit(repo, '.worktrees.yml', "copy:\n- notes.txt\n", 'declare provisioning')
      git!(repo, 'checkout', '-q', 'feature')
      git!(repo, 'merge', '-q', 'master')
      git!(repo, 'checkout', '-q', 'master')
      worktree = add_worktree('feature-wt', 'feature')
      File.write(File.join(worktree, 'notes.txt'), "provisioned\n")

      stdout, _stderr, = run

      expect(stdout).to include('Removed feature (and 1 worktree)')
    end
  end

  describe 'a branch merged by squash' do
    it 'is removed when a merged PR has exactly its tip as head' do
      tip = squash_merged_branch('squashed')
      gh = fake_gh([{ headRefName: 'squashed', headRefOid: tip }])

      stdout, _stderr, = run(env: { 'BRANCH_REMOVE_MERGED_GH' => gh })

      expect(stdout).to include('Removed squashed')
      expect(local_branches(repo)).not_to include('squashed')
    end

    it 'is kept when it holds commits the merged PR never had' do
      old_tip = squash_merged_branch('squashed')
      git!(repo, 'checkout', '-q', 'squashed')
      write_commit(repo, 'later.txt', "later\n", 'work after the merge')
      git!(repo, 'checkout', '-q', 'master')
      gh = fake_gh([{ headRefName: 'squashed', headRefOid: old_tip }])

      stdout, _stderr, = run(env: { 'BRANCH_REMOVE_MERGED_GH' => gh })

      expect(stdout).not_to include('Removed squashed')
      expect(local_branches(repo)).to include('squashed')
    end

    it 'is kept when no merged PR matches it' do
      squash_merged_branch('squashed')
      gh = fake_gh([{ headRefName: 'other', headRefOid: 'a' * 40 }])

      run(env: { 'BRANCH_REMOVE_MERGED_GH' => gh })

      expect(local_branches(repo)).to include('squashed')
    end

    it 'is reported, not deleted, under --dry-run' do
      tip = squash_merged_branch('squashed')
      gh = fake_gh([{ headRefName: 'squashed', headRefOid: tip }])

      stdout, _stderr, = run('--dry-run', env: { 'BRANCH_REMOVE_MERGED_GH' => gh })

      expect(stdout).to include('Would remove squashed')
      expect(local_branches(repo)).to include('squashed')
    end

    it 'still cleans up ancestry-merged branches when gh is unavailable, and says so' do
      merged_branch(repo, 'feature')

      stdout, stderr, status = run

      expect(status).to be_success
      expect(stdout).to include('Removed feature')
      expect(stderr).to include('squash-merged branches were not checked')
    end
  end

  it 'rejects an unknown argument' do
    _stdout, stderr, status = run('--wat')

    expect(status).not_to be_success
    expect(stderr).to include('usage: git branch-remove-merged [--dry-run]')
  end
end
