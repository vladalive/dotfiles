# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'rbconfig'
require 'tmpdir'

SCRIPT_DIR = File.expand_path('../private_dot_config/git/bin', __dir__)

# Every example gets a throwaway $HOME and a throwaway repository. The real
# ~/.gitconfig is deliberately out of reach: it signs commits, sets merge.ff and
# defines the very aliases under test, all of which would make these specs pass
# or fail for reasons that have nothing to do with the scripts.
module GitScriptHelper
  BASE_ENV = {
    'GIT_CONFIG_SYSTEM' => '/dev/null',
    'GIT_AUTHOR_NAME' => 'Test Author',
    'GIT_AUTHOR_EMAIL' => 'author@example.test',
    'GIT_COMMITTER_NAME' => 'Test Author',
    'GIT_COMMITTER_EMAIL' => 'author@example.test'
  }.freeze

  attr_reader :sandbox

  def git_env
    BASE_ENV.merge(
      'HOME' => sandbox,
      'GIT_CONFIG_GLOBAL' => File.join(sandbox, 'gitconfig-empty')
    )
  end

  def git!(dir, *args, env: {})
    stdout, stderr, status = Open3.capture3(git_env.merge(env), 'git', *args, chdir: dir)
    raise "git #{args.join(' ')} failed in #{dir}:\n#{stderr}" unless status.success?

    stdout
  end

  def run_script(name, *args, chdir:)
    Open3.capture3(
      git_env, RbConfig.ruby, File.join(SCRIPT_DIR, "executable_#{name}"), *args, chdir: chdir
    )
  end

  def create_repo(name = 'repo')
    path = File.join(sandbox, name)
    FileUtils.mkdir_p(path)
    git!(path, 'init', '-q', '-b', 'master')
    git!(path, 'config', 'user.name', 'Test Author')
    git!(path, 'config', 'user.email', 'author@example.test')
    git!(path, 'config', 'commit.gpgsign', 'false')
    write_commit(path, 'README.md', "hello\n", 'initial commit')
    path
  end

  def create_bare_repo(name = 'origin.git')
    path = File.join(sandbox, name)
    git!(sandbox, 'init', '-q', '--bare', '-b', 'master', path)
    path
  end

  def write_commit(repo, file, content, message, date: nil, author: nil)
    File.write(File.join(repo, file), content)
    git!(repo, 'add', '--all')

    env = {}
    env['GIT_AUTHOR_DATE'] = env['GIT_COMMITTER_DATE'] = date if date
    if author
      env['GIT_AUTHOR_NAME'] = env['GIT_COMMITTER_NAME'] = author
      env['GIT_AUTHOR_EMAIL'] = env['GIT_COMMITTER_EMAIL'] = "#{author.downcase.tr(' ', '.')}@example.test"
    end

    git!(repo, 'commit', '-q', '-m', message, env: env)
  end

  # A branch with a commit of its own, merged into master with a merge commit so
  # it stays a distinct ancestor rather than being fast-forwarded away.
  def merged_branch(repo, name, file: nil)
    git!(repo, 'checkout', '-q', '-b', name)
    write_commit(repo, file || "#{name.tr('/', '-')}.txt", "#{name}\n", "work on #{name}")
    git!(repo, 'checkout', '-q', 'master')
    git!(repo, 'merge', '-q', '--no-ff', '-m', "merge #{name}", name)
    name
  end

  def days_ago(count)
    (Time.now - (count * 86_400)).strftime('%Y-%m-%dT%H:%M:%S%z')
  end

  def local_branches(repo)
    git!(repo, 'for-each-ref', '--format=%(refname:short)', 'refs/heads').split("\n")
  end

  def remote_branches(bare)
    git!(bare, 'for-each-ref', '--format=%(refname:short)', 'refs/heads').split("\n")
  end

  # spawn returns once the child is forked, which can be a moment before it has
  # chdir'd; without this the live-process guard is a coin flip.
  def wait_for_cwd(pid, dir, timeout: 5.0)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      cwd = begin
        File.realpath("/proc/#{pid}/cwd")
      rescue SystemCallError
        nil
      end
      return true if cwd == dir

      sleep 0.01
    end

    raise "process #{pid} never reported #{dir} as its cwd"
  end

  def with_process_in(dir)
    pid = spawn('sleep', '30', chdir: dir)
    wait_for_cwd(pid, dir)
    yield
  ensure
    if pid
      Process.kill('TERM', pid)
      Process.wait(pid)
    end
  end
end

RSpec.configure do |config|
  config.include GitScriptHelper
  config.disable_monkey_patching!
  config.order = :random

  config.around do |example|
    Dir.mktmpdir('git-scripts-spec') do |dir|
      @sandbox = File.realpath(dir)
      FileUtils.touch(File.join(@sandbox, 'gitconfig-empty'))
      example.run
    end
  end
end
