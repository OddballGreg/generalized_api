# frozen_string_literal: true

module GeneralizedApi
  require 'generalized_api/identity'
  require 'generalized_api/engine'
  require 'generalized_api/api'
  require 'generalized_api/controller'

  DATABASE_LIKE = (ENV['RAILS_ENV'] == 'production' ? 'ILIKE' : 'LIKE')
  DATABASE_WILDCARD = '%'

  CONFIG = {
    use_strong_parameters: false,
    restful_api: false,
    approved_generalized_api_param_classes: [String, Array, Integer, Float, TrueClass, FalseClass],
    provide_count_index_header: false
  }

  def self.config
    yield CONFIG
  end
end
