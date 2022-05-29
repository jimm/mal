require 'readline'
require_relative 'reader'
require_relative 'printer'

class REPL
  def repl
    while true
      str = Readline.readline('user> ', true)
      return if str.nil?

      begin
        val = _read(str)
        next unless val

        _print(_eval(val))
      rescue StandardError => e
        puts e
      end
    end
  end

  def _read(val)
    Reader.new.read_str(val)
  end

  def _eval(val)
    val
  end

  def _print(val)
    puts pr_str(val, readably = true)
  end
end

REPL.new.repl if __FILE__ == $PROGRAM_NAME
