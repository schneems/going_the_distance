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

    return m if (0 == n)
    return n if (0 == m)
    return n if (n - m).abs > max

    d = (0..m).to_a
    x = nil

    matrix = []

    str1.each_char.each_with_index do |char1,i|
      e = i+1
      matrix[i] = []
      str2.each_char.each_with_index do |char2, j|

        cost = (char1 == char2) ? 0 : 1
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

require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner  = <<HEREDOC
Outputs the levensthein distance between two words
Usage: $ ruby levensthein.rb --target far --provided foo
HEREDOC

  opts.on("-t word", "--target word", "The word you meant to write") do |target|
    options[:target] = target
  end

  opts.on("-p word", "--provided word", "The word you ACTUALLY wrote") do |provided|
    options[:provided] = provided
  end
end.parse!

raise "expected --provided flag, but was blank #{options.inspect}" unless provided = options[:provided]
raise "expected --target flag, but was blank #{options.inspect}"   unless target   = options[:target]

# $ levenshtein --target far --provided foo


target = options[:target]

class LevenDisplay

  def initialize(target, provided)
    @target   = target.upcase.each_char.map(&:to_s)
    @provided = provided.upcase.each_char.map(&:to_s)
    @artii    = Artii::Base.new font: 'big'
  end


  def matrix(matrix)
    provided = @provided.dup
    table = Terminal::Table.new do |t|
      matrix.each_with_index do |row, i|

        if matrix.size - 1 == i
          # last iteration
          last_char = matrix[i].last
          t << ([provided.shift] + matrix[i]).map {|x| @artii.asciify(x.to_s) }
          puts @artii.asciify(last_char.to_s)
        else
          t << ([provided.shift] + matrix[i]).map {|x| @artii.asciify(x.to_s) }
          t << :separator
        end
      end
    end
    # table.style    = {width: 40}
    table.title    = "Levenshtein Distance"
    table.headings = [""] + @target.map {|x| @artii.asciify(x.to_s) }
    table.align_column(0, :left)

    puts table
  end
end

display = LevenDisplay.new(target, provided)

each_step = Proc.new do |m|
  display.matrix(m)
end



puts Levenshtein.distance(target, provided, each_step: each_step)


