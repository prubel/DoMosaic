#!/usr/bin/env ruby

# Turns an image into a model for glpk to solve
# Run with -h for usage instructions

#           Copyright (c) 2008  Paul Rubel
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


$LOAD_PATH.push(File.dirname(__FILE__))
require "create_data.rb"
require "domino_options.rb"
require 'optparse'
require 'ostruct'

$VERSION="1.0"

$SQUARE_SIZE = 2
$MODEL_SUFFIX = ".mod"



# TODO: 
#  - Better support for horizontal/vertical difference



#makes a model for glpsol to solve for the dominos:
# ./fill.rb 4 Chewbacca.jpg > chewy.4.mod #spits out Chewbacca.jpg.bmp
#  glpsol --intopt --tmlim 40000 -m chewy.4.mod -o chewy.4.sol  
# ./save_data.rb Chewbacca.jpg.bmp chewy.4.sol 
#               spits out Chewbacca.jpg.bmp-as_dom.png
#  convert -resize 11x10! -type Grayscale -posterize 10 \
#          vikinglander1-1.jpg vl2.bmp
# Might want to try --noscale --std which may speed up integer solutions

class Domino
  attr_accessor :high_spot, :low_spot

  def initialize(low, high)
    @low_spot = low
    @high_spot = high
  end

  def cost(a,b)
    (a-@low_spot)**2 + (b-@high_spot)**2
  end

  def to_s
    "D#{@low_spot}_#{@high_spot}"
  end
end


class Dominos
  attr_accessor :dominos

  def initialize(max, sets, options)
    @options = options
    @max = max #number of spot gradations, one more than num spots
    @sets = sets
    @dominos = []
    (0..@max).each do |i|
      (i..@max).each do |j|
        d = Domino.new(i,j)
        @dominos.push(d)
      end
    end
  end

  def each_domino
    @dominos.each do |d|
      yield(d)
    end
  end

  #This needs to change for best-fit
  def print_sets_constraint
    puts "/* Only use each domino once for each set being used */"
    each_domino do |d|
      sep = "="
      sep = '<=' if (@options.best_fit || (!@options.x.nil?))
      puts "s.t. onlySetTimes#{d.low_spot}#{d.high_spot} :" + 
        " sum{p in POSITIONS, o in ORIENTATION} x[p,'#{d}', o] #{sep} #{@sets};"
    end
  end

  def make_set
    res = "set DOMINOS    :="
    count = 0
    @dominos.each do |d|
      res += " #{d}"
      count += 1
      res += "\n                 " if ((count % 10) == 0)
    end
    res += ";"
  end

end

class Costs
  def initialize(optimal, options)
    @options = options
    options.horizontal
    @doms = Dominos.new(options.spots, 1, options) #num_spots
    @optimal = optimal
    @costs = Hash.new(10000)
    @y = @optimal[0].length
    @x = @optimal.length
    #puts "Costs constructor x is #{@x} y is #{@y}"
    calculate_costs
  end

  def make_tag(i,j,d,orient)
    "P#{i}_#{j}-#{d}-#{orient}"
  end

  def get_cost(i,j,d,orient)
    @costs[make_tag(i,j,d,orient)]
  end

  def fill (x1,y1,x2,y2,orient)
    @doms.each_domino do |d|
      #puts "\nusing #{orient} x1-#{x1} y1-#{y1} x2-#{x2} y2-#{y2} and dom #{d}"
      cost = d.cost(@optimal[x1][y1], @optimal[x2][y2])
      #puts "Cost: using #{orient} #{x1} #{y1} and dom #{d} w/ cost #{cost} "
      #puts "cost @ #{x1},#{y1} #{@optimal[x1][y1]} cost @ #{x2},#{y2} #{@optimal[x2][y2]}"
      @costs[make_tag(x1,y1,d,orient)] = cost
        end
  end

  def calculate_costs
    # up

    if (@options.vertical)
      @x.times do |x|
        (@y-1).times do |y|
          fill(x,y,x,y+1, "UP")
        end
      end
      # down
      @x.times do |x|
        (@y-1).times do |y|
          fill(x,y+1,x,y, "DOWN")
        end
      end
    end

    # left
    if (@options.horizontal) 
      @y.times do |y|
        (@x-1).times do |x|
          fill(x+1,y,x,y, "LEFT")
        end
      end
      #right
      @y.times do |y|
        (@x-1).times do |x|
          fill(x,y,x+1,y, "RIGHT")
        end
      end
    end

  end

  def print_cost_table_in_orientation(orient)
    print "   " + "[*,*,'#{orient}']: ".ljust(14)
    @doms.each_domino do |d|
      print " #{d}  "
    end
    puts " :="
    @x.times do |x|
      puts " /* For x #{x} */"
      @y.times do |y|
        print "        "
        print "P#{x}_#{y}   "
        @doms.each_domino do |d|
          print " #{get_cost(x,y,d,orient).to_s.rjust(6)}"
        end
        puts ""
      end 
    end
  end
  
  def print_cost_table
    puts "param Cost :="
    if (@options.vertical)
      print_cost_table_in_orientation("UP")
      print_cost_table_in_orientation("DOWN")
    end
    if (@options.horizontal)
      print_cost_table_in_orientation("LEFT") 
      print_cost_table_in_orientation("RIGHT")
    end
    puts ";"
  end

  
