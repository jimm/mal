require_relative 'printer'

class MalType
  attr_reader :value

  def initialize(value = nil)
    @value = value
  end

  def to_s
    @value.to_s
  end
end

class MalNil < MalType
  def to_s
    'nil'
  end

  def length
    0
  end
end
$nil = MalNil.new

class MalTrue < MalType
  def initialize(_ = true)
    super(true)
  end
end
$true = MalTrue.new

class MalFalse < MalType
  def initialize(_ = false)
    super(false)
  end
end
$false = MalFalse.new

class MalList < MalType
  include Enumerable

  def initialize(value = [])
    @value = value
  end

  def empty?
    length == 0
  end

  def length
    @value.length
  end

  def [](key)
    @value[key]
  end

  def car
    @value[0]
  end

  def cdr
    MalList.new(@value[1..] || $nil)
  end

  def append(val)
    @value << val
  end

  def each(&block)
    @value.each(&block)
  end
end

class MalVector < MalList
end

class MalHashMap < MalList
  def initialize(value = {})
    @value = value
    @next_entry = :key
    @key = nil
  end

  def [](key)
    @value[key]
  end

  def []=(key, val)
    @value[key] = val
  end

  # parsing only
  def append(val)
    if @next_entry == :key
      @key = val
      @next_entry = :value
    else
      @value[@key] = val
      @next_entry = :key
    end
  end
end

class MalNumber < MalType
end

class MalString < MalType
  def to_readable_s
    str = ''
    @value.each_char do |ch|
      case ch
      when "\n"
        str << "\\n"
      when '\\', '"'
        str << "\\#{ch}"
      else
        str << ch
      end
    end
    '"' + str + '"'
  end
end

class MalSymbol < MalType
  def initialize(sym_name)
    @value = sym_name.to_sym
  end
end

class MalKeyword < MalType
  def initialize(sym_name)
    @value = sym_name.to_sym
  end

  def to_s
    ":#{@value}"
  end
end

class MalFunction < MalType
  attr_reader :body

  def initialize(env, arglist, body)
    super('#<function>')
    @env = env
    @arglist = arglist
    @body = body
  end

  def bind(*args)
    Env.new(@env, @arglist, args)
  end
end

class MalAtom < MalType
  attr_accessor :value

  def to_s
    "(atom #{value})"
  end
end
