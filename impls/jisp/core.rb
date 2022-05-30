require_relative 'types'
require_relative 'printer'

def equals(a, b)
  return $false unless a.instance_of?(b.class)

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
  :+ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:+)) },
  :- => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:-)) },
  :* => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:*)) },
  :/ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:/)) },
  :prn => lambda { |*args|
    puts pr_str(args[0], true)
    $nil
  },
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
  }
}
