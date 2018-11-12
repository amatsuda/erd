# frozen_string_literal: true

require 'rubygems'
require 'bundler'

Bundler.require :default, :development

Combustion.initialize!
run Combustion::Application
