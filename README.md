# ruby-sql-maker

[![Build Status](https://secure.travis-ci.org/sonots/ruby-sql-maker.png?branch=master)](http://travis-ci.org/sonots/ruby-sql-maker)
[![Coverage Status](https://coveralls.io/repos/sonots/ruby-sql-maker/badge.png?branch=master)](https://coveralls.io/r/sonots/ruby-sql-maker?branch=master)

SQL Builder for Ruby

## Installation

Add the following to your `Gemfile`:

```ruby
gem 'sql-maker'
```

And then execute:

```plain
$ bundle
```

## Example

```ruby
require 'sql-maker'
builder = SQL::Maker::Select.new(:quote_char => '"', :auto_bind => true)
builder.add_select('id').add_from('books').add_where('books.id' => 1).as_sql
#=> SELECT "id" FROM "books" WHERE "books"."id" = 1
```

To avoid quoting the column name, use `sql_raw`.

```ruby
require 'sql-maker'
include SQL::Maker::Helper # adds sql_raw, etc
builder = SQL::Maker::Select.new(:quote_char => '"', :auto_bind => true)
builder.add_select(sql_raw('COUNT(*)')).add_from('books').as_sql
# => SELECT COUNT(*) FROM "books"
```

## Further Reading

Please see the [doc](./doc) directory.

## ChangeLog

See [CHANGELOG.md](CHANGELOG.md) for details.

## ToDo

1. Support plugins

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new [Pull Request](../../pull/new/master)

## Copyright

Copyright (c) 2014 Naotoshi Seo. See [LICENSE.txt](LICENSE.txt) for details.

## Acknowledgement

Ruby SQL::Maker is a ruby port of following perl modules: 

1. https://github.com/tokuhirom/SQL-Maker
2. https://github.com/kazuho/SQL-QueryMaker

Thank you very much!!!
