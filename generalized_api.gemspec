# frozen_string_literal: true

$LOAD_PATH.append File.expand_path("lib", __dir__)
require "generalized_api/identity"

Gem::Specification.new do |spec|
  spec.name = GeneralizedApi::Identity.name
  spec.version = GeneralizedApi::Identity.version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Gregory Havenga"]
  # spec.email = [""]
  spec.homepage = ""
  spec.summary = ""
  spec.license = ""

  # spec.metadata = {
  #   "source_code_uri" => "",
  #   "changelog_uri" => "/blob/master/CHANGES.md",
  #   "bug_tracker_uri" => "/issues"
  # }

  spec.required_ruby_version = "~> 2.5"
  spec.add_dependency "rails", "~> 5.1"
  spec.add_dependency "will_paginate"
  spec.add_development_dependency "bundler-audit", "~> 0.6"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "gemsmith", "~> 12.0"
  spec.add_development_dependency "git-cop", "~> 2.2"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-byebug", "~> 3.5"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "reek", "~> 4.8"
  spec.add_development_dependency "rspec-rails", "~> 3.7"
  spec.add_development_dependency "rubocop", "~> 0.54"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "shoulda-matchers"

  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.files = Dir["lib/**/*"]
  spec.require_paths = Dir["lib"]
end
