require_relative 'types'

TOKEN_REGEX = /[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)/
QUOTE_MACROS = {
  "'" => 'quote',
  '`' => 'quasiquote',
  '~' => 'unquote',
  '~@' => 'splice-unquote',
  '@' => 'deref'
}
CLOSING_DELIMS = {
  '(' => ')',
  '[' => ']',
  '{' => '}'
}

class Reader
  def read_str(str)
    @tokens = tokenize(str)
    read_form
  end

  private

  def next
    @tokens.shift
  end

  def peek
    @tokens[0]
  end

  def tokenize(str)
    tokens = []
    while !str.empty? && str =~ TOKEN_REGEX
      token = Regexp.last_match(1)
      break if token.strip.empty?
      tokens << token unless token[0] == ';' # skip comments

      str = str.sub(/\A[\s,]+/, '')[token.length..]
    end
    tokens
  end

  def read_form
    case peek
    when '(', '[', '{'
      opening_delim = self.next
      read_list(opening_delim, CLOSING_DELIMS[opening_delim])
    when "'", '`', '~', '~@', '@'
      reader_macro(QUOTE_MACROS[self.next])
    when '@'
      MalList.new([MalSymbol.new('deref'), read_atom])
    else
      read_atom
    end
  end

  def reader_macro(func_name)
    MalList.new([MalSymbol.new(func_name), read_form])
  end

  def read_list(opening_delim, closing_delim)
    list = case opening_delim
           when '('
             MalList.new
           when '['
             MalVector.new
           when '{'
             MalHashMap.new
           end
    while peek != closing_delim
      # raise "unbalanced '#{opening_delim}'" if peek.nil?
      list.append(read_form)
    end
    self.next                   # eat closing delim
    list
  end

  def read_atom
    token = self.next
    case token
    when 'nil'
      $nil
    when 'true'
      $true
    when 'false'
      $false
    when /\A-?[0-9]+\z/
      MalNumber.new(token.to_i)
    when /\A-?[0-9]+(\.[0-9]*)?\z/
      MalNumber.new(token.to_f)
    when /\A:/
      MalKeyword.new(token[1..])
    when /\A"/
      parse_string_token(token)
    when nil
      $nil
    else
      MalSymbol.new(token)
    end
  end

  def parse_string_token(token)
    str = ''
    escaping = false
    seen_double_quote = false
    token[1..].each_char do |ch|
      raise "unbalanced double quote" if seen_double_quote
      if escaping
        str << (ch == 'n' ? "\n" : ch)
        escaping = false
      elsif ch == '\\'
        escaping = true
      else
        seen_double_quote = true if ch == '"'
        str << ch
      end
    end
    raise "unbalanced double quote" if escaping || !seen_double_quote
    MalString.new(str[..-2])
  end
end
