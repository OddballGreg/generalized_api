# frozen_string_literal: true

class ClassApiController < GeneralizedApi::Controller
  permit_params ({ customer: %i[name stuff created_at updated_at],
                   tests: %i[name stuff created_at updated_at],
                   blocks: %i[name updated_at] })
end
