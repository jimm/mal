require_relative 'types'

class Env
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
    key = key.value if key.is_a?(MalType)
    @data[key] = val
  end

  def get(key)
    env = find(key)
    raise "#{key} not found" unless env

    env[key.value]
  end

  def has_key?(key)
    !find(key).nil?
  end

  def find(key)
    lookup = key.is_a?(MalType) ? key.value : key
    return @data if @data.has_key?(lookup)
    return nil unless @outer_env

    @outer_env.find(key)
  end
end
