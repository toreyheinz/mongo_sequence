require "mongo"

class MongoSequence

  class << self
    attr_writer :database

    def database
      return @database if @database
      return MongoMapper.database if defined?(MongoMapper) && MongoMapper.database
    end

    def collection
      database['sequences']
    end

    def [](name)
      new(name)
    end

    def []=(name, integer)
      self[name].current = integer
    end
  end

  attr_reader :name

  def initialize(name)
    @name = name.to_s
  end

  def collection
    MongoSequence.collection
  end

  def next
    current_after_update(:$inc => { :current => 1 })
  end

  def current
    current_after_update(:$set => {}) # noop that works
  end

  def current=(integer)
    current_after_update(:current => integer)
  end

  private

  def current_after_update(update)
    options = {
      :query  => { :_id => name },
      :new    => true, # return the modified doc
      :update => update
    }
    if sequence = collection.find_and_modify(options)
      sequence['current']
    else
      init_in_database
      current_after_update(update)
    end
  end

  def init_in_database
    collection.save({:_id => name, :current => 0}, :w => 1)
  end
end