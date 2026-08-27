# frozen_string_literal: true

RSpec.describe 'git grep-replace' do
  let(:repo) { create_repo }

  def run(*args)
    run_script('git-grep-replace', *args, chdir: repo)
  end

  def read(file)
    File.read(File.join(repo, file))
  end

  it 'replaces the pattern in every tracked file that matches' do
    write_commit(repo, 'a.txt', "keep OLD keep\n", 'a')
    write_commit(repo, 'b.txt', "OLD\nOLD\n", 'b')

    stdout, _stderr, status = run('OLD', 'NEW')

    expect(status).to be_success
    expect(stdout).to include('Replaced 3 occurrences in 2 files.')
    expect(read('a.txt')).to eq("keep NEW keep\n")
    expect(read('b.txt')).to eq("NEW\nNEW\n")
  end

  # The whole reason this stopped being a shell alias: `sed -i "s/$1/$2/g"`
  # unquoted turned a space into an argument break and a slash into a delimiter.
  it 'handles a pattern and replacement containing spaces and slashes' do
    write_commit(repo, 'config.yml', "url: http://old.example/api v1\n", 'config')

    _stdout, _stderr, status = run('http://old.example/api v1', 'https://new.example/api v2')

    expect(status).to be_success
    expect(read('config.yml')).to eq("url: https://new.example/api v2\n")
  end

  it 'supports capture groups in the replacement' do
    write_commit(repo, 'names.txt', "alpha_old\nbeta_old\n", 'names')

    _stdout, _stderr, status = run('(\w+)_old', '\1_new')

    expect(status).to be_success
    expect(read('names.txt')).to eq("alpha_new\nbeta_new\n")
  end

  it 'leaves untracked files alone' do
    write_commit(repo, 'tracked.txt', "OLD\n", 'tracked')
    File.write(File.join(repo, 'untracked.txt'), "OLD\n")

    run('OLD', 'NEW')

    expect(read('tracked.txt')).to eq("NEW\n")
    expect(read('untracked.txt')).to eq("OLD\n")
  end

  it 'reports without writing under --dry-run' do
    write_commit(repo, 'a.txt', "OLD OLD\n", 'a')

    stdout, _stderr, status = run('--dry-run', 'OLD', 'NEW')

    expect(status).to be_success
    expect(stdout).to include('a.txt: 2 matches')
    expect(stdout).to include('Would replace 2 occurrences in 1 file.')
    expect(read('a.txt')).to eq("OLD OLD\n")
  end

  it 'says so when nothing matches' do
    stdout, _stderr, status = run('nothing-here', 'x')

    expect(status).to be_success
    expect(stdout).to include('No tracked file matches')
  end

  it 'rejects a missing replacement' do
    _stdout, stderr, status = run('OLD')

    expect(status).not_to be_success
    expect(stderr).to include('usage: git grep-replace [--dry-run] <pattern> <replacement>')
  end
end
