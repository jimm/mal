require 'readline'

class REPL
  def repl
    while true
      str = Readline.readline('user> ', true)
      return if str.nil?

      _print(_eval(_read(str)))
    end
  end

  def _read(val)
    val
  end

  def _eval(val)
    val
  end

  def _print(val)
    puts val
  end
end

REPL.new.repl if __FILE__ == $PROGRAM_NAME
