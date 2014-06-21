require_relative '../../spec_helper'
require 'sql/maker/select'

begin
  fname = "#{ROOT}/doc/sql/maker/select.md"
  file = File.open(fname)
  lineno = 0
  while line = file.gets
    lineno += 1
    break if line =~ /=head1/
  end
  code = ''
  describe 'SQL::Maker::Select' do
    it do
      while line = file.gets
        lineno += 1
        next if line =~ /^ *#/
        if line =~ /^[ ]{4,}.*# => (.+)/
          # puts "----------------------"
          # puts code
          expected = eval($1, binding)
          got = eval(code, binding, fname, lineno - 4)
          got.gsub!(/\n/, ' ')
          got.gsub!(/ +$/, '')
          expect(got).to be == expected
        elsif line =~ /^[ ]{4,}(.+)/
          code += "#{$1}\n"
        else
          code = '' # clear
        end
      end
    end
  end
end
