#!/usr/bin/env ruby

# Generate a postscript file from an input glpk solution
#
#           Copyright (c) 2008,2009,2010  Paul Rubel
#
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



$domino_drawing_functions = <<EOS

/doOne
{
pgrenter
20 20 9 0 360 arc fill stroke % 1
pgrleave
} def

/doTwo
{
pgrenter
20 50 9 0 360 arc fill stroke % 2 
pgrleave
} def

/doThree
{
pgrenter
20 80 9 0 360 arc fill stroke % 3
pgrleave
} def

/doFour
{
pgrenter
50 20 9 0 360 arc fill stroke % 4
pgrleave
} def

/doFive
{
pgrenter
50 50 9 0 360 arc fill stroke % 5
pgrleave
} def

/doSix
{
pgrenter
50 80 9 0 360 arc fill stroke % 6
pgrleave
} def

/doSeven
{
pgrenter
80 20 9 0 360 arc fill stroke % 7
pgrleave
} def

/doEight{
pgrenter
80 50 9 0 360 arc fill stroke % 8
pgrleave
} def

/doNine
{
pgrenter
80 80 9 0 360 arc fill stroke % 9
pgrleave
} def

/doA0V
{} def

/doA0H
{} def

/doA1H
{
doFive
} def

/doA1V
{
doA1H
} def

/doA2H
{
doThree
doSeven
} def

/doA2V
{
doOne
doNine
} def

/doA3H
{
doThree
doFive
doSeven
} def

/doA3V
{
doOne
doFive
doNine
} def

/doA4H
{
doOne
doThree
doSeven
doNine
} def

/doA4V
{
doA4H
} def


/doA5H
{
doA4H
doFive
} def

/doA5V
{
doA5H
} def

/doA6H
{
doA4H
doFour
doSix
} def

/doA6V
{
doA4H
doEight
doTwo
} def


/doA7H
{
doA6H
doFive
}def

/doA7V
{
doA6V
doFive
}def


/doA8H
{
doA6H
doTwo
doEight
}def

/doA8V
{
doA8H
}def

/doA9H
{
doA8H
doFive
} def

/doA9V
{
doA9H
} def

EOS


## Code

