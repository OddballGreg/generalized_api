# frozen_string_literal: true

require "will_paginate"

module GeneralizedApi
  module Api
    extend ActiveSupport::Concern
    @@filters = {}

    def index
      query = resource.where(permitted_params).order(order_params).paginate(pagination_params)
      yield query if block_given? 
      query = filters(query)
      body = {resource_key.pluralize => query}
      render_processed_entity(body)
    end

    def count
      query = resource.where(permitted_params).count
      yield query if block_given? 
      query = filters(query)
      body = {resource_key.pluralize + '_count' => query}
      render_processed_entity(body)
    end

    def show
      operate_on_valid_object do |object|
        yield object if block_given? 
        object = filters(object)
        render_processed_entity(resource_key => object)
      end
    end

    def create
      object = resource.new(permitted_params)
      yield object if block_given? 
      object = filters(object)
      render_processed_entity(resource_key => object) && return if object.save
      render_unprocessable_entity(messages: object.errors.full_messages.uniq)
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

    def update
      operate_on_valid_object do |object|
        yield object if block_given? 
        object = filters(object)
        object.update(permitted_params)
        if object.save
          render_processed_entity(resource_key => object)
          return
        else
          render_unprocessable_entity(messages: object.errors.full_messages.uniq)
        end
      end
    end

    def search
      if params["search_field"] && params["search_string"]
        query = resource.where(permitted_params).where(fuzzy_search_field, fuzzy_search_query).order(order_params).paginate(pagination_params)
        yield query if block_given? 
        query = filters(query)

        render_processed_entity(resource_key.pluralize => query)
      else
        render_unprocessable_entity(messages: "Please select a 'search_field' and a 'search_string'")
      end
    end

    included do
      def self.permit_params(param)
        @@resource_params ||= {}
        case param
        when Hash
          param.each do |key, array|
            throw "Paramter Array expected, recieved #{array.class}" if array.class != Array
            array.each do |value|
              throw "Invalid parameter type #{value.class} for model #{key.to_s.titleize}" if value.class != String && value.class != Symbol
              @@resource_params[key.to_s.singularize.to_sym] ||= []
              @@resource_params[key.to_s.singularize.to_sym] << value.to_sym
            end
          end
        when Array
          param.each do |value|
            @@resource_params[self.to_s.tableize.split('_controllers').first.singularize] ||= []
            @@resource_params[self.to_s.tableize.split('_controllers').first.singularize] << value.to_sym
          end
        when Symbol
          @@resource_params[self.to_s.tableize.split('_controllers').first.singularize] ||= []
          @@resource_params[self.to_s.tableize.split('_controllers').first.singularize] << param.to_sym
        when String
          @@resource_params[self.to_s.tableize.split('_controllers').first.singularize] ||= []
          @@resource_params[self.to_s.tableize.split('_controllers').first.singularize] << param.to_sym
        else
          throw "Unpermittable parameter class #{param.class}"
        end
      end

      def self.apply_filter(method_name, options={})
        @@filters[self] ||= {before: [], after: [], filter: []}
        @@filters[self][:filter] << { method_name: method_name.to_sym, options: options }
      end
    end

    private

    def skip_filter_due_to_except?(method)
      except_set = method.dig(:options, :except)
      except_set && ((except_set.is_a?(Array) && except_set.map(&:to_sym).include?(action_name.to_sym)) || except_set.try(:to_sym) == action_name.to_sym)
    end

    def apply_filter_due_to_only?(method)
      only_set = method.dig(:options, :only)
      only_set.nil? || only_set.try(:to_sym) == action_name.to_sym || (only_set.is_a?(Array) && only_set.map(&:to_sym).include?(action_name.to_sym))
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
        information = self.send(method[:method_name], information) if apply_filter_due_to_if?(method)
      end
      information
    end

    def fuzzy_search_field
      "#{params["search_field"]} #{GeneralizedApi::DATABASE_LIKE} ?"
    end

    def fuzzy_search_query
      wildcard = GeneralizedApi::DATABASE_WILDCARD.to_s
      wildcard + params["search_string"] + wildcard
    end

    def order_params
      return :id unless params["order_by"]
      params["order_by"].split(',').map do |order_set| 
        order_set = order_set.split(' ')
        next unless resource.columns.map(&:name).include?(order_set[0]) && %i(desc asc).include order_set[1].downcase 
        { order_set[0] => order_set[1] }
      end
    end

    def pagination_params
      if params["page"] && params["per_page"]
        {page: params[:page], per_page: params[:per_page]}
      else
        {page: 1, per_page: 1000}
      end
    end

    def render_json error, info_hash, status
      render json: {error: error}.merge(info_hash), status: status
    end

    def render_unprocessable_entity info_hash
      render_json(true, info_hash, :unprocessable_entity)
    end

    def render_processed_entity info_hash
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

      permitted = nil
      if params[:model]
        allowed_params = @resource_params[params[:model].pluralize.to_sym] || @resource_params[params[:model].singularize.to_sym]
        allowed_params = @resource_params[params[:model].pluralize.to_sym] + (@resource_params[params[:model].singularize.to_sym]) if @resource_params[params[:model].pluralize.to_sym] && @resource_params[params[:model].singularize.to_sym]
        permitted = params.require(resource_key).permit allowed_params
      else
        permitted = params.require(resource_key).permit @resource_params
      end
      
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
        self.class.to_s.split(":").last.split("Controller").first.singularize
      end
    end

    def resource_key
      resource_name.tableize.singularize
    end
  end
end
