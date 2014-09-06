# $ levenshtein far foo

require 'artii'
require 'terminal-table'

module Levenshtein
  def self.distance(str1, str2, options = {})
    each_step = options[:each_step]
    matrix = []
    matrix[0] = (0..str2.length).to_a

    0.upto(str1.length).each do |i|
      matrix[i] ||= []
      matrix[i][0] = i
    end


    str1.each_char.each_with_index do |char1,i|
      str2.each_char.each_with_index do |char2, j|
        if char1 == char2
          puts ["skip", matrix[i][j]].inspect
          matrix[i + 1 ][j + 1 ] = matrix[i][j]
        else
           actions = {
              deletion:     matrix[i][j +1 ] + 1,
              insert:       matrix[i + 1][j] + 1,
              substitution: matrix[i][j]     + 1
            }
            action = actions.sort {|(k,v), (k2, v2)| v <=> v2 }.first
            puts action.inspect
            matrix[i + 1 ][j + 1 ] = action.last
        end
        each_step.call(matrix) if each_step
      end
    end

    puts matrix.inspect
    return matrix[str1.length][str2.length]
  end
end



raise "Must provide two arguments" unless ARGV.size >= 2

target   = ARGV.shift
provided = ARGV.shift



require "curses"

class LevenDisplay
  include Curses

  def initialize(target, provided)
    @target   = [nil] + target.upcase.each_char.map(&:to_s)
    @provided = provided.upcase.each_char.map(&:to_s)
    @artii    = Artii::Base.new font: 'colossal'
  end

  def clear
  end

  def asciify(txt)
    @artii.asciify(txt.to_s)
  end


  def matrix(matrix)
    provided = [nil] + @provided.dup
    table = Terminal::Table.new do |t|
      matrix.each_with_index do |row, i|

        if matrix.size - 1 == i
          # last iteration
          last_char = matrix[i].last
          t << ([provided.shift] + matrix[i])
        else
          t << ([provided.shift] + matrix[i])
          t << :separator
        end
      end
    end
    table.headings = [nil] + @target
    table.align_column(0, :left)

    puts table
  end
end

display = LevenDisplay.new(target, provided)

each_step = Proc.new do |m|
  display.clear
  display.matrix(m)
  puts ""
  gets
end



cost =  Levenshtein.distance(provided, target, each_step: each_step)

puts display.asciify("Final Cost: #{cost}")


