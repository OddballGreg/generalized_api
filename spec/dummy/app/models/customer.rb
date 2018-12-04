# frozen_string_literal: true

class Customer < ApplicationRecord
  validates_presence_of :name
end
