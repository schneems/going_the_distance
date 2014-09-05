# ```
# def ld(s, t):
#   if not s: return len(t)
#   if not t: return len(s)
#   if s[0] == t[0]: return ld(s[1:], t[1:])
#   l1 = ld(s, t[1:])
#   l2 = ld(s[1:], t)
#   l3 = ld(s[1:], t[1:])
#   return 1 + min(l1, l2, l3)
# ```

require 'artii'
require 'terminal-table'

raise "Must provide two arguments" unless ARGV.size >= 2

target   = ARGV.shift
provided = ARGV.shift

@artii   = Artii::Base.new font: 'colossal'


@count = 0
def distance(str1, str2)
  return str2.length if str1.empty?
  return str1.length if str2.empty?

  @count += 1
  puts "Comparing '#{str1}' '#{str2}'"
  sleep 0.01
  return distance(str1[1..-1], str2[1..-1]) if str1[0] == str2[0]
  l1 = distance(str1, str2[1..-1])
  l2 = distance(str1[1..-1], str2)
  l3 = distance(str1[1..-1], str2[1..-1])
  return 1 + [l1,l2,l3].min
end

result = distance(target, provided)

puts "Took #{@count} comparisons"
puts "Distance: #{result}"