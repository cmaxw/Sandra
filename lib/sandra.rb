require 'active_model'
require 'cassandra'
require File.dirname(__FILE__) + '/sandra/key_validator'
require File.dirname(__FILE__) + '/sandra/list'

module Sandra
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(ActiveModel::Naming)
    base.extend(ActiveModel::Callbacks)
    base.class_eval do
      include ActiveModel::Validations
      include ActiveModel::Conversion
      include ActiveModel::SecurePassword
      define_model_callbacks :create, :update, :save, :destroy
      attr_accessor :attributes, :new_record

      def initialize(attrs = {})
        @attributes = attrs.stringify_keys
        @unregistered_attrs = @attributes - self.class.registered_columns.map(&to_s)
        @unregistered_attrs.each do |attr|
          self.send("#{attr}=", @attributes[attr])
        end
        @new_record = true
      end

    end
  end

  def key
    attributes[self.class.key.to_s]
  end

  def new_record?
    new_record
  end

  def persisted?
    false
  end

  def save
    callback_target = self.new_record? ? :create : :update
    run_callbacks callback_target do
      run_callbacks :save do
        attrs = attributes.dup
        key = attrs.delete(self.class.key)
        if key && valid?
          self.class.insert(key, attrs)
          new_record = false
          true
        else
          false
        end
      end
    end
  end

  module ClassMethods
    def column(col_name, type)
      define_method col_name do
        attr = col_name.to_s
        attributes[attr]
      end
      define_method "#{col_name}=" do |val|
        attr = col_name.to_s
        attributes[attr] = val
      end
      @registered_columns ||= []
      @registered_columns << col_name
    end

    def registered_columns
      @registered_columns + Array(@key)
    end

    def establish_connection(options = {})
      connection_options = YAML.load_file("#{::Rails.root.to_s}/config/sandra.yml")[::Rails.env].merge(options)
      keyspace = connection_options["keyspace"]
      host = "#{connection_options["host"]}:#{connection_options["port"]}"
      @connection = Cassandra.new(keyspace, host)
    end

    def connection
      @connection || establish_connection
    end

    def get(key)
      hash = connection.get(self.to_s, key)
      unless hash.empty?
        self.new_object(key, hash)
      else
        nil
      end
    end

    def new_object(key, attributes)
      obj = self.new(attributes)
      obj.send("#{@key}=", key)
      obj.new_record = false
      obj
    end

    def insert(key, columns = {})
      connection.insert(self.to_s, key, columns)
    end

    def key_attribute(name, type)
      @key = name
      validates name, :presence => true, :key => true
      column name, type
    end

    def key
      @key
    end

    def create(columns = {})
      obj = self.new(columns)
      obj.save
      obj
    end

    def range(options)
      connection.get_range(self.to_s, options).map do |key, value|
        self.new_object(key, value)
      end
    end

    def list(name, type)
      define_method name do
        var_name = "@__#{name}_list"
        unless instance_variable_get(var_name)
          instance_variable_set(var_name, Sandra::List.new(name, type, self))
        end
        instance_variable_get(var_name)
      end
    end

    def multi_get(keys)
      collection = connection.multi_get(self.to_s, keys)
      collection.map {|key, attrs| self.new_object(key, attrs) }
    end
  end
end
