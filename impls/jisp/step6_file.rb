require 'readline'
require_relative 'reader'
require_relative 'printer'
require_relative 'env'
require_relative 'core'

class REPL
  PREDEFINED_LISP_FUNCTIONS = [
    "(def! not (fn* (a) (if a false true)))",
    "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \"\nnil)\")))))"
  ]

  attr_reader :env

  def initialize(env = nil)
    @env = Env.new(nil)

    argv = MalList.new()
    @env.set(:"*ARGV*", argv)
    (ARGV[1..] || []).each { |arg| argv.append(MalString.new(arg)) }

    $core_ns.each { |sym, func| @env.set(sym, func) }
    PREDEFINED_LISP_FUNCTIONS.each do |func_str|
      _eval(_read(func_str), @env)
    end
    @env.set(:eval, lambda { |*args| _eval(args[0], @env) })
  end

  def repl
    fname = ARGV[0]
    if fname
      _eval(_read("(load-file \"#{fname}\")"), @env)
      exit(0)
    end
    while true
      str = Readline.readline('user> ', true)
      return if str.nil?

      begin
        val = _read(str)
        next unless val

        _print(_eval(val, @env))
      rescue StandardError => e
        puts e
      end
    end
  end

  private

  def _read(val)
    Reader.new.read_str(val)
  end

  def _eval(val, env)
    while true
      return _eval_ast(val, env) unless val.instance_of?(MalList)
      return val if val.empty?

      first_val = val[0]
      if first_val.instance_of?(MalSymbol)
        case first_val.value
        when :"def!"
          val = env.set(val[1], _eval(val[2], env))
          next
        when :"let*"
          let_env = Env.new(env)
          val[1].each_slice(2) do |var, val|
            let_env.set(var, _eval(val, let_env))
          end
          val = val[2]
          env = let_env
          next
        when :do
          cdr = val.cdr
          cdr.value[..-2].map { |val| _eval(val, env) }
          val = cdr.value[-1]
          next
        when :if
          condition = _eval(val[1], env)
          which = (condition == $nil || condition == $false) ? 3 : 2
          return $nil if which == 3 && val.length < 4
          val = val[which]
          next
        when :"fn*"
          return MalFunction.new(env, val[1], val.cdr.cdr.car)
        end
      end

      evalled = _eval_ast(val, env)
      func = evalled[0]
      args = evalled[1..]
      if func.instance_of?(MalFunction)
        env = func.bind(*args)
        val = func.body
      else
        return func.call(*args)
      end
    end
  end

  def _print(val)
    puts pr_str(val, readably = true)
  end

  def _eval_ast(ast, env)
    case ast
    when MalSymbol
      env.get(ast)
    when MalHashMap
      new_map = MalHashMap.new
      ast.each do |k, v|
        new_map[k] = _eval(v, env)
      end
      new_map
    when MalList, MalVector
      ast.class.new(ast.map { |val| _eval(val, env) })
    else
      ast
    end
  end
end

REPL.new.repl if __FILE__ == $PROGRAM_NAME
