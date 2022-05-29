require 'readline'
require_relative 'reader'
require_relative 'printer'
require_relative 'env'

class REPL
  def initialize
    @env = Env.new(nil)
    {
      :+ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:+)) },
      :- => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:-)) },
      :* => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:*)) },
      :/ => ->(*args) { MalNumber.new(args.map(&:value).reduce(&:/)) }
    }.each do |k, v|
      @env.set(k, v)
    end
  end

  def repl
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
    return _eval_ast(val, env) unless val.instance_of?(MalList)
    return val if val.empty?

    first_val = val[0]
    if first_val.instance_of?(MalSymbol)
      case first_val.value
      when :"def!"
        return env.set(val[1], _eval(val[2], env))
      when :"let*"
        let_env = Env.new(env)
        val[1].each_slice(2) do |var, val|
          let_env.set(var, _eval(val, let_env))
        end
        return _eval(val[2], let_env)
      end
    end

    evalled = _eval_ast(val, env)
    evalled[0].call(*evalled.value[1..])
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
      new_list = ast.class.new
      ast.each { |val| new_list.append(_eval(val, env)) }
      new_list
    else
      ast
    end
  end
end

REPL.new.repl if __FILE__ == $PROGRAM_NAME
