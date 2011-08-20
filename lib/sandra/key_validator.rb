module Sandra
  class KeyValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      record.errors[attribute] << "#{record.attributes[attribute.to_s]} has been taken." if record.new_record? && record.class.get(record.attributes[attribute.to_s])
    end
  end
end
