# encoding: UTF-8
require 'rubygems'
require 'bundler'
Bundler.setup(:default, :test)
Bundler.require(:default, :test)

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
end

$TESTING=true
$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
