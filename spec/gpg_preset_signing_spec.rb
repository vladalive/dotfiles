# frozen_string_literal: true

require_relative 'spec_helper'

# gpg-preset-signing runs git, gpg, envs, gpgconf and gpg-preset-passphrase.
# Each is a stub on PATH that keeps its state in files: whether the key is
# unlocked, what the preset tool received on stdin, whether the agent was
# restarted. The real gpg-agent and BWS stay out of reach.
RSpec.describe 'gpg-preset-signing' do
  let(:passphrase) { 'correct horse battery staple' }
  let(:keyid) { '29CABA9A1CB33A8A' }

  around do |example|
    Dir.mktmpdir('gpg-preset-') do |dir|
      @dir = dir
      @state = File.join(dir, 'state').tap { FileUtils.mkdir_p(_1) }
      @bin = File.join(dir, 'bin').tap { FileUtils.mkdir_p(_1) }
      write_stubs
      example.run
    end
  end

  def stub(name, body)
    path = File.join(@bin, name)
    File.write(path, "#!/bin/sh\nS=#{@state}\n#{body}\n")
    File.chmod(0o755, path)
  end

  def write_stubs
    stub('git', %(echo "BB40A87C1C26979B386DFB7F#{keyid}"))
    stub('gpg', <<~SH)
      case "$*" in
        *--clearsign*) cat >/dev/null; [ -f "$S/unlocked" ] ;;
        *--list-secret-keys*) printf 'sec:u:255:22:#{keyid}:::::::::\\ngrp:::::::::GRIP1:\\nssb:u:255:18:X:::::::::\\ngrp:::::::::GRIP2:\\n' ;;
      esac
    SH
    stub('envs', <<~SH)
      if [ -f "$S/stored" ]; then printf '%s\\n' "$(cat "$S/stored")"; else echo "Secret not found: $7" >&2; exit 1; fi
    SH
    stub('gpgconf', <<~SH)
      case "$1" in
        --list-dirs) echo "#{@bin}" ;;
        --kill) touch "$S/killed" ;;
      esac
    SH
    stub('gpg-preset-passphrase', <<~SH)
      if [ -f "$S/unsupported" ] && [ ! -f "$S/killed" ]; then
        cat >/dev/null; echo "gpg-preset-passphrase: caching passphrase failed: Not supported" >&2; exit 2
      fi
      cat > "$S/preset-$2"
      [ "$(cat "$S/preset-$2")" = "$(cat "$S/stored")" ] && touch "$S/unlocked"
      exit 0
    SH
  end

  def run(*args)
    env = { 'PATH' => "#{@bin}:/usr/bin:/bin" }
    script = File.join(SCRIPT_DIR, 'executable_gpg-preset-signing')
    Open3.capture3(env, RbConfig.ruby, script, *args)
  end

  def state(name) = File.join(@state, name)

  it 'does nothing when the key is already unlocked' do
    FileUtils.touch(state('unlocked'))

    out, _err, status = run

    expect(status.exitstatus).to eq(0)
    expect(out).to include("#{keyid} is already unlocked")
    expect(Dir.children(@state)).not_to include('preset-GRIP1')
  end

  it 'presets every keygrip from BWS without printing the passphrase' do
    File.write(state('stored'), passphrase)

    out, err, status = run

    expect(status.exitstatus).to eq(0)
    expect(out).to include("#{keyid} unlocked")
    expect(File.read(state('preset-GRIP1'))).to eq(passphrase)
    expect(File.read(state('preset-GRIP2'))).to eq(passphrase)
    expect(out + err).not_to include(passphrase)
  end

  it 'exits 3 with the command to store the passphrase when BWS has none' do
    _out, err, status = run

    expect(status.exitstatus).to eq(3)
    expect(err).to include("bws-envs secret set services/gpg-signing/local/production/GPG_PASSPHRASE_#{keyid}")
  end

  it 'restarts a locked agent that predates allow-preset-passphrase, then presets' do
    File.write(state('stored'), passphrase)
    FileUtils.touch(state('unsupported'))

    out, _err, status = run

    expect(status.exitstatus).to eq(0)
    expect(File).to exist(state('killed'))
    expect(out).to include('restarted gpg-agent')
  end

  it 'fails when the stored passphrase does not unlock the key' do
    File.write(state('stored'), passphrase)
    stub('gpg-preset-passphrase', 'cat > "$S/preset-$2"; exit 0')

    _out, err, status = run

    expect(status.exitstatus).to eq(1)
    expect(err).to include('signing still fails')
  end

  it 'reports locked or unlocked with --check and presets nothing' do
    File.write(state('stored'), passphrase)

    _out, err, status = run('--check')
    expect([status.exitstatus, err]).to match([1, /locked/])

    FileUtils.touch(state('unlocked'))
    out, _err, status = run('--check')
    expect([status.exitstatus, out]).to match([0, /is unlocked/])
    expect(Dir.children(@state)).not_to include('preset-GRIP1')
  end
end