class PSGenerator

  attr_accessor :white_back

  def initialize()
    #empty
    @firstPage = true
    @data = []
    @max_x = 0
    @max_y = 0
    @square_data = {}
    @page = 1
  end

  def do_check(max_sets, min_sets)
    doms = {}
    @data.each do |d|
      d1,d2=d[2..3]
      key = "#{d1}-#{d2}"
      doms[key] ||= 0
      doms[key] += 1
    end

    doms.sort.each do |k,v|
      v = doms[k]
      if (v > max_sets || v < min_sets)
        $stderr.puts "Error: Key: #{k} is used #{doms[k]} times"
      end
    end
  end


  def ps_header()
    @x_steps = @max_x/10 + 1
    @y_steps = @max_y/10 + 1

    puts "%!PS-Adobe-2.0\n%%Creator: #{$0}\n%%CreationDate: #{Time.now}"
    puts "%%Pages: #{@x_steps*@y_steps +1}"
    puts "%%BoundingBox:  0 0 612 792"
    puts "%%DocumentFonts: Time-Italic"
    puts "%%EndComments"

  end

  def prolog()    

    puts "%% $Id: to_dom.rb,v 1.33 2008/07/01 13:54:43 prubel Exp $"
    puts "% @white_back is #{@white_back}"
    puts "/pgrWhiteBack #{@white_back} def"
    puts "/pgrFirstPage true def"
    puts "\n%% Horizontal domino outline"
    puts "/outlineH"
    puts "{"
    puts "newpath" 
    puts "8 setlinewidth" 
    puts "0 0 moveto" 
    puts "200 0 lineto" 
    puts "200 100 lineto" 
    puts "0 100 lineto" 
    puts "closepath " 
    #print "%" if @white_back 
    puts "pgrWhiteBack not {fill} if "#0.2 setgray fill 0 setgray %#% for black background dominos" 
    puts "stroke" 
    puts "} def\n\n"

    puts "\n%% Vertical domino outline"
    puts "/outlineV { "
    puts "newpath"
    puts "8 setlinewidth"
    puts "0 0 moveto"
    puts "100 0 lineto"
    puts "100 200 lineto"
    puts "  0 200 lineto"
    puts "closepath"
    #print "%" if @white_back
    puts "pgrWhiteBack not {fill} if %#% for black dominos"
    puts "stroke"
    puts "} def\n\n"

    puts "\n%% White domino outline"
    puts "/outlineWhiteV { "
    puts "newpath"
    puts "3 setlinewidth"
    puts "0 0 moveto"
    puts "100 0 lineto"
    puts "100 200 lineto"
    puts "  0 200 lineto"
    puts "closepath"
    puts "0.5 setgray"
    puts "stroke"
    puts "0 setgray"
    puts "} def\n\n"

    puts "\n%% White Horizontal domino outline"
    puts "/outlineWhiteH"
    puts "{"
    puts "newpath" 
    puts "3 setlinewidth" 
    puts "0 0 moveto" 
    puts "200 0 lineto" 
    puts "200 100 lineto" 
    puts "0 100 lineto" 
    puts "closepath " 
    puts "0.5 setgray"
    puts "stroke" 
    puts "0 setgray"
    puts "} def\n\n"

    puts "/pgrenter {"
    #if (!@white_back)
      puts "pgrWhiteBack not {pgrFirstPage {0.99 setgray} if} if"
      #puts "  0.99 setgray"
    #end
    puts "} def\n\n"

    puts "/pgrleave {   "
    #if (!@white_back)
      puts "pgrWhiteBack not {  0.00 setgray} if"
    #end
    puts "} def"

    puts $domino_drawing_functions

    puts "%%EndProlog"
  end


  def flip
    puts "\n% The image data is upside down, flip it"
    puts "475 650 translate"
    puts "180 rotate"

  end


  def inTrans(x,y)
    puts "#{x} #{y} translate"
    yield
    puts "#{-1*x} #{-1*y} translate"
  end

  def gather_data(line)
    line =~ /x\[P(\d+)_(\d+),D(\d)_(\d),(.*)\]/
    x,y,d1,d2,orient = $1.to_i,$2.to_i,$3.to_i,$4.to_i,$5
    #process_line([x,y,d1,d2,orient,line])
    @max_x = x if (x > @max_x)
    @max_y = y if (y > @max_y)
    @data.push([x,y,d1,d2,orient,line])
    @square_data[[x,y]] = [d1,d2,orient, line]
  end

  def print_data
    puts "%%Page: #{@page}"
    puts "/pgrWhiteBack #{@white_back} def"
    puts "/pgrFirstPage true def"
    flip
    scale
    @page += 1
    @data.each do |d|
      process_line(d)
    end
  end

  def print_dominos_used(counts)
      x = 100
      y = 230
      puts "#{x} #{y} moveto"
      puts "(Domino Usage:) show"
      down = 0
      keys = counts.keys.sort

      while (keys.length > 0) do
        12.times do |j|
          y -= 15
          down += 15
          if (keys.length > 0)
            key = keys.shift
            puts "#{x} #{y} moveto"
            puts "(#{key}: #{counts[key]}) show"
            if (keys.length > 0 && key[0] != keys[0][0])
              #$stderr.puts "breaking key#{key} key[0]#{keys[0]}"
              break 
            end
          end
        end
        x += 45
        y += down
        down = 0
      end
   
  end

  def print_info(sets, min, max_d, counts)
    unscale
    puts "180 rotate"
    puts "-475 -650 translate"
    #$stderr.puts "info w/ sets #{sets} min #{min}"
    puts "/Times-Italic findfont 18 scalefont setfont"

    puts "200 670 moveto"
    setsS = "set"
    setsS += "s" if (sets > 1)
    complete = ""
    if (min == sets) 
      complete = " complete"
      @complete=true
    end
    puts "(Uses #{sets}#{complete} #{setsS} of double-#{max_d} dominos ) show"
    puts "/Times-Italic findfont 12 scalefont setfont"


    print_dominos_used(counts) if (min != sets)
  end

  #number of spots
  def black_on_white(white_on_black)
    res = -(-9 + white_on_black) # for black on white
    res
  end

  def process_line(line)
    x,y,d1,d2,orient,ln = line
    puts "\n% "
    puts "% #{ln}"
    puts "% d1 is #{d1} d2 #{d2}  % black on white"
    if (@white_back)
      d1 = black_on_white(d1)
      d2 = black_on_white(d2)
      puts "% d1 is #{d1} d2 #{d2}  % white on black"
    end

    draw_domino(d1, d2, orient, x, y)

  end

  def draw_domino(d1, d2, orient, x, y)
    mx = x * 100
    my = y * 100
    case orient
    when "UP"
      inTrans(mx,my) do
        puts "outlineV"
        puts "outlineWhiteV" unless (@white_back ||!@firstPage)
      end
      inTrans(mx,my) {puts "doA#{d1}V"}
      inTrans(mx,my+100) {puts "doA#{d2}V"}

    when "DOWN"
      inTrans(mx,my-100) do
        puts "outlineV"
        puts "outlineWhiteV"  unless (@white_back)
      end
      inTrans(mx,my) {puts "doA#{d1}V"}
      inTrans(mx,my-100) {puts "doA#{d2}V"}

    when "LEFT"
      inTrans(mx-100,my) do
        puts "outlineH" 
        puts "outlineWhiteH"  unless (@white_back)
      end
      inTrans(mx,my) {puts "doA#{d1}H"}
      inTrans(mx-100,my) {puts "doA#{d2}H"}

    when "RIGHT"
      inTrans(mx,my) do
        puts "outlineH" 
        puts "outlineWhiteH" unless (@white_back)
      end
      inTrans(mx,my) {puts "doA#{d1}H"}
      inTrans(mx+100,my) {puts "doA#{d2}H"}

    end
  end

  def grid_rect(x,y, stepx, stepy)
    cur_x = 0
    cur_y = 0
    @x_steps.times do |i| 
      puts "#{stepx*i} 0 moveto"
      puts "0 #{y} rlineto"
      puts "stroke"
    end

    @y_steps.times do |i| 
      puts "0 #{stepy*i} moveto"
      puts "#{x} 0 rlineto"
      puts "stroke"
    end
  end

  def draw_rect(x, y, close= false)
    puts "0 #{y} rlineto"
    puts "#{x} 0 rlineto"
    puts "0 #{-y} rlineto"
    if (!close)
      puts "#{-x} 0 rlineto"
      puts "stroke"
    else
      puts "closepath fill"
    end

  end


  #For the sub-spaces
  def print_header(x,y)
    size = 200

    puts "%%Page: #{@page}"
    @page += 1
    puts "%Quad #{x} #{y}"
    #puts "180 rotate"
    puts "0.30 0.30 scale"
    #puts "2.5 2.5 scale"
    puts "1300 2000 translate"
    puts "0 0 moveto"
    puts "8 setlinewidth"

    #puts "0.99 setgray"

    #what fraction of the size square to take
    stepX = size / @x_steps
    stepY = size / @y_steps

    draw_rect(size,size)
    grid_rect(size,size, stepX, stepY)


    
    puts "% x #{x} y #{y} stepX #{stepX} " + 
         "stepY #{stepY} maxX #{@max_x} maxY #{@max_y}"
    offX = size - x*stepX
    offY = size - y*stepY
    #puts "#{offX} #{offY} 50 0 360 arc"
    puts "#{offX} #{offY} moveto"
    draw_rect(-stepX, -stepY, true)
    puts "fill"
    puts "#{-offX} #{-offY} moveto"

    puts "/Times-Italic findfont 64 scalefont setfont"
    puts "230 320 translate"
    puts " -75 -100 moveto"
    puts "(0x) show"

    puts "100 -120 translate"
    puts " -100 -50 moveto"
    puts "(0y) show"

    puts "-500 300 translate"
    puts "/Times-Italic findfont 64 scalefont setfont"
    puts "-400 -400 translate"
    puts " 0 0 moveto"
    puts "(Quadrant #{x},#{y}) show"
    puts "180 rotate"
    #puts "fill"
    

    puts "-900 250 translate"


  end

  def print_sections()
    puts "%max_x is #{@max_x}"
    puts "%max_y is #{@max_y}"
    @x_steps = @max_x/10 + 1
    @y_steps = @max_y/10 + 1
    puts "%xSteps is #{@x_steps} ySteps is #{@y_steps}."
    @x_steps.times do |i|
      @y_steps.times do |j|
        print_section(i,j)
      end
    end
  end

  def print_square_dominos_used(counts)
    x = 1100
    y = 1200

    puts "#{x} #{y} translate"
    puts "0 0 moveto"
    x = 0 
    y = 0
    puts "180 rotate"
    puts "(Domino usage in this quad:) show"
    puts "/Times-Italic findfont 32 scalefont setfont"
    keys = counts.keys.sort
    while (keys.length > 0) do
      y = -25
      12.times do |j|
        y -= 40
        if (keys.length > 0)
          key = keys.shift
          puts "#{x} #{y} moveto"
          puts "(#{key}: #{counts[key]}) show"
          if (keys.length > 0 && key[0] != keys[0][0])
            #$stderr.puts "breaking key#{key} key[0]#{keys[0]}"
            break 
          end
        end
      end
      x += 130
      y = -25
    end
  end


  #This should draw a new page with a header about which section it is
  def print_section(qx,qy)
    puts "gsave % #{@page}" #FIXME
    puts "/pgrFirstPage false def"
    puts "/pgrWhiteBack true def"
    @firstPage=false
    print_header(qx,qy)    
    used_doms = {}
    xi = 10 * qx
    yi = 10 * qy
    (xi..xi+9).each do |x|
      (yi..yi+9).each do |y|
        key = [x,y]
        if (@square_data.has_key?(key))
          data = @square_data[key]
          d1,d2,orient = data[0],data[1],data[2]
          used_doms["#{d1}-#{d2}"] ||= 0
          used_doms["#{d1}-#{d2}"] += 1
          local_x = x - (10*qx)
          local_y = y - (10*qy)
          if (local_x < 0 || local_y < 0)
            $stderr.puts "Error, negative local values #{local_x} #{local_y}"
          end
          puts "%  lx is #{local_x} ly is #{local_y} data is #{data.inspect}"
          draw_domino(d1, d2, orient, local_x, local_y)
          if (@white_back)
            d1 = black_on_white(d1)
            d2 = black_on_white(d2)
            puts "% d1 is #{d1} d2 #{d2}  % white on black"
            
          end      
          #puts "% #{x} #{y} #{@square_data[key]}"
        end
      end
    end

    $stderr.puts "Size of used_doms is #{used_doms.size}"
    print_square_dominos_used(used_doms)

    puts "grestore  % #{@page}" #FIXME
    puts "showpage"

  end

  #a single set portrait 11x10 is scaled by .4.
  # 1 => .4 .4 
  # 4 => .2 .2
  # 9 => .14 .14
  # 16 =>  .1 .1
  # This is liner by the size of the larger size
  def scale_factor
    factor = 0.4 #0.4
    puts "% factor is #{factor}"
    puts "% max_x is #{@max_x} max_y is #{@max_y}"
    scale_x = factor/((@max_x+1)/11.0)
    scale_y = factor/((@max_y+1)/10.0)
    min = [scale_x,scale_y].min
  end

  def scale()    
    min = scale_factor
    puts "#{min} #{min} scale"
  end

  def unscale
    min = 1.0/scale_factor
    puts "#{min} #{min} scale"
  end


  ######################################################################
  ### Main below
  ######################################################################
  def main
    if __FILE__ == $0 
      my_args = ARGV.flatten
      if (my_args.length <= 0 || my_args[0] == "-h")
        puts "Usage: #{$0} {-white-back} {-black-back} input.sol"
        puts "      input.sol is a glpk solution file"
        puts "       -black-back gives white dominos with black spots. [DEFAULT]"
        puts "       -white-back gives white dominos with black spots."
        exit -1
      end

      do_white_back = false
      if (my_args.include?("-white-back"))
        do_white_back = true
      end
      my_args.delete("-white-back")
      my_args.delete("-black-back")

      @max_sets = -1
      @min_sets = 1000
      max_d = 0
      counts = {}

      solution_fn = my_args[0]
      found_sets = nil
      IO.foreach(solution_fn) do |line|
        good = false
        if (line =~ /^Status:     INTEGER (NON-)*OPTIMAL/)
          good = true
        elsif (line =~ /^Status:\s+(.*)/)
          status = $1
          unless (good)
            $stderr.puts "The solution was not complete in #{solution_fn}" +
              ", cannot use this file \nto make output. Solution needs " + 
              "to be:\n  'INTEGER OPTIMAL' or INTEGER NON-OPTIMAL' " + 
              "but is: '#{status}'"
            exit -1
          end
        # The onlySetTimes lines take two lines of outputs so we
        # note the dots on each dom and then wait for the next line 
        # to make the count
        elsif (line =~ /onlySetTimes(\d)(\d)/)
          d1 = $1.to_i
          d2 = $2.to_i
          max_d = d1 if (d1 > max_d)
          max_d = d2 if (d2 > max_d)
          found_sets = [d1,d2]
        # Once the number of sets is found, we save it to make sure
        # the count is correct
        elsif (!found_sets.nil?)
          d1,d2 = found_sets
          found_sets = nil
          if (line =~ /\s+(\d+)\s+(\d+)/)
            m_sets = $2.to_i
            m_min = $1.to_i
            counts["#{d1},#{d2}"] = m_min
            if (m_min < @min_sets)
              @min_sets = m_min
            end
            if (m_sets > @max_sets)
              @max_sets = m_sets
            end
          else
            $stderr.puts " Couldn't match on line #{line}"
          end
        end
      end
      
      
      g = PSGenerator.new
      g.white_back = do_white_back
      prev = ""
      IO.foreach(solution_fn) do |line|
        #14 spaces between * and 1 that signifies good
        if (line =~ /\*( ){14}1/) 
          g.gather_data(prev)
        end
        prev = line
      end
      
      
      g.ps_header
      g.prolog()
      puts "%%%%%%%"
      puts "%%%%%%%"
      puts "%%%%%%%"
      puts "gsave %bg"
      g.print_data
      g.print_info(@max_sets, @min_sets, max_d, counts)
      puts "grestore %%bg" #FIXME  
      puts "showpage"

      puts "%%% Sections"

      g.print_sections

      g.do_check(@max_sets, @min_sets)

    end
  end

end


pg = PSGenerator.new
pg.main
