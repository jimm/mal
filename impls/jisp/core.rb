require_relative 'types'
require_relative 'printer'

def equals(a, b)
  return $false unless a.is_a?(b.class) || b.is_a?(a.class)

  case a
  when MalHashMap
    return $false unless a.length == b.length
    return $false unless a.values.keys.sort == b.values.keys.sort

    a.values.keys.all? { |key| equals(a[key], b[key]) } ? $true : $false
  when MalList
    return $false unless a.length == b.length

    (0...a.length).all? { |i| equals(a[i], b[i]) } ? $true : $false
  else
    a.value == b.value ? $true : $false
  end
end

$core_ns = {
  # **************** math ****************
  :+ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:+)) },
  :- => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:-)) },
  :* => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:*)) },
  :/ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:/)) },

  # **************** lists ****************
  :list => lambda { |*args|
    list = MalList.new
    args.each { |arg| list.append(arg) }
    list
  },
  :list? => lambda { |*args|
    args[0].instance_of?(MalList) ? $true : $false
  },
  :empty? => lambda { |*args|
    args[0].empty? ? $true : $false
  },
  :count => lambda { |*args|
    MalNumber.new(args[0].length)
  },

  # **************** comparators ****************
  :"=" => ->(*args) { equals(args[0], args[1]) },
  :"<" => lambda { |*args|
    args[0].value < args[1].value ? $true : $false
  },
  :"<=" => lambda { |*args|
    args[0].value <= args[1].value ? $true : $false
  },
  :">" => lambda { |*args|
    args[0].value > args[1].value ? $true : $false
  },
  :">=" => lambda { |*args|
    args[0].value >= args[1].value ? $true : $false
  },

  # **************** string functions ****************
  :"pr-str" => lambda { |*args|
    MalString.new(args.map { |arg| pr_str(arg, true) }.join(' '))
  },
  :str => lambda { |*args|
    MalString.new(args.map { |arg| pr_str(arg, false) }.join(''))
  },
  :prn => lambda { |*args|
    puts args.map { |arg| pr_str(arg, true) }.join(' ')
    $nil
  },
  :println => lambda { |*args|
    puts args.map { |arg| pr_str(arg, false) }.join(' ')
    $nil
  }
}
