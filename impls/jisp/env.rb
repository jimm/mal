require 'set'
require_relative 'types'

class Env
  attr_reader :data, :outer_env

  def initialize(outer_env, bindings = [], exprs = [])
    @outer_env = outer_env
    @data = {}
    bindings.each_with_index do |sym, i|
      if sym.value == :&
        rest = MalList.new(exprs[i..])
        set(bindings[i+1], rest)
        break
      end
      set(sym, exprs[i])
    end
  end

  def set(key, val)
    @data[lookup(key)] = val
  end

  def get(key)
    env = find(key)
    raise "#{key} not found" unless env

    env[lookup(key)]
  end

  def has_key?(key)
    !find(key).nil?
  end

  def find(key)
    seen = Set.new
    curr = self

    while true
      return nil if seen.include?(curr)
      seen.add(curr)

      data = curr.data
      return data if data.has_key?(lookup(key))
      curr = curr.outer_env
      return nil unless curr
    end
  end

  def lookup(key)
    key.is_a?(MalType) ? key.value : key
  end

  def to_s
    "#<Environment #{self.object_id} @outer_env=#{@outer_env}>"
  end
end
