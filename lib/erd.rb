# frozen_string_literal: true

require 'erd/version'
require 'rails'
require 'erd/engine'

module Erd
  autoload :Migrator, 'erd/migrator'
  autoload :GenaratorRunner, 'erd/generator_runner'
end
