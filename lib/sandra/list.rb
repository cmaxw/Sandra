module Sandra
  class List
    def initialize(name, type, owner)
      @column_family = name.to_s.camelize
      @type = type.to_s.constantize
      @owner = owner

      keys = @type.connection.get(@column_family, @owner.key).keys
      @elements = @type.multi_get(keys)
    end

    def <<(obj)
      if obj.is_a?(@type)
        @elements << obj
        @type.connection.insert(@column_family, @owner.key, {obj.key => Time.now.to_s})
      end
    end
  end
end
