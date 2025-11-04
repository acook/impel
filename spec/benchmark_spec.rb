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
  output = nil
  status = nil
  print " -- #{name.ljust(11)} :"
  stats = Benchmark.measure {
    iterations.times do
      status, output = run command
    end
  }
  out = output.stdout.strip + output.stderr.strip
  puts stats unless status.exitstatus != 0
  puts "\t#{out}" unless out.empty?
rescue => err
  puts err.full_message
end


begin

  interpreters = {
    luajit:      %q{luajit -e 'os.exit()'},
    blacklight:  %q{blacklight -e '@'},
    lua:         %q{lua -e 'os.exit()'},
    bash:        %q{bash -c 'exit'},
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
end
