# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{duostack}
  s.version = "0.0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David E. Chen", "Todd Eichel"]
  s.date = %q{2011-01-20}
  s.description = %q{Duostack command line client: create and manage Duostack apps}
  s.email = ["dave@duostack.com", "todd@toddeichel.com"]
  s.executables = ["duostack", ".duostack-console-expect"]
  s.files = [
    ".document",
    "Rakefile",
    "bin/.duostack-console-expect",
    "bin/bash/.duostack-console-expect",
    "bin/duostack",
    "duostack.gemspec"
  ]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Duostack command line client}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
