# frozen_string_literal: true

module GeneralizedApi
  # Generator for installing new files.
  class InstallGenerator < Rails::Generators::Base
    source_root File.join(File.dirname(__FILE__), "..", "templates")

    desc "Installs additional Generalized Api resources."
    def install
    end
  end
end
