module LegendaryJsonApi
  class Config
    @key_transform = nil
    @id_transform = nil

    def self.key_transform
      @key_transform
    end

    def self.key_transform=(proc)
      @key_transform = proc
    end

    def self.transform_key(key)
      @key_transform ? @key_transform.call(key) : key
    end

    def self.id_transform
      @id_transform
    end

    def self.id_transform=(proc)
      @id_transform = proc
    end

    def self.transform_id(id)
      @id_transform ? @id_transform.call(id) : id
    end

  end
end
