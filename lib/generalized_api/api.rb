# frozen_string_literal: true

require "will_paginate"

module GeneralizedApi
  module Api
    extend ActiveSupport::Concern
    @@filters = {}

    # def index
    #   query = resource.where(permitted_params).order(order_param).paginate(pagination_params)

    #   query = yield query if block_given? 

    #   body = {resource_key.pluralize => query}

    #   render_processed_entity(body)
    # end

    # def count
    #   query = resource.where(permitted_params).count
  
    #   query = yield query if block_given? 

    #   body = {resource_key.pluralize + '_count' => query}

    #   render_processed_entity(body)
    # end

    # def show
    #   operate_on_valid_object do |object|
    #     object = yield object if block_given? 
    #     render_processed_entity(resource_key => object)
    #   end
    # end

    # def create
    #   object = resource.new(permitted_params)
    #   object = yield object if block_given? 
    #   render_processed_entity(resource_key => object) && return if object.save
    #   render_unprocessable_entity(messages: object.errors.full_messages.uniq)
    # end

    # def destroy
    #   operate_on_valid_object do |object|
    #     if object.destroy
    #       object = yield object if block_given? 
    #       render_processed_entity(message: "#{resource_key} With ID #{params[:id]} Succesfully Deleted")
    #       return
    #     else
    #       render_unprocessable_entity(messages: object.errors.full_messages.uniq)
    #     end
    #   end
    # end

    # def update
    #   operate_on_valid_object do |object|
    #     object.update(permitted_params)
    #     if object.save
    #       object = yield object if block_given? 
    #       render_processed_entity(resource_key => object)
    #       return
    #     else
    #       render_unprocessable_entity(messages: object.errors.full_messages.uniq)
    #     end
    #   end
    # end

    # def search
    #   if params["search_field"] && params["search_string"]
    #     query = resource.where(permitted_params).where(fuzzy_search_field, fuzzy_search_query).order(order_param).paginate(pagination_params)
    #     query = yield query if block_given? 

    #     render_processed_entity(resource_key.pluralize => query)
    #   else
    #     render_unprocessable_entity(messages: "Please select a 'search_field' and a 'search_string'")
    #   end
    # end

    def index
      query = resource.where(permitted_params).order(order_param).paginate(pagination_params)
      query = yield query if block_given? 
      query = filters(query)
      body = {resource_key.pluralize => query}
      render_processed_entity(body)
    end

    def count
      query = resource.where(permitted_params).count
      query = yield query if block_given? 
      query = filters(query)
      body = {resource_key.pluralize + '_count' => query}
      render_processed_entity(body)
    end

    def show
      operate_on_valid_object do |object|
        object = yield object if block_given? 
        object = filters(object)
        render_processed_entity(resource_key => object)
      end
    end

    def create
      object = resource.new(permitted_params)
      object = yield object if block_given? 
      object = filters(object)
      render_processed_entity(resource_key => object) && return if object.save
      render_unprocessable_entity(messages: object.errors.full_messages.uniq)
    end

    def destroy
      operate_on_valid_object do |object|
        if object.destroy
          object = yield object if block_given? 
          object = filters(object)
          render_processed_entity(message: "#{resource_key} With ID #{params[:id]} Succesfully Deleted")
          return
        else
          render_unprocessable_entity(messages: object.errors.full_messages.uniq)
        end
      end
    end

    def update
      operate_on_valid_object do |object|
        object.update(permitted_params)
        if object.save
          object = yield object if block_given? 
          object = filters(object)
          render_processed_entity(resource_key => object)
          return
        else
          render_unprocessable_entity(messages: object.errors.full_messages.uniq)
        end
      end
    end

    def search
      if params["search_field"] && params["search_string"]
        query = resource.where(permitted_params).where(fuzzy_search_field, fuzzy_search_query).order(order_param).paginate(pagination_params)
        query = yield query if block_given? 
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
      method.dig(:options, :except) && ((method.dig(:options, :except).is_a?(Array) && method.dig(:options, :except).include?(params[:action])) || method.dig(:options, :except) == params[:action])
    end

    def apply_filter_due_to_only?(method)
      method.dig(:options, :only).nil? || method.dig(:options, :only) == params[:action] || (method.dig(:options, :only).is_a?(Array) && method.dig(:options, :only).include?(params[:action]))
    end

    def skip_filter_due_to_unless?(method)
      method.dig(:options, :unless).nil? || [*method.dig(:options, :unless)].all?(&:call)
    end

    def apply_filter_due_to_if?(method)
      method.dig(:options, :next).nil? || [*method.dig(:options, :next)].all?(&:call)
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

    def order_param
      params["order_by"] || :id
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
