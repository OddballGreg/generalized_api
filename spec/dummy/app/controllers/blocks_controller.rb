# frozen_string_literal: true

class BlocksController < ApplicationController
  include GeneralizedApi::Api
  def initialize
    super
    @resource_params = %i[name stuff created_at updated_at]
  end

  def index
    super { |query| change_name query }
  end

  def count
    super { |count| modify_count count }
  end

  private

  def modify_count(count)
    count + 1
  end

  def change_name(query_results)
    results = query_results.map do |result|
      result.name = 'BLOCK'
      result
    end
    results
  end
end
