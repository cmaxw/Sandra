module Sandra
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:define_method, :initialize) do |attrs|
      @attributes = attrs
    end
  end

  def method_missing(name, *args)
    if name.to_s =~ /=\z/
      @attributes[name.to_s] = args.first
    else
      @attributes[name.to_s] || super
    end
  end

  module ClassMethods
    def columns
      @columns ||= []
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
    end

    def create(columns = {})
      key = columns.delete(@key)
      insert(key, columns)
    end

    def column(name)
      @columns << name
    end
  end
end
