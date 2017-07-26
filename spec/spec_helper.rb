require 'chefspec'
require 'chefspec/berkshelf'

Dir['*_spec.rb'].each { |f| require File.expand_path(f) }
at_exit { ChefSpec::Coverage.report! }
