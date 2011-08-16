require 'active_model'
require 'cassandra'

module Sandra
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(ActiveModel::Naming)
    base.class_eval do
      include ActiveModel::Validations
      include ActiveModel::Conversion
      attr_accessor :attributes
      def initialize(attrs = {})
        @attributes = attrs
      end
    end
  end

  def persisted?
    false
  end

  module ClassMethods
    def column(col_name)
      define_method col_name do
        attributes[col_name]
      end
      define_method "#{col_name}=" do |val|
        attributes[col_name] = val
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
      obj = self.new(hash)
    end

    def insert(key, columns = {})
      connection.insert("User", key, columns)
    end

    def key_attribute(key)
      @key = key
      validates_presence_of key
      validates_uniqueness_of key
      column key
    end

    def create(columns = {})
      key = columns.delete(@key)
      insert(key, columns)
    end
  end
end
