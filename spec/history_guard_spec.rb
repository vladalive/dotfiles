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
      expect(err).to include('unsigned', 'git rebase --rebase-merges --force-rebase --gpg-sign ')
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

    # For repositories that merge locally (sandbox): only signatures, and only
    # for what the push sends that no remote branch has yet.
    describe 'signatures-only install' do
      def guarded(name)
        repo = create_repo(name)
        remote = create_bare_repo("#{name}.git")
        git!(repo, 'remote', 'add', 'origin', remote)
        git!(repo, 'push', '-q', 'origin', 'master')
        _, err, status = run_script('git-history-guard', 'install', '--signatures-only', chdir: repo)
        raise err unless status.success?
        [repo, remote]
      end

      it 'needs no base and says so in its status' do
        repo, = guarded('status')
        out, = run_script('git-history-guard', 'status', chdir: repo)
        expect(out).to eq("installed (signatures only)\n")
        expect(File.read(File.join(repo, '.git/hooks/pre-push'))).to include('pre-push --signatures-only')
      end

      it 'refuses an unsigned commit the push sends, with a rebase that keeps merges' do
        repo, remote = guarded('refuse')
        write_commit(repo, 'new.txt', 'new', 'new')
        git!(repo, 'config', 'commit.gpgsign', 'true')
        _, err, status = Open3.capture3(git_env, 'git', 'push', 'origin', 'master', chdir: repo)
        expect(status.success?).to be(false)
        expect(err).to include('unsigned', '--rebase-merges')
        expect(git!(remote, 'log', '--format=%s', 'master')).not_to include('new')
      end

      it 'lets a local merge through' do
        repo, remote = guarded('merge')
        git!(repo, 'checkout', '-qb', 'side')
        write_commit(repo, 'side.txt', 'side', 'side')
        git!(repo, 'checkout', '-q', 'master')
        write_commit(repo, 'main.txt', 'main', 'main')
        git!(repo, 'merge', '-q', '--no-ff', '-m', 'local merge', 'side')
        _, err, status = Open3.capture3(git_env, 'git', 'push', 'origin', 'master', chdir: repo)
        expect(status.success?).to be(true), err
        expect(git!(remote, 'log', '--format=%s', 'master')).to include('local merge')
      end

      it 'does not hold a push to account for commits the remote already has' do
        repo, = guarded('old')
        write_commit(repo, 'old.txt', 'old', 'old unsigned')
        git!(repo, 'push', '-q', 'origin', 'master')
        write_commit(repo, 'next.txt', 'next', 'next')
        git!(repo, 'update-ref', 'refs/heads/master', signed_copy(repo, 'HEAD'))
        git!(repo, 'config', 'commit.gpgsign', 'true')
        _, err, status = Open3.capture3(git_env, 'git', 'push', 'origin', 'master', chdir: repo)
        expect(status.success?).to be(true), err
      end
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

  # init.templateDir hands every new clone the signatures-only hook, so a
  # repository nobody remembered to set up is covered from its first push.
  describe 'clone template' do
    let(:template_source) { File.expand_path('../private_dot_config/git/template', __dir__) }

    # What chezmoi writes from the source: an executable_ name loses the prefix and gets 0755.
    def applied_template
      target = File.join(sandbox, 'template')
      Dir.glob('**/*', base: template_source).each do |rel|
        src = File.join(template_source, rel)
        next if File.directory?(src)

        name = File.basename(rel)
        dest = File.join(target, File.dirname(rel), name.delete_prefix('executable_'))
        FileUtils.mkdir_p(File.dirname(dest))
        FileUtils.cp(src, dest)
        File.chmod(name.start_with?('executable_') ? 0o755 : 0o644, dest)
      end
      bin = File.join(sandbox, '.config/git/bin')
      FileUtils.mkdir_p(bin)
      FileUtils.cp(File.join(SCRIPT_DIR, 'executable_git-history-guard'), File.join(bin, 'git-history-guard'))
      File.chmod(0o755, File.join(bin, 'git-history-guard'))
      target
    end

    it 'gives a new repository the signatures-only hook, which refuses an unsigned push' do
      repo = File.join(sandbox, 'fresh')
      git!(sandbox, 'init', '-q', '-b', 'master', "--template=#{applied_template}", repo)
      git!(repo, 'config', 'commit.gpgsign', 'false')
      write_commit(repo, 'a.txt', 'a', 'first')
      remote = create_bare_repo('fresh.git')
      git!(repo, 'remote', 'add', 'origin', remote)
      git!(repo, 'push', '-q', 'origin', 'master')
      out, = run_script('git-history-guard', 'status', chdir: repo)
      expect(out).to eq("installed (signatures only)\n")

      write_commit(repo, 'b.txt', 'b', 'second')
      git!(repo, 'config', 'commit.gpgsign', 'true')
      _, err, status = Open3.capture3(git_env, 'git', 'push', 'origin', 'master', chdir: repo)
      expect(status.success?).to be(false)
      expect(err).to include('unsigned')
      expect(File).to exist(File.join(repo, '.git/info/exclude'))
    end

    it 'is where the git config points init' do
      fragment = File.expand_path('../private_dot_config/git/config.d/00-core.gitconfig', __dir__)
      out, = Open3.capture2('git', 'config', '--file', fragment, '--get', 'init.templateDir')
      expect(out.strip).to eq('~/.config/git/template')
    end
  end
end
