require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov.formatter,
  Coveralls::SimpleCov::Formatter,
]
SimpleCov.start
