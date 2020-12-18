# frozen_string_literal: true

require 'active_support'

module AppStatusNotification
  class ConnectAPI
    module Platform
      IOS = 'IOS'
      MAC_OS = 'MAC_OS'
      TV_OS = 'TV_OS'
      WATCH_OS = 'WATCH_OS'

      ALL = [IOS, MAC_OS, TV_OS, WATCH_OS]
    end

    module ProcessStatus
      PROCESSING = 'PROCESSING'
      FAILED = 'FAILED'
      INVALID = 'INVALID'
      VALID = 'VALID'
    end

    module Model
      def self.included(base)
        Parser.types ||= []
        Parser.types << base
        base.extend(Parser)
      end

      attr_accessor :id
      attr_reader :attributes
      attr_reader :rate

      def initialize(id, attributes, rate)
        @id = id
        @attributes = attributes
        @rate = rate

        update_attributes(attributes)
      end

      def update_attributes(attributes)
        (attributes || []).each do |key, value|

          method = "#{key.to_s.underscore}=".to_sym
          self.send(method, value) if self.respond_to?(method)
        end
      end
    end

    module Parser
      class << self
        attr_accessor :types
        attr_accessor :types_cache
      end

      def self.parse(response, rate)
        body = response.body
        data = body['data']
        raise ConnectAPIError, 'No data' unless data

        included = body['included'] || []
        if data.kind_of?(Hash)
          inflate_model(data, included, rate: rate)
        elsif data.kind_of?(Array)
          return data.map do |model_data|
            inflate_model(model_data, included, rate: rate)
          end
        else
          raise ConnectAPIError, "'data' is neither a hash nor an array"
        end
      end

      def self.inflate_model(model_data, included, rate: {})
        # Find class
        type_class = find_class(model_data)
        raise "No type class found for #{model_data['type']}" unless type_class

        # Get id and attributes needed for inflating
        id = model_data['id']
        attributes = model_data['attributes']

        # Instantiate object and inflate relationships
        relationships = model_data['relationships'] || []
        type_instance = type_class.new(id, attributes, rate)

        inflate_model_relationships(type_instance, relationships, included)
      end

      def self.find_class(model_data)
        # Initialize cache
        @types_cache ||= {}

        # Find class in cache
        type_string = model_data['type']
        type_class = @types_cache[type_string]
        return type_class if type_class

        # Find class in array
        type_class = @types.find do |type|
          type.type == type_string
        end

        # Cache and return class
        type_class
      end

      def self.inflate_model_relationships(type_instance, relationships, included)
        # Relationship attributes to set
        attributes = {}

        # 1. Iterate over relationships
        # 2. Find id and type
        # 3. Find matching id and type in included
        # 4. Inflate matching data and set in attributes
        relationships.each do |key, value|
          # Validate data exists
          value_data_or_datas = value['data']
          next unless value_data_or_datas

          # Map an included data object
          map_data = lambda do |value_data|
            id = value_data['id']
            type = value_data['type']

            relationship_data = included.find do |included_data|
              id == included_data['id'] && type == included_data['type']
            end

            inflate_model(relationship_data, included) if relationship_data
          end

          # Map a hash or an array of data
          if value_data_or_datas.kind_of?(Hash)
            attributes[key] = map_data.call(value_data_or_datas)
          elsif value_data_or_datas.kind_of?(Array)
            attributes[key] = value_data_or_datas.map(&map_data)
          end
        end

        type_instance.update_attributes(attributes)
        type_instance
      end
    end
  end
end

require 'app_status_notification/connect_api/models/app'
require 'app_status_notification/connect_api/models/app_store_version'
require 'app_status_notification/connect_api/models/build'
require 'app_status_notification/connect_api/models/pre_release_version'
require 'app_status_notification/connect_api/models/app_store_version_submission'
