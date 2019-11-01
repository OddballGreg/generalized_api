# frozen_string_literal: true

class MissingPaginationGemError < StandardError
end

module GeneralizedApi
  module Api
    extend ActiveSupport::Concern
    @@filters = {}
    @@_pagination_provider = nil

    if Gem.loaded_specs.key?('kaminari')
      require 'kaminari'
      @@_pagination_provider = :kaminari
    elsif Gem.loaded_specs.key?('will_paginate')
      require 'will_paginate'
      @@_pagination_provider = :will_paginate
    else
      raise MissingPaginationGemError, 'Please add either will_paginate or kaminari to your bundle.'
    end

    def index
      query = apply_pagination(apply_fuzzy_searches(resource.where(permitted_params)).order(order_params))
      # query = apply_fuzzy_searches(resource.where(permitted_params)).order(order_params).paginate(_pagination_params)
      yield query if block_given?
      query = filters(query)
      body = { resource_key.pluralize => query }
      render_processed_entity(body)
    end

    def count
      query = apply_fuzzy_searches(resource.where(permitted_params))
      yield query if block_given?
      query = filters(query)
      body = { resource_key.pluralize + '_count' => query.count }
      render_processed_entity(body)
    end

    def create
      object = resource.new(permitted_params)
      yield object if block_given?
      object = filters(object)
      render_processed_entity(resource_key => object) && return if object.save
      render_unprocessable_entity(messages: object.errors.full_messages.uniq)
    end

    def show
      operate_on_valid_object do |object|
        yield object if block_given?
        object = filters(object)
        render_processed_entity(resource_key => object)
      end
    end

    def update
      operate_on_valid_object do |object|
        yield object if block_given?
        object = filters(object)
        if object.update(permitted_params)
          render_processed_entity(resource_key => object)
          return
        else
          render_unprocessable_entity(messages: object.errors.full_messages.uniq)
        end
      end
    end

    def destroy
      operate_on_valid_object do |object|
        yield object if block_given?
        object = filters(object)
        if object.destroy
          render_processed_entity(message: "#{resource_key} With ID #{params[:id]} Succesfully Deleted")
          return
        else
          render_unprocessable_entity(messages: object.errors.full_messages.uniq)
        end
      end
    end

    included do
      def self.permit_params(param)
        @@resource_params ||= {}
        case param
        when Hash
          param.each do |key, array|
            throw "Parameter Array expected, recieved #{array.class}" if array.class != Array
            array.each do |value|
              throw "Invalid parameter type #{value.class} for model #{key.to_s.titleize}" unless [String, Symbol].include? value.class
              @@resource_params[key.to_s.singularize.to_sym] ||= []
              @@resource_params[key.to_s.singularize.to_sym] << value.to_sym
            end
          end
        when Array, Symbol, String
          [*param].each do |value|
            @@resource_params[_controlled_resource_name] ||= []
            @@resource_params[_controlled_resource_name] << value.to_sym
          end
          @@resource_params[_controlled_resource_name].uniq!
        else
          throw "Unpermittable parameter class #{param.class}"
        end
      end

      def self.infer_params_from_models(model_names)
        full_params = {}
        model_names.each do |model|
          full_params[model.to_sym] = model.camelcase.constantize.columns.map(&:name).map(&:to_sym) - [:id]
        end
        full_params
      end

      def self.apply_filter(method_name, options = {})
        @@filters[self] ||= { before: [], after: [], filter: [] }
        @@filters[self][:filter] << { method_name: method_name.to_sym, options: options }
      end

      def self._controlled_resource_name
        @_controlled_resource_name ||= to_s.tableize.split('_controllers').first.singularize.to_sym
      end
    end

    protected

    def skip_filter_due_to_except?(method)
      except_set = method.dig(:options, :except)
      except_set &&
        ((except_set.is_a?(Array) && except_set.map(&:to_sym).include?(action_name.to_sym)) ||
        except_set.try(:to_sym) == action_name.to_sym)
    end

    def apply_filter_due_to_only?(method)
      only_set = method.dig(:options, :only)
      only_set.nil? ||
        only_set.try(:to_sym) == action_name.to_sym ||
        (only_set.is_a?(Array) && only_set.map(&:to_sym).include?(action_name.to_sym))
    end

    def skip_filter_due_to_unless?(method)
      unless_set = method.dig(:options, :unless)
      unless_set.nil? || [*unless_set].all?(&:call)
    end

    def apply_filter_due_to_if?(method)
      next_set = method.dig(:options, :next)
      next_set.nil? || [*next_set].all?(&:call)
    end

    def filters(information)
      return information unless @@filters[self.class]

      @@filters[self.class][:filter].each do |method|
        next if skip_filter_due_to_except?(method)
        next unless apply_filter_due_to_only?(method)
        next unless skip_filter_due_to_unless?(method)

        information = send(method[:method_name], information) if apply_filter_due_to_if?(method)
      end
      information
    end

    def apply_fuzzy_searches(query)
      return query unless do_fuzzy_search?

      params['search'].each do |key, value|
        if _legal_resource_columns.include?(key) && value.is_a?(String)
          query = query.where(fuzzy_search_query(key), fuzzy_search_value(value))
        else
          puts "Discarding illegal fuzzy search key value set: #{key} => #{value}"
        end
      end

      query
    end

    def do_fuzzy_search?
      return false unless params['search']

      unless params['search']&.is_a?(ActionController::Parameters)
        puts 'Search parameters are not a valid set of key value pairs'
        return false
      end
      true
    end

    def fuzzy_search_query(field_name)
      "#{field_name} #{GeneralizedApi::DATABASE_LIKE} ?"
    end

    def fuzzy_search_value(value)
      wildcard = GeneralizedApi::DATABASE_WILDCARD.to_s
      wildcard + value + wildcard
    end

    def order_params
      return :id unless params['order_by']

      params['order_by'].split(',').map do |order_set|
        order_set = order_set.split(' ')
        order_set[1] ||= 'desc'
        next unless _legal_resource_columns.include?(order_set[0]) && %w[desc asc].include?(order_set[1].downcase)

        { order_set[0] => order_set[1] }
      end
    end

    def _legal_resource_columns
      @_legal_resource_columns ||= resource.columns.map(&:name)
    end

    def apply_pagination(query)
      if @@_pagination_provider == :will_paginate
        query.paginate(_pagination_params)
      elsif @@_pagination_provider == :kaminari
        query.page(_pagination_params[:page]).per(_pagination_params[:per_page])
      else
        raise MissingPaginationGemError, 'Please add either will_paginate or kaminari to your bundle.'
      end
    end

    def _pagination_params
      @_pagination_params ||= if params['page'] && params['per_page']
                                { page: params[:page], per_page: params[:per_page] }
                              else
                                { page: 1, per_page: 1000 }
                              end
    end

    def render_json(error, info_hash, status)
      render json: { error: error }.merge(info_hash), status: status
    end

    def render_unprocessable_entity(info_hash)
      render_json(true, info_hash, :unprocessable_entity)
    end

    def render_processed_entity(info_hash)
      render_json(false, info_hash, :ok)
    end

    def operate_on_valid_object
      id = params[:id]

      render_unprocessable_entity(message: "No #{resource_key} ID Provided") && return unless params.key? :id

      object = resource.find(id)

      render_unprocessable_entity(message: "Could Not Find #{resource_key} With ID #{id}") && return unless object

      yield object
    end

    def permitted_params
      logger.info "\tParams Recieved: #{params.inspect}"
      return unless params.key? resource_key

      permitted_params_model_key = params[:model]&.singularize&.to_sym || self.class._controlled_resource_name
      allowed_params = @@resource_params[permitted_params_model_key]
      permitted = params.require(resource_key).permit allowed_params

      logger.info "\tPermitted Params: #{permitted.inspect}"
      permitted
    end

    def resource
      resource_name.constantize
    end

    def resource_name
      if params[:model]
        params[:model].tableize.singularize.titleize.tr(' ', '')
      else
        self.class.to_s.split(':').last.split('Controller').first.singularize
      end
    end

    def resource_key
      resource_name.tableize.singularize
    end
  end
end
