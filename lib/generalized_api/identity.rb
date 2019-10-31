# frozen_string_literal: true

module GeneralizedApi
  # Gem identity information.
  module Identity
    def self.name
      'generalized_api'
    end

    def self.label
      'Generalized Api'
    end

    def self.version
      '2.0.0'
    end

    def self.version_label
      "#{label} #{version}"
    end
  end
end
