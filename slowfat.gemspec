# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'slowfat/version'

Gem::Specification.new do |s|
  s.name = "slowfat"
  s.version = SlowFat::VERSION

  s.description = "FAT filesystem library for use with slow I/O (e.g. serial links)"
  s.homepage = "http://github.com/sarahemm/ruby-slowfat"
  s.summary = "Slow I/O FAT interface library"
  s.licenses = "MIT"
  s.authors = ["sarahemm"]
  s.email = "github@sen.cx"
  
  s.files = Dir.glob("{lib,spec}/**/*") + %w(README.md Rakefile)
  s.require_path = "lib"

  s.rubygems_version = "2.7.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
end
