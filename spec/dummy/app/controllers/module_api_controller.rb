# frozen_string_literal: true

class ModuleApiController < ApplicationController
  include GeneralizedApi::Api
  
  def initialize
    super
    @resource_params = {}
    @resource_params[:customer] = %i[name stuff created_at updated_at]
    @resource_params[:tests] = %i[name stuff created_at updated_at]
    @resource_params[:blocks] = %i[name updated_at]
  end
end
