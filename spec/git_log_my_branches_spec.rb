# frozen_string_literal: true

RSpec.describe 'git log-my-branches' do
  let(:repo) { create_repo }

  def run(*args)
    run_script('git-log-my-branches', *args, chdir: repo)
  end

  def orphan(name, date: nil, author: nil)
    git!(repo, 'checkout', '-q', '--orphan', name)
    write_commit(repo, "#{name}.txt", "#{name}\n", "work on #{name}", date: date, author: author)
    git!(repo, 'checkout', '-qf', 'master')
  end

  def branch_order(stdout)
    stdout.lines.drop(1).map { |line| line.split.last }
  end

  it 'lists branches I committed to inside the period, newest first' do
    git!(repo, 'checkout', '-q', '-b', 'older')
    write_commit(repo, 'older.txt', "older\n", 'older work', date: days_ago(10))
    git!(repo, 'checkout', '-q', '-b', 'newer', 'master')
    write_commit(repo, 'newer.txt', "newer\n", 'newer work', date: days_ago(2))
    git!(repo, 'checkout', '-q', 'master')

    stdout, _stderr, status = run('month')

    expect(status).to be_success
    expect(stdout).to start_with("my branches since 1 month ago:\n")
    # master's own commit is the initial one, dated now, so it leads.
    expect(branch_order(stdout)).to eq(%w[master newer older])
  end

  it 'omits a branch whose last commit of mine predates the period' do
    orphan('stale', date: days_ago(400))

    stdout, _stderr, = run('week')

    expect(branch_order(stdout)).not_to include('stale')
  end

  it 'omits a branch nobody but someone else committed to' do
    orphan('theirs', author: 'Other Person')

    stdout, _stderr, = run('week')

    expect(branch_order(stdout)).not_to include('theirs')
  end

  it 'defaults to a week' do
    stdout, _stderr, status = run

    expect(status).to be_success
    expect(stdout).to start_with("my branches since 1 week ago:\n")
  end

  it 'rejects a period it does not understand' do
    _stdout, stderr, status = run('fortnight')

    expect(status).not_to be_success
    expect(stderr).to include('usage: git log-my-branches [day|week|month|year]')
  end
end
