# frozen_string_literal: true

module GeneralizedApi
  require 'rails'
  # Defines and registers the Rails engine.
  class Engine < ::Rails::Engine
    # isolate_namespace GeneralizedApi

    config.generators do |generator|
      generator.test_framework :rspec
      generator.fixture_replacement :factory_girl, dir: 'spec/factories'
    end
  end
end
