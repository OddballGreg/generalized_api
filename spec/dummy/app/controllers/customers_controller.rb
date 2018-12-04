# frozen_string_literal: true

class CustomersController < GeneralizedApi::Controller
  permit_params %i[name stuff created_at updated_at]
  after_action :successful_callback
  apply_filter :a_filter
  before_action :successful_callback

  private

  def successful_callback
    "successful callback"
  end

  def a_filter(information)
    information
  end
end
