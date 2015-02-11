# ruby-sql-maker

[![Build Status](https://secure.travis-ci.org/sonots/ruby-sql-maker.png?branch=master)](http://travis-ci.org/sonots/ruby-sql-maker)

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

You may want to use quoting or SQL escape function together with `sql_raw`. 

```ruby
SQL::Maker::Quoting.quote("gi'thubber's")  #=> 'gi''thubber''s'
SQL::Maker::Quoting.escape("gi'thubber's") #=> gi''thubber''s
```

## Further Reading

Please see the [doc](./doc) directory.

## The JSON SQL Injection Vulnerability

Both perl and ruby verion of SQL::Maker has a JSON SQL Injection Vulnerability if not used in `strict` mode.

Therefore, I strongly recommend to use SQL::Maker in `strict` mode.
You can turn on the `strict` mode by passing `:strict => true` as:

```ruby
SQL::Maker.new(...., :strict => true)
SQL::Maker::Select.new(...., :strict => true)
```

In strict mode, array or hash conditions are not accepted anymore. A sample usage snippet is shown in below:

```ruby
require 'sql-maker'
include SQL::Maker::Helper # adds SQL::QueryMaker functions such as sql_le, etc

builder = SQL::Maker::Select.new(:strict => true)

builder.select('user', ['*'], {:name => json['name']}) 
#=> SELECT * FROM `user` WHERE `name` = ?

builder.select('user', ['*'], {:name => ['foo', 'bar']})
#=> SQL::Maker::Error! Will not generate SELECT * FROM `name` IN (?, ?) any more

builder.select('user', ['*'], {:name => sql_in(['foo', 'bar'])})
#=> SELECT * FROM `user` WHERE `name` IN (?, ?)

builder.select('fruit', ['*'], {:price => sql_le(json['max_price'])})
#=> SELECT * FROM `fruit` WHERE `price` <= ?
```

See following articles for more details (perl version)

* http://blog.kazuhooku.com/2014/07/the-json-sql-injection-vulnerability.html (English)
* http://developers.mobage.jp/blog/2014/7/3/jsonsql-injection (Japanese)

## See Also

* [perl の SQL::Maker (と SQL::QueryMaker) を ruby に移植した - sonots:blog](http://blog.livedoor.jp/sonots/archives/38723820.html) (Japanese)

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
