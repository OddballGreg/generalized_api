# frozen_string_literal: true

class TestsController < ApplicationController
  include GeneralizedApi::Api
  def initialize
    super
    @resource_params = %i[name stuff created_at updated_at]
  end
end
