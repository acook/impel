require_relative 'spec_helper'

require 'benchmark'
require 'socket'

spec 'running benchmarks' do
  true
end

def self.iterations
  200
end

def self.header
  puts "                     USER      SYSTEM     TOTAL        REAL"
end

def self.bench name, command
  output = nil
  print " -- #{name.ljust(11)} :"
  stats = Benchmark.measure {
    iterations.times do
      _, output = run command
    end
  }
  out = output.stdout.strip + output.stderr.strip
  puts stats unless out.include? 'command not found'
  puts "\t#{out}" unless out.empty?
rescue => err
  puts err.full_message
end

Dir.mkdir './tmp' unless File.exist? './tmp'
file = './tmp/benchmark.sock'
File.delete(file) if File.exist?(file) && File.socket?(file)

server = UNIXServer.new(file)
#socket = server.accept

begin

  bash_socket = <<-BASH_SOCKET
    bash -c "
      exec 3<> ./tmp/benchmark.sock

      exec 3<&-
      exec 3>&-
      exit
    "
  BASH_SOCKET

  interpreters = {
    luajit:      %q{luajit -e 'os.exit()'},
    blacklight:  %q{blacklight -e '@'},
    lua:         %q{lua -e 'os.exit()'},
    bash:        %q{bash -c 'exit'},
    #bash_socket: bash_socket,
    perl:        %q{perl -e 'exit'},
    mruby:       %q{mruby -e 'Array.new'},
    python:      %q{python -c 'exit'},
    rebol2:      %q{rebol2 -q --do 'quit'},
    nodejs:      %q{node -e "process.exit()"},
    rebol3:      %q{r3 --do 'quit'},
    ruby:        %q{ruby -e 'exit'},
    erlang:      %q{erl -noshell -eval 'halt(0).'},
    elixir:      %q{elixir -e 'System.halt(0)'},
  }

  header
  interpreters.each do |name, command|
    bench name.to_s, command
  end

ensure
  server.close
  File.delete(file) if File.exist?(file) && File.socket?(file)
end
