filename = ARGV.first
body = File.read(filename)

body.gsub!(/ eq /, ' == ')
body.gsub!(/\$([_A-Za-z]\w*)->\{([_A-Za-z]\w*)\}/, '\1.\2') # $self->{var} => self.var
body.gsub!(/\$([_A-Za-z]\w*)->([_A-Za-z]\w*)/, '\1.\2') # $self->var => self.var
body.gsub!(/\$([_A-Za-z]\w*)/, '\1') # $var => var
body.gsub!(/\@([_A-Za-z]\w*)/, '\1') # @var => var
body.gsub!(/ \. /, ' + ') # str . str => str + str
body.gsub!(/join\('([^']+)', ([^)]+)\)/, '\2.join(\'\1\')') # join(', ', foo) => foo.join(', ')
body.gsub!(/subtest '([^']+)' => sub {/, 'it \'\1\' do') # subtest '[]' => sub { => it '[]' do
body.gsub!(/sub ([_A-Za-z]\w*) {/, 'def \1') # sub sql_op { => def sql_op
body.gsub!(/([_A-Za-z]\w*) => /, ':\1 => ') # x => [] to :x => []
body.gsub!(/ +};$/, 'end') # }; => end
body.gsub!(/}$/, 'end') # } => end
body.gsub!(/my /, '') # remove my
body.gsub!(/->/, '.') # foo->var => foo.var
body.gsub!(/;$/, '')
body.gsub!(/\\'$/, "'") # \' => '
body.gsub!(/\\\[$/, "[") # \[ => [
body.gsub!(/qq{/, '%Q{')
#body.gsub!(/\[ qw\/([^/]+)\/ \]/, '%w/\1/')
body.gsub!(/ordered_hashref\(([^)]+)\)/, '{\1}')
body.gsub!(/use strict/, '')
body.gsub!(/\(sql, bind\)/, 'sql, bind')
body.gsub!(/use warnings/, '')
body.gsub!(/use Test::More/, "require_relative '../spec_helper'")
body.gsub!(/use SQL::Maker/, "require 'sql/maker'")
body.gsub!(/use SQL::QueryMaker/, "require 'sql/query_maker'")
body.gsub!(/done_testing/, '')
body.gsub!(/is ([^,]+), (.+)$/, 'expect(\1).to be == \2')
body.gsub!(/is\(([^,]+), (.+)\)$/, 'expect(\1).to be == \2')
body.gsub!(/is ([^(]+\([^)]+\)), (.+)$/, 'expect(\1).to be == \2') # is foo.join(', '), '1'
puts body.strip
