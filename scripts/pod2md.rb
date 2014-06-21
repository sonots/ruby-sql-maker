require 'tempfile'
require 'fileutils'

def pod2md(paths)
  paths.each do |path|
    code, md = '', ''
    File.open(path, 'r') do |fp|
      while line = fp.gets
        break if line.chomp == "__END__"
        code << line
      end
      while line = fp.gets
        line.gsub!(/^=encoding.*/, '')
        line.gsub!(/^=head1/, '#')
        line.gsub!(/^=head2/, '##')
        line.gsub!(/^=item/, '###')
        line.gsub!(/^=over.*/, '')
        line.gsub!(/^=cut.*/, '')
        line.gsub!(/^=back.*/, '')
        line.gsub!(/C<< (.+) >>/, '\1')
        line.gsub!(/L<([^>]+)>/, '\1')
        line.gsub!(/B<([^>]+)>/, '\1')
        line.gsub!(/C<([^>]+)>/, '\1')
        md << line
      end
    end
    File.open(path, 'w') do |fp|
      fp.puts code.strip
    end
    docpath = path.gsub('lib', 'doc').gsub(/.rb$/, '.md')
    FileUtils.mkdir_p File.dirname(docpath)
    File.open(docpath, 'w') do |fp|
      fp.puts md.strip
    end
  end
end

paths = %w[lib/sql/maker.rb lib/sql/query_maker.rb]
paths += Dir.glob('lib/sql/maker/*.rb').to_a
pod2md(paths)

