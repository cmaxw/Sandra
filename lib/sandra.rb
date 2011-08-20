require 'active_model'
require 'cassandra'
require 'sandra/key_validator'

module Sandra
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(ActiveModel::Naming)
    base.class_eval do
      include ActiveModel::Validations
      include ActiveModel::Conversion
      attr_accessor :attributes, :new_record
      def initialize(attrs = {})
        @attributes = attrs.stringify_keys
        @new_record = true
      end
    end
  end

  def new_record?
    new_record
  end

  def persisted?
    false
  end

  def save
    if valid?
      attrs = attributes.dup
      key = attrs.delete(self.class.key)
      self.class.insert(key, attrs)
      new_record = false
      true
    else
      false
    end
  end

  module ClassMethods
    def column(col_name)
      define_method col_name do
        attr = col_name.to_s
        attributes[attr]
      end
      define_method "#{col_name}=" do |val|
        attr = col_name.to_s
        attributes[attr] = val
      end
    end

    def establish_connection(options = {})
      connection_options = YAML.load_file("#{::Rails.root.to_s}/config/sandra.yml")[Rails.env].merge(options)
      keyspace = connection_options["keyspace"]
      host = "#{connection_options["host"]}:#{connection_options["port"]}"
      @connection = Cassandra.new(keyspace, host)
    end

    def connection
      @connection || establish_connection
    end

    def get(key)
      hash = connection.get("User", key)
      unless hash.empty?
        obj = self.new(hash)
        obj.username = key
        obj.new_record = false
        obj
      else
        nil
      end
    end

    def insert(key, columns = {})
      connection.insert("User", key, columns)
    end

    def key_attribute(name)
      @key = name
      validates name, :presence => true, :key => true
      column name
    end

    def key
      @key
    end

    def create(columns = {})
      obj = self.new(columns)
      obj.save
      obj
    end
  end
end
