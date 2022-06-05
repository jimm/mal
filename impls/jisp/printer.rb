require_relative 'types'

def pr_str(val, readably = false)
  case val
  when MalString
    if readably
      val.to_readable_s
    else
      val.to_s
    end
  when MalVector
    '[' + val.map { |v| pr_str(v, readably) }.join(' ') + ']'
  when MalHashMap
    innards = val
              .map { |k, v| [pr_str(k, readably), pr_str(v, readably)] }
              .flatten.join(' ')
    innards = val.map { |k, v| [k, v] }.flatten.map { |elt| pr_str(elt, readably) }.join(' ')
    '{' + innards + '}'
  when MalList
    '(' + val.map { |v| pr_str(v, readably) }.join(' ') + ')'
  else
    val.to_s
  end
end