end


class Constraints

  attr_accessor :only_vertical

  def initialize(max_x, max_y, options)
    @maxx = max_x;
    @maxy = max_y;
    @options = options
  end

  def make_positions
    res = "\nset POSITIONS :="
    count = 0
    @maxx.times do |i|
      @maxy.times do |j|
        res += " P#{i}_#{j}".rjust(7)
        count += 1
        res += "\n                " if ((count % 5) == 0)
      end
    end
    res += ";\n\n"
  end  

  def make_orientations
    orintations = ""
    orientations = "#{orientations} 'DOWN' 'UP'" if (@options.vertical)
    orientations = "#{orientations} 'RIGHT' 'LEFT'" if (@options.horizontal)
    return "set ORIENTATION := #{orientations};"
  end


  def constrain(x,y)
    res = []
    header = "s.t. constraint#{x}_#{y}:sum {d in DOMINOS} (0"
    if (@options.vertical)
      res.push("   + x['P#{x}_#{y}',d,'UP']") unless (y == (@maxy - 1))
      res.push("   + x['P#{x}_#{y}',d,'DOWN']") if (y > 0)
      res.push("   + x['P#{x}_#{y-1}',d,'UP']") if (y >= 1) 
      res.push("   + x['P#{x}_#{y+1}',d,'DOWN']") if (y < (@maxy - 1))
    end
    if (@options.horizontal)
      res.push("   + x['P#{x}_#{y}',d,'LEFT']") if (x > 0)
      res.push("   + x['P#{x}_#{y}',d,'RIGHT']") if (x < (@maxx - 1))
      res.push("   + x['P#{x+1}_#{y}',d,'LEFT']") if (x < (@maxx - 1))
      res.push("   + x['P#{x-1}_#{y}',d,'RIGHT']") if (x >= 1) 
    end
    result = header + "\n" + res.sort.join("\n")
    result += ") = 1;"
  end

  def print_grid_constraint
    puts "\n\n/* Use each grid-square exactly once */"
    @maxx.times do |x|
      @maxy.times do |y|
        puts constrain(x,y)
        puts ""
      end
    end
  end

end


class Generator
  def initialize(sets, filename, out_filename, 
                 options)
    @options = options
    @sets = sets
    @filename = filename
    @out_filename = out_filename
    @spots = @options.spots
    @creator = DataCreator.new(@sets, @filename, @options)
  end

  def print_header
    puts "/* to run: glpsol --intopt --tmlim 40000 -m " + 
      "#{@out_filename}.mod \\ \n                  " + 
      "-o #{@out_filename}.sol */"
    puts "/* Options: #{@options} */"
    puts "/* Image will be #{@width}x#{@height} " + 
         "squares (a domino contains 2 squares) */"
  end

  def print_params
    puts "\n/* parameters */"
    puts "param Cost {p in POSITIONS, d in DOMINOS, o in ORIENTATION};"

    puts "\n\n"
  end


  def print_sets
    puts "\n/* sets */"
    puts "set DOMINOS;"
    puts "set ORIENTATION;"
    puts "set POSITIONS;"

  end

  def print_decision
    puts "/* decision vars, is a domino in a position */"
    puts "var x {p in POSITIONS, d in DOMINOS, o in ORIENTATION} binary;\n"
    
    puts "\nminimize layout: sum{p in POSITIONS, d in DOMINOS,"
    puts "                     o in ORIENTATION} x[p,d,o] * Cost[p,d,o];\n\n"
  end
  
  def make_data_section(c,d)
    puts "\n\n\ndata;\n\n"
    puts c.make_orientations

    puts c.make_positions

    puts ""
    puts d.make_set
    puts ""


    #$stderr.puts "Filename for creater is #{@filename}"
    optimal = @creator.makeDominoData
    costs = Costs.new(optimal, @options)
    puts ""
    costs.print_cost_table

    puts "\n\nend;"
  end

  def go
    d = Dominos.new(@spots,@sets, @options)

    @width, @height = @creator.compute_size
      

    c = Constraints.new(@width,@height, @options)
    print_header
    print_sets
    print_params
    print_decision

    d.print_sets_constraint

    c.print_grid_constraint

    make_data_section(c,d)

  end

end


class GeneratorMain

  # remove the extension
  def make_model_basename(input)
    model_filename_base = input.split('.')[0..-2].join('.')
  end

  def parseOptions(options, argv)

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options] input-file {output-file}"
      opts.separator ""
      opts.separator "Required:"
      opts.on("-s", "--sets [N]", Integer, "How many sets to use.") do |s|
        options.sets = s
      end

      opts.separator ""
      opts.separator "Optional:"

      opts.on("-M", "--mix-orientation", 
              "* Allow both horizontal and vertical ", 
              "  orientation of dominos.",
              "  This is MUCH slower and much",
              "  more memory intensive, but gives",
              "  better results. [default]") do
        options.mix(true)
      end
      opts.on("-p", "--spots [N]", Integer,
              "o How many spots on your dominos",
              "  default is 9 but you may say 6") do |s|
        #puts "looking at #{s}"
        options.spots = (s.to_int)
      end
      opts.on("-H", "--horizontal", 
              "o Only allow the horizontal orientation",
              "  of dominos.") do
        options.horiz(true)
        options.mix(false)
      end
      opts.on("-V", "--vertical", 
              "o Only allow the vertical orientation",
              "  of dominos.") do 
        options.mix(false)
        options.vert(true)
      end

      opts.on("-w", "--white-spots", 
              "* White spots on black dominos.   [default]") do |s|
        options.white_on_black = true
      end
      opts.on("-b", "--black-spots", 
              "o Black spots on white dominos.") do |s|
        options.white_on_black = false
      end

      opts.on("-x", "--setX [N]", Integer, 
              "* Set the width of the image",
              "  Likely will not use all the dominos ",
              "  When this is set --best-usage is ignored") do |s|
        options.x = s
      end


      opts.on("-U", "--best-usage", 
              "* Optimize for the number of sets", 
              "  at the expense of the image geometry.",
              "  Will use every domino in a set",
              "  even if it means 'stretching' the ",
              "  image to do so. [default]") do |s|
        options.best_fit = false
      end
      opts.on("-F", "--best-fit", 
              "o Optimize for the image geometry", 
              "  at the expense of extra dominos.",
              "  May not use every domino in a set.") do |s|
        options.best_fit = true
      end

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        exit -1
      end
    end

    begin
      opts.parse!(argv)
    rescue Exception => e
      puts e, "", opts
      exit
    end
  end


  def main(argv)

    options = DominoOptions.new
    opts = parseOptions(options, argv)


    #figure out the input and output file, all others should have been
    # taken by the opts.parse line above
    my_args = argv.flatten

    if (my_args.length != 0)
      if (my_args.length == 1)
        image_filename = my_args[0]
        model_filename_base =  make_model_basename(image_filename) + ".#{options.sets}"
        model_filename = model_filename_base + ".mod"
      elsif  (my_args.length == 2)
        image_filename = my_args[0]
        model_filename = my_args[1]
        model_filename_base = model_filename.chomp('.mod')
        model_file = model_filename_base

      else
        puts opts
        exit
      end
      #model_filename is a directory
      if ((model_filename.length - 1) == model_filename.rindex(File::SEPARATOR))
        model_filename_base = model_filename + 
          File.basename(make_model_basename(image_filename)) + 
          ".#{options.sets}"
      end

      orig_stdout = $stdout
      if (image_filename.nil?)
        puts "image is nil"
        exit -1
      end

      begin
        unless (model_filename_base =~ /\.mod$/)
          model_file = model_filename_base + ".mod" 
        end
        File.open(model_file,
                  File::CREAT | File::WRONLY | File::TRUNC) do |file|
          $stdout = file
          g = Generator.new(options.sets,image_filename, 
                            model_filename_base,
                            options)
          g.go
          orig_stdout.puts "Model generated to #{model_file}"
        end
      ensure
        $stdout = orig_stdout
      end
      exit 0 #needed so we don't test on every invocation
    end
  end

