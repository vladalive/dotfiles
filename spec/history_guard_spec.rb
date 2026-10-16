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

  # While GPG was broken on 2026-10-16, queue sessions committed with
  # -c commit.gpgsign=false and pushed unsigned commits to three PRs.
  describe 'commit signatures' do
    def signed_copy(repo, rev)
      raw = git!(repo, 'cat-file', 'commit', rev)
      header, body = raw.split("\n\n", 2)
      sig = "gpgsig -----BEGIN PGP SIGNATURE-----\n \n -----END PGP SIGNATURE-----"
      out, status = Open3.capture2(git_env, 'git', 'hash-object', '-t', 'commit', '-w', '--stdin',
                                   stdin_data: "#{header}\n#{sig}\n\n#{body}", chdir: repo)
      raise 'hash-object failed' unless status.success?
      out.strip
    end

    def unsigned_branch(name = 'repo')
      repo = create_repo(name)
      git!(repo, 'checkout', '-qb', 'feature')
      write_commit(repo, 'feature.txt', 'feature', 'feature')
      git!(repo, 'config', 'commit.gpgsign', 'true')
      repo
    end

    it 'refuses an unsigned commit of ours where commits are meant to be signed' do
      _, err, status = run_script('git-history-guard', 'check', '--base', 'master', chdir: unsigned_branch)
      expect(status.exitstatus).to eq(1)
      expect(err).to include('unsigned', 'rebase --force-rebase --gpg-sign $(git merge-base HEAD master)')
    end

    it 'accepts a signed commit, and a host that does not sign' do
      repo = unsigned_branch
      git!(repo, 'update-ref', 'refs/heads/feature', signed_copy(repo, 'HEAD'))
      _, err, status = run_script('git-history-guard', 'check', '--base', 'master', chdir: repo)
      expect(status.success?).to be(true), err

      repo = unsigned_branch('nosign')
      git!(repo, 'config', 'commit.gpgsign', 'false')
      _, err, status = run_script('git-history-guard', 'check', '--base', 'master', chdir: repo)
      expect(status.success?).to be(true), err
    end

    it "leaves someone else's unsigned commit alone" do
      repo = create_repo
      git!(repo, 'checkout', '-qb', 'feature')
      write_commit(repo, 'theirs.txt', 'theirs', 'theirs', author: 'Team Mate')
      git!(repo, 'config', 'commit.gpgsign', 'true')
      _, err, status = run_script('git-history-guard', 'check', '--base', 'master', chdir: repo)
      expect(status.success?).to be(true), err
    end

    it 'blocks the actual push' do
      repo = unsigned_branch
      remote = create_bare_repo
      git!(repo, 'remote', 'add', 'origin', remote)
      _, err, status = run_script('git-history-guard', 'install', '--base', 'master', chdir: repo)
      expect(status.success?).to be(true), err
      _, err, status = Open3.capture3(git_env, 'git', 'push', 'origin', 'feature', chdir: repo)
      expect(status.success?).to be(false)
      expect(err).to include('unsigned')
      expect(remote_branches(remote)).not_to include('feature')
    end
  end
end
