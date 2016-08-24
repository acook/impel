require_relative 'spec_helper'

require 'benchmark'

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
  print " -- #{name.ljust(11)} :"
  puts Benchmark.measure {
    iterations.times do
      run command
    end
  }
end

file = './tmp/benchmark.sock'
File.delete(file) if File.exists?(file) && File.socket?(file)

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
    lua:         %q{lua -e 'os.exit()'},
    bash:        %q{bash -c 'exit'},
    bash_socket: bash_socket,
    perl:        %q{perl -e 'exit'},
    blacklight:  %q{blacklight -e 'quit'},
    rebol3:      %q{r3 --do 'quit'},
    python:      %q{python -c 'exit'},
    node:        %q{node -e "process.exit()"},
    io:          %q{io -e 'exit'},
    ruby:        %q{ruby -e 'exit'}
  }

  header
  interpreters.each do |name, command|
    bench name.to_s, command
  end

ensure
  server.close
  File.delete(file) if File.exists?(file) && File.socket?(file)
end
