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

  attr_reader :open_delim, :close_delim

  def initialize
    @value = []
    @open_delim = '('
    @close_delim = ')'
  end

  def empty?
    @value.empty?
  end

  def [](key)
    @value[key]
  end

  def append(val)
    @value << val
  end

  def each(&block)
    @value.each(&block)
  end
end

class MalVector < MalList
  def initialize
    super
    @open_delim = '['
    @close_delim = ']'
  end
end

class MalHashMap < MalList
  def initialize
    @value = {}
    @open_delim = '{'
    @close_delim = '}'
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
      str << '\\' if ["\n", '\\', '"'].include?(ch)
      str << ch
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
