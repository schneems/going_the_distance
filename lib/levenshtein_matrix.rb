# $ levenshtein far foo

require 'artii'
require 'terminal-table'

module Levenshtein
  def self.distance(str1, str2, options = {})
    each_step = options[:each_step]
    s = str1
    t = str2
    n = s.length
    m = t.length
    max = n/2

    d = (0..m).to_a
    x = nil

    matrix = []

    str1.each_char.each_with_index do |char1,i|
      e = i+1
      matrix[i] = []
      str2.each_char.each_with_index do |char2, j|

        cost = (char1 == char2) ? 0 : 1
        puts "cost: #{cost}"
        puts "j: #{j}"
        puts "i: #{i}"
        puts "d.inspect: #{d.inspect}"
        puts "d[j+1] + 1: #{d[j+1] + 1}"
        puts "e + 1: #{e + 1}"
        puts "d[j] + cost: #{d[j] + cost}"
        x = [
             d[j+1] + 1, # insertion
             e + 1,      # deletion
             d[j] + cost # substitution
            ].min
        d[j] = e
        e = x
        matrix[i][j] = x
        each_step.call(matrix) if each_step
      end

      d[m] = x
    end

    return x
  end
end

raise "Must provide two arguments" unless ARGV.size >= 2

target   = ARGV.shift
provided = ARGV.shift


class LevenDisplay

  def initialize(target, provided)
    @target   = target.upcase.each_char.map(&:to_s)
    @provided = provided.upcase.each_char.map(&:to_s)
    @artii    = Artii::Base.new font: 'colossal'
  end

  def clear
    puts "CLEARING ==========================="
  end

  def asciify(txt)
    @artii.asciify(txt.to_s)
  end


  def matrix(matrix)
    provided = @provided.dup
    table = Terminal::Table.new do |t|
      matrix.each_with_index do |row, i|

        if matrix.size - 1 == i
          # last iteration
          last_char = matrix[i].last
          t << ([provided.shift] + matrix[i])#.map {|x| asciify(x) }
        else
          t << ([provided.shift] + matrix[i])#.map {|x| asciify(x) }
          t << :separator
        end
      end
    end
    # table.style    = {width: 40}
    table.headings = [""] + @target#.map {|x| asciify(x) }
    table.align_column(0, :left)

    puts table
  end
end

display = LevenDisplay.new(target, provided)

each_step = Proc.new do |m|
  display.clear
  display.matrix(m)
  puts ""
  puts display.asciify("Cost: ") + display.asciify(m.last.last)
  gets
end



cost =  Levenshtein.distance(provided, target, each_step: each_step)

puts display.asciify("Final Cost: #{cost}")


