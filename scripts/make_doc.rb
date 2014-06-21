require 'tempfile'
require 'fileutils'

def extract_md(paths)
  paths.each do |path|
    md = ''
    File.open(path, 'r') do |fp|
      while line = fp.gets
        break if line.chomp == "__END__"
      end
      while line = fp.gets
        md << line
      end
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
extract_md(paths)
