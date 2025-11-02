require 'bundler'
Bundler.require :test

require 'uspec'
extend Uspec

module Uspec; class Define
  def run *args
    output = Struct.new :pid, :stdout, :stderr

    status = Open4.popen4(*args) do |pid, stdin, stdout, stderr|
      output = output.new pid, stdout.read, stderr.read
    end

    [status, output]
  end
end; end
