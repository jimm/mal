require_relative 'types'

def pr_str(val, readably = false)
  case val
  when MalString
    if readably
      val.to_readable_s
    else
      val.to_s
    end
  when MalHashMap
    val.open_delim +
      val.map do |k, v|
        [pr_str(k, readably = readably), pr_str(v, readably = readably)]
      end
         .flatten.join(' ') +
      val.close_delim
  when MalList, MalVector
    val.open_delim + val.map { |v| pr_str(v, readably = readably) }.join(' ') + val.close_delim
  else
    val.to_s
  end
end
