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

def quasiquote(ast)
  return ast if ast == $nil

  case ast
  when MalHashMap, MalSymbol
    MalList.new([MalSymbol.new(:quote), ast])
  when MalVector
    MalList.new([MalSymbol.new(:vec), quasiquote_list(MalList.new(ast.value))])
  when MalList
    if ast.length == 2 && ast[0].value == :unquote
      ast[1]
    else
      quasiquote_list(ast)
    end
  else
    ast
  end
end

def quasiquote_list(list)
  return list if list.empty?
  acc = MalList.new
  list.reverse_each do |elt|
    if elt.instance_of?(MalList) && elt.length == 2 && elt[0].value == :"splice-unquote"
      acc = MalList.new([MalSymbol.new(:concat), elt[1], acc])
    else
      acc = MalList.new([MalSymbol.new(:cons), quasiquote(elt), acc])
    end
  end
  acc
end

$core_ns = {
  # **************** math ****************
  :+ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:+)) },
  :- => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:-)) },
  :* => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:*)) },
  :/ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:/)) },

  # **************** typing ****************
  :"type-of" => ->(*args) { MalString.new(args[0].class.name) },

  # **************** read-time ****************
  :quasiquote => ->(*args) { quasiquote(args[0]) },

  # **************** lists ****************
  :list => ->(*args) { MalList.new(args) },
  :list? => ->(*args) { args[0].instance_of?(MalList) ? $true : $false },
  :empty? => ->(*args) { args[0].empty? ? $true : $false },
  :count => ->(*args) { MalNumber.new(args[0].length) },
  :cons => ->(*args) { MalList.new([args[0]] + args[1].value) },
  :concat => ->(*args) { MalList.new(args.map(&:value).flatten) },
  :vec => ->(*args) do
    if args.empty?
      MalVector.new
    elsif args[0].instance_of?(MalVector)
      args[0]
    else
      MalVector.new(args[0].value)
    end
  end,

  # **************** comparators ****************
  :"=" => ->(*args)  { equals(args[0],  args[1]) },
  :"<" => ->(*args)  { args[0].value <  args[1].value ? $true : $false },
  :"<=" => ->(*args) { args[0].value <= args[1].value ? $true : $false },
  :">" => ->(*args)  { args[0].value >  args[1].value ? $true : $false },
  :">=" => ->(*args) { args[0].value >= args[1].value ? $true : $false },

  # **************** string functions ****************
  :"pr-str" => ->(*args) {
    MalString.new(args.map { |arg| pr_str(arg, true) }.join(' '))
  },
  :str => ->(*args) {
    MalString.new(args.map { |arg| pr_str(arg, false) }.join(''))
  },
  :prn => ->(*args) {
    puts args.map { |arg| pr_str(arg, true) }.join(' ')
    $nil
  },
  :println => ->(*args) {
    puts args.map { |arg| pr_str(arg, false) }.join(' ')
    $nil
  },

  # **************** I/O ****************
  :"read-string" => ->(*args) {
    Reader.new.read_str(args[0].value)
  },
  :slurp => ->(*args) {
    MalString.new(IO.read(args[0].value))
  },

  # **************** atoms ****************
  :atom => ->(*args) {
    MalAtom.new(args[0])
  },
  :atom? => ->(*args) {
    args[0].instance_of?(MalAtom)
  },
  :deref => ->(*args) {
    args[0].value
  },
  :reset! => ->(*args) {
    args[0].value = args[1]
  },
  :swap! => ->(*args) {
    sexpr = MalList.new([args[1], args[0].value] + args[2..])
    repl = REPL.new
    args[0].value = repl.send(:_eval, sexpr, repl.env)
  }
}
