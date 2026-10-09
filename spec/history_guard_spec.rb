# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'git-history-guard' do
  def history
    repo = create_repo
    git!(repo, 'checkout', '-qb', 'feature')
    write_commit(repo, 'feature.txt', 'feature', 'feature')
    git!(repo, 'checkout', '-q', 'master')
    write_commit(repo, 'base.txt', 'base', 'base')
    git!(repo, 'checkout', '-q', 'feature')
    git!(repo, 'merge', '--no-ff', '-m', 'unwanted merge', 'master')
    repo
  end

  it 'rejects a merge in the PR range and accepts it as inherited from a stack parent' do
    repo = history
    _, err, status = run_script('git-history-guard', 'check', '--base', 'master', chdir: repo)
    expect(status.exitstatus).to eq(1)
    expect(err).to include('rebase', 'merge')
    git!(repo, 'checkout', '-qb', 'child')
    write_commit(repo, 'child.txt', 'child', 'child')
    _, err, status = run_script('git-history-guard', 'check', '--base', 'feature', chdir: repo)
    expect(status.success?).to be(true), err
  end

  it 'fails closed on a missing base' do
    repo = create_repo
    _, err, status = run_script('git-history-guard', 'check', '--base', 'missing', chdir: repo)
    expect(status.exitstatus).to eq(2)
    expect(err).to include('base')
  end

  it 'blocks an actual push, preserves the preceding hook and supports uninstall' do
    repo = history
    remote = create_bare_repo
    git!(repo, 'remote', 'add', 'origin', remote)
    hook = File.join(repo, '.git/hooks/pre-push')
    original = "#!/bin/sh\ncat > pushed-refs\n"
    File.write(hook, original)
    File.chmod(0o755, hook)
    _, err, status = run_script('git-history-guard', 'install', '--base', 'master', chdir: repo)
    expect(status.success?).to be(true), err
    _, err, status = Open3.capture3(git_env, 'git', 'push', 'origin', 'feature', chdir: repo)
    expect(status.success?).to be(false)
    expect(err).to include('merge')
    expect(remote_branches(remote)).not_to include('feature')
    # A stack parent explicitly records that the merge is inherited.
    git!(repo, 'branch', 'parent', 'feature')
    git!(repo, 'config', 'branch.feature.agentsKitBase', 'parent')
    git!(repo, 'push', 'origin', 'feature')
    expect(File.read(File.join(repo, 'pushed-refs'))).to include('refs/heads/feature')
    _, err, status = run_script('git-history-guard', 'uninstall', chdir: repo)
    expect(status.success?).to be(true), err
    expect(File.read(hook)).to eq(original)
  end
end
