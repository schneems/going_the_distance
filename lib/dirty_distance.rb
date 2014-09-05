require 'artii'
require 'terminal-table'

raise "Must provide two arguments" unless ARGV.size >= 2

target   = ARGV.shift
provided = ARGV.shift

@artii   = Artii::Base.new font: 'colossal'


def distance(str1, str2)
  cost = 0
  str1.each_char.with_index do |char, index|
    cost += 1 if str2[index] != char
    puts @artii.asciify "Compare '#{char}' to '#{str2[index]}'"
    puts @artii.asciify("Total: #{cost}")
    gets
  end
  cost
end


distance(target, provided)