end

#######################################################################
#######################################################################
#######################################################################
######################## Main Below####################################
#######################################################################
#######################################################################
#######################################################################

m = GeneratorMain.new
m.main(ARGV)

puts "Running tests:  For usage, try #{$0} -h\n\n"

####################################################################
####################################################################
######################## TESTS  ####################################
####################################################################
####################################################################
require 'test/unit'
require 'test/unit/ui/console/testrunner'

class TestConstraints < Test::Unit::TestCase

  def setup
    @options = DominoOptions.new
    @options.mix(true)
    #empty
  end


  def test_dom_set
    d = Dominos.new(3,1, @options)
    assert_equal("set DOMINOS    := D0_0 D0_1 D0_2 D0_3 D1_1 " +
                 "D1_2 D1_3 D2_2 D2_3 D3_3\n                 ;",
                 d.make_set)
  end

  def test_positions
    c = Constraints.new(2,3,@options);
    assert_equal("\nset POSITIONS :=   P0_0   P0_1   P0_2   P1_0   P1_1\n" + 
                 "                   P1_2;\n\n",
                     c.make_positions)
  end

  def test_domino_cost
    d = Domino.new(0,0)
    assert_equal(0, d.cost(0,0))
    assert_equal(1, d.cost(0,1))
    d = Domino.new(0,2)
    assert_equal(0, d.cost(0,2))
    assert_equal(8, d.cost(2,0))
    d = Domino.new(1,2)
    assert_equal(1, d.cost(0,2))
    assert_equal(5, d.cost(2,4))

  end

  def test_costs
    optimal = [[0,0],[1,0]]
    c = Costs.new(optimal, @options)
    assert_equal(0, c.get_cost(0,0, Domino.new(0,0), "UP"))
    assert_equal(1, c.get_cost(0,0, Domino.new(0,1), "UP"))
    assert_equal(10000, c.get_cost(1,1, Domino.new(0,1), "UP"))
    assert_equal(2, c.get_cost(1,0, Domino.new(0,1), "UP"))
    assert_equal(10000, c.get_cost(1,1, Domino.new(0,1), "UP"))

    assert_equal(0, c.get_cost(1,1, Domino.new(0,1), "DOWN"))

    assert_equal(0, c.get_cost(0,1, Domino.new(0,0), "RIGHT"))
    assert_equal(1, c.get_cost(0,0, Domino.new(0,0), "RIGHT"))
    assert_equal(10000, c.get_cost(1,0, Domino.new(0,0), "RIGHT"))

    assert_equal(0, c.get_cost(1,1, Domino.new(0,0), "LEFT"))
    assert_equal(82, c.get_cost(1,1, Domino.new(1,9), "LEFT"))
    assert_equal(1, c.get_cost(1,0, Domino.new(0,0), "LEFT"))
    assert_equal(10000, c.get_cost(0,0, Domino.new(0,0), "LEFT"))

  end


  def test_constraints
    c = Constraints.new(2,2, @options);
    
    # 0-0
    cons = c.constrain(0,0);
    assert_match('s.t. constraint0_0:sum {d in DOMINOS} (0',cons)
    assert_match('x[\'P0_0\',d,\'RIGHT\']', cons)
    assert_match('x[\'P0_0\',d,\'UP\']', cons)
    assert_match('x[\'P0_1\',d,\'DOWN\']', cons)
    assert_match('x[\'P1_0\',d,\'LEFT\']) = 1;',cons)
    assert_equal(cons.count("x["), 8)

    # 0-1
    assert_equal("s.t. constraint0_1:sum {d in DOMINOS} (0\n" +
                 "   + x['P0_0',d,'UP']\n" + 
                 "   + x['P0_1',d,'DOWN']\n" + 
                 "   + x['P0_1',d,'RIGHT']\n" + 
                 "   + x['P1_1',d,'LEFT']) = 1;",
                 c.constrain(0,1))

    # 1-0
    cons = c.constrain(1,0)
    assert_match("s.t. constraint1_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P1_0',d,'LEFT']", cons) 
    assert_match("x['P1_0',d,'UP']", cons) 
    assert_match("x['P1_1',d,'DOWN']", cons) 
    assert_match("x['P0_0',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 8)

    # 1-1
    cons = c.constrain(1,1)
    assert_match("s.t. constraint1_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P1_1',d,'DOWN']", cons) 
    assert_match("x['P1_1',d,'LEFT']", cons) 
    assert_match("x['P1_0',d,'UP']", cons) 
    assert_match("x['P0_1',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 8)

    options = DominoOptions.new
    options.vert(true)
    c = Constraints.new(2,2,options);
    # 0-0
    cons = c.constrain(0,0)
    assert_match("s.t. constraint0_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P0_0',d,'UP']", cons)
    assert_match("x['P0_1',d,'DOWN']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 4)
                 

    # 0-1
    cons = c.constrain(0,1)
    assert_match("s.t. constraint0_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P0_1',d,'DOWN']", cons) 
    assert_match("x['P0_0',d,'UP']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 4)


    # 1-0
    cons = c.constrain(1,0)
    assert_match("s.t. constraint1_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P1_0',d,'UP']", cons) 
    assert_match("x['P1_1',d,'DOWN']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 4)



    # 1-1
    cons = c.constrain(1,1)
    assert_match("s.t. constraint1_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P1_1',d,'DOWN']", cons)
    assert_match("x['P1_0',d,'UP']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 4)


    c = Constraints.new(4,3,@options);

    # 0-0
    cons = c.constrain(0,0)
    assert_match("s.t. constraint0_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P0_0',d,'RIGHT']", cons)
    assert_match("x['P0_0',d,'UP']", cons)
    assert_match("x['P0_1',d,'DOWN']", cons)
    assert_match("x['P1_0',d,'LEFT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 8)


    # 0-1
    cons = c.constrain(0,1)
    assert_match("s.t. constraint0_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P0_0',d,'UP']", cons) 
    assert_match("x['P0_1',d,'DOWN']", cons) 
    assert_match("x['P0_1',d,'RIGHT']", cons) 
    assert_match("x['P0_1',d,'UP']", cons) 
    assert_match("x['P0_2',d,'DOWN']", cons) 
    assert_match("x['P1_1',d,'LEFT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 12)


    # 0-2
    cons = c.constrain(0,2)
    assert_match("s.t. constraint0_2:sum {d in DOMINOS} (0", cons)
    assert_match("x['P0_2',d,'DOWN']", cons) 
    assert_match("x['P0_1',d,'UP']", cons) 
    assert_match("x['P0_2',d,'RIGHT']", cons) 
    assert_match("x['P1_2',d,'LEFT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 8)


    # 1-0
    cons = c.constrain(1,0)
    assert_match("s.t. constraint1_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P0_0',d,'RIGHT']", cons)
    assert_match("x['P1_0',d,'LEFT']", cons)
    assert_match("x['P1_0',d,'RIGHT']", cons)
    assert_match("x['P1_0',d,'UP']", cons)
    assert_match("x['P1_1',d,'DOWN']", cons)
    assert_match("x['P2_0',d,'LEFT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 12)


    # 1-1
    cons = c.constrain(1,1)
    assert_match("s.t. constraint1_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P1_1',d,'UP']", cons) 
    assert_match("x['P1_1',d,'DOWN']", cons) 
    assert_match("x['P1_1',d,'LEFT']", cons) 
    assert_match("x['P1_1',d,'RIGHT']", cons) 
    assert_match("x['P1_0',d,'UP']", cons) 
    assert_match("x['P1_2',d,'DOWN']", cons) 
    assert_match("x['P2_1',d,'LEFT']", cons) 
    assert_match("x['P0_1',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 16)


    # 1-2
    cons = c.constrain(1,2)
    assert_match("s.t. constraint1_2:sum {d in DOMINOS} (0", cons)
    assert_match("x['P1_2',d,'DOWN']", cons) 
    assert_match("x['P1_2',d,'LEFT']", cons) 
    assert_match("x['P1_2',d,'RIGHT']", cons) 
    assert_match("x['P1_1',d,'UP']", cons) 
    assert_match("x['P2_2',d,'LEFT']", cons) 
    assert_match("x['P0_2',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 12)


    # 2-0
    cons = c.constrain(2,0)
    assert_match("s.t. constraint2_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P2_0',d,'UP']", cons)
    assert_match("x['P2_0',d,'LEFT']", cons)
    assert_match("x['P2_0',d,'RIGHT']", cons)
    assert_match("x['P2_1',d,'DOWN']", cons)
    assert_match("x['P3_0',d,'LEFT']", cons)
    assert_match("x['P1_0',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 12)


    # 2-1
    cons = c.constrain(2,1)
    assert_match("s.t. constraint2_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P2_1',d,'UP']", cons) 
    assert_match("x['P2_1',d,'DOWN']", cons) 
    assert_match("x['P2_1',d,'LEFT']", cons) 
    assert_match("x['P2_1',d,'RIGHT']", cons) 
    assert_match("x['P2_0',d,'UP']", cons) 
    assert_match("x['P2_2',d,'DOWN']", cons) 
    assert_match("x['P3_1',d,'LEFT']", cons) 
    assert_match("x['P1_1',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 16)


    # 2-2
    cons = c.constrain(2,2)
    assert_match("s.t. constraint2_2:sum {d in DOMINOS} (0", cons)
    assert_match("x['P2_2',d,'DOWN']", cons) 
    assert_match("x['P2_2',d,'LEFT']", cons) 
    assert_match("x['P2_2',d,'RIGHT']", cons) 
    assert_match("x['P2_1',d,'UP']", cons) 
    assert_match("x['P3_2',d,'LEFT']", cons) 
    assert_match("x['P1_2',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 12)


    # 3-0
    cons = c.constrain(3,0)
    assert_match("s.t. constraint3_0:sum {d in DOMINOS} (0", cons)
    assert_match("x['P3_0',d,'UP']", cons)
    assert_match("x['P3_0',d,'LEFT']", cons)
    assert_match("x['P3_1',d,'DOWN']", cons)
    assert_match("x['P2_0',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 8)


    # 3-1
    cons = c.constrain(3,1)
    assert_match("s.t. constraint3_1:sum {d in DOMINOS} (0", cons)
    assert_match("x['P3_1',d,'UP']", cons) 
    assert_match("x['P3_1',d,'DOWN']", cons) 
    assert_match("x['P3_1',d,'LEFT']", cons) 
    assert_match("x['P3_0',d,'UP']", cons) 
    assert_match("x['P3_2',d,'DOWN']", cons) 
    assert_match("x['P2_1',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 12)


    # 3-2
    cons = c.constrain(3,2)
    assert_match("s.t. constraint3_2:sum {d in DOMINOS} (0", cons)
    assert_match("x['P3_2',d,'DOWN']", cons) 
    assert_match("x['P3_2',d,'LEFT']", cons) 
    assert_match("x['P3_1',d,'UP']", cons) 
    assert_match("x['P2_2',d,'RIGHT']", cons)
    assert_match(/\) = 1;$/, cons)
    assert_equal(cons.count("x["), 8)

  end

  def test_creater
    voptions = DominoOptions.new
    voptions.vert(true)

    hoptions = DominoOptions.new
    hoptions.horiz(true)
    sets = 100

    rh = []
    rv = []
    10.times do 
      rh.push(rand(1000)+1)
      rv.push(rand(1000)+1)
    end

    rh.each do |h|
      v = rv.pop
      vdc = DataCreator.new(sets, "empty-file-name", voptions)
      vdc.t_set_size(h,v)

      hdc = DataCreator.new(sets, "empty-file-name", hoptions)
      hdc.t_set_size(h,v)
    
      a,b = vdc.best_fit(sets*110, true)
      c,d = vdc.dom_fit(sets*110, true)
      assert_equal(0, b%2, "Problems with h:#{h}, v:#{v}")
      assert_equal(0, d%2, "Problems with h:#{h}, v:#{v}")
      

      a,b = hdc.best_fit(sets*110, true)
      c,d = hdc.dom_fit(sets*110, true)
      assert_equal(0, a%2, "Problems with h:#{h}, v:#{v}")
      assert_equal(0, c%2, "Problems with h:#{h}, v:#{v}")
    end
  end

end
