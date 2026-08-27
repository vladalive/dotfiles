# frozen_string_literal: true

RSpec.describe 'git branch-remove-merged-remote' do
  let(:bare) { create_bare_repo }
  let(:repo) do
    create_repo.tap do |path|
      git!(path, 'remote', 'add', 'origin', bare)
      git!(path, 'push', '-q', 'origin', 'master')
    end
  end

  def run(*args)
    run_script('git-branch-remove-merged-remote', *args, chdir: repo)
  end

  def push_merged(name)
    merged_branch(repo, name)
    git!(repo, 'push', '-q', 'origin', name)
    git!(repo, 'push', '-q', 'origin', 'master')
  end

  it 'deletes a merged branch on the remote' do
    push_merged('feature')

    stdout, _stderr, status = run

    expect(status).to be_success
    expect(stdout).to include('Deleted 1 merged branch on origin.')
    expect(remote_branches(bare)).not_to include('feature')
    expect(remote_branches(bare)).to include('master')
  end

  it 'never touches a protected branch' do
    push_merged('develop')

    stdout, _stderr, = run

    expect(stdout).to include('No merged branches to delete.')
    expect(remote_branches(bare)).to include('develop')
  end

  # The shell version protected this by accident, through an unanchored grep for
  # "master". Protection is now the exact name, so this one is cleanable.
  it 'treats a branch that merely contains a protected word as ordinary' do
    push_merged('release/master-fix')

    _stdout, _stderr, status = run

    expect(status).to be_success
    expect(remote_branches(bare)).not_to include('release/master-fix')
  end

  it 'ignores the remote HEAD pointer' do
    git!(repo, 'remote', 'set-head', 'origin', 'master')

    stdout, _stderr, status = run

    expect(status).to be_success
    expect(stdout).to include('No merged branches to delete.')
  end

  it 'reports without deleting under --dry-run' do
    push_merged('feature')

    stdout, _stderr, status = run('--dry-run')

    expect(status).to be_success
    expect(stdout).to include('Would delete 1 merged branch on origin:')
    expect(stdout).to include('  feature')
    expect(remote_branches(bare)).to include('feature')
  end

  it 'rejects more than one remote' do
    _stdout, stderr, status = run('origin', 'upstream')

    expect(status).not_to be_success
    expect(stderr).to include('usage: git branch-remove-merged-remote')
  end
end
