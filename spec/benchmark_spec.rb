require_relative 'spec_helper'

require 'benchmark'
require 'tempfile'

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
  puts stats if status.exitstatus == 0
  puts "\tstatus: #{status.exitstatus}" unless status.exitstatus == 0
  puts "\t#{out}" unless out.empty?
rescue => err
  puts err.full_message
end

def self.compile cc, source_file
  temp_binary = Tempfile.create
  temp_binary.close
  compile_command = "#{cc} #{source_file} -o #{temp_binary.path}"
  status, output = run compile_command

  p compile_command, output unless status.exitstatus == 0
  temp_binary.path
end

temp_files = Array.new
temp_c_source = Tempfile.create ['', '.c']
File.open(temp_c_source.path, 'w') do |f|
  f << <<~EOF
    int main() {return 0;}
  EOF
end
temp_clang = compile 'clang', temp_c_source.path
temp_gcc = compile 'gcc', temp_c_source.path
temp_files << temp_c_source.path
temp_files << temp_clang
temp_files << temp_gcc

temp_v_source = Tempfile.create ['', '.v']
File.open(temp_v_source.path, 'w') do |f|
  f << <<~EOF
    module main
    fn main() { return }
  EOF
end
temp_v = compile 'v', temp_v_source.path
temp_files << temp_v_source.path
temp_files << temp_v

begin

  interpreters = {
    clang:       temp_clang,
    gcc:         temp_gcc,
    v:           temp_v,
    luajit:      %q{luajit -e 'os.exit()'},
    blacklight:  %q{blacklight -e '@'},
    lua:         %q{lua -e 'os.exit()'},
    dash:        %q{dash -c 'exit'},
    bash:        %q{bash -c 'exit'},
    perl:        %q{perl -e 'exit'},
    mruby:       %q{mruby -e 'Array.new'},
    zsh:         %q{zsh -c 'exit'},
    python:      %q{python -c 'exit'},
    rebol2:      %q{rebol2 -q --do 'quit'},
    rebol3:      %q{r3 --do 'quit'},
    nodejs:      %q{node -e "process.exit()"},
    fish:        %q{fish -c 'exit'},
    ruby:        %q{ruby -e 'exit'},
    v_run:       %Q{v run #{temp_v_source.path}},
    erlang:      %q{erl -noshell -eval 'halt(0).'},
    elixir:      %q{elixir -e 'System.halt(0)'},
  }

  header
  interpreters.each do |name, command|
    bench name.to_s, command
  end

ensure
  temp_files.each do |f|
    File.unlink f
  end
end
