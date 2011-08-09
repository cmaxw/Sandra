module Sandra
  def included(model)
    model.extend(ClassMethods)
  end

  module ClassMethods
    def establish_connection(options = {})
      connection_options = YAML.load_file("#{RAILS_ROOT}/config/sandra.yml")[Rails.env].merge(options)
      keyspace = connection_options["keyspace"]
      host = "#{connection_options["host"]}:#{connection_options["port"]}"
      @connection = Cassandra.new(keyspace, host)
    end

    def connection
      @connection || establish_connection
    end

    def get(key)

    end

    def insert(key, columns = {})
      connection.insert("User", key, columns)
    end

    def key_attribute(key)
      @key = key
    end

    def create(columns = {})
      key = columns.delete(@key)
      insert(key, columns)
    end
  end
end
