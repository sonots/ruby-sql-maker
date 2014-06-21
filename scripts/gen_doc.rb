require 'tempfile'
require 'fileutils'

def generate_docs(paths)
  paths.each do |path|
    tmppath = Tempfile.open('temp') do |tmpfp|
      File.open(path) do |fp|
        while line = fp.gets
          break if line.chomp == "__END__"
        end
        while line = fp.gets
          line.gsub!(/^=encoding.*/, '')
          line.gsub!(/^=over.*/, '')
          line.gsub!(/^=cut.*/, '')
          line.gsub!(/^=back.*/, '')
          line.gsub!(/^=head\d/, '=')
          line.gsub!(/^=item/, ':')
          line.gsub!(/C<< (.+) >>/, '\1')
          line.gsub!(/L<([^>]+)>/, '\1')
          line.gsub!(/B<([^>]+)>/, '\1')
          line.gsub!(/C<([^>]+)>/, '\1')
          tmpfp.puts line
        end
      end
      tmpfp.path
    end
    docpath = path.gsub('lib', 'doc').gsub(/.rb$/, '.html')
    FileUtils.mkdir_p File.dirname(docpath)
    system "bundle exec rd2 #{tmppath} | sed 's!<title>.*</title>!<title>#{path}</title>!' > #{docpath}"
  end
end

def generate_index(paths)
  html =<<EOF
<?xml version="1.0" ?>
<!DOCTYPE html 
  PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>SQL::Maker - index</title>
</head>
<body>
<h1>SQL::Maker - index</h1>
<ul>
EOF
  paths.each do |path|
    docpath = path.gsub('lib/', '').gsub(/.rb$/, '.html')
    html << "<li><a href='#{docpath}'>#{docpath}</a></li>\n"
  end
  html << '</ul></body></html>'
  File.open('doc/index.html', 'w') do |fp|
    fp.write html
  end
end

paths = %w[lib/sql/maker.rb lib/sql/query_maker.rb]
paths += Dir.glob('lib/sql/maker/*.rb').to_a
generate_index(paths)
generate_docs(paths)

