#!/usr/bin/env ruby

# Library functions used by fill.rb

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

gem 'rmagick' 
require 'RMagick'
#convert -resize 11x10! -type Grayscale -posterize 10 vikinglander1-1.jpg vl2.bmp

class DataCreator
  def initialize(sets, file_name,options)
    @sets = sets
    @file_name = file_name
    @options = options
    @domino_shades = options.spots + 1 # a nine-spot domino has 10 "colors"
    @dominos_in_set = (1..@domino_shades).to_a.inject(0){|i,j| i+j}
  end

  def t_set_size(w,h)
    @orig_height = h
    @orig_width = w
  end

  def set_size
    o_img = Magick::Image.read("#{@file_name}").first
    @orig_height = o_img.rows.to_f
    @orig_width = o_img.columns.to_f
  end

  #might also want to try this on sum of squared error
  def ratio(a,b)
    s = [a,b].sort
    return s[0]/(s[1].to_f)
  end

  #Given a total number of spots and a goal width and height
  # optimize for keeping the best aspect ration using ALL the dominos
  def dom_fit(pixels, quiet = false)
    goal = (@orig_width*1.0) / @orig_height
    #puts "Goal is #{goal}"

    best_attempt = 1000000.0
    best_diff = 1000000.0
    best_h = -1
    best_w = -1
    (1..pixels).each do |w|
      h = (pixels) / w
      next if ( w*h != pixels)
      attempt = (w*1.0)/h
      #puts "attempt #{attempt} w/ #{h}x#{w}"
      diff = (goal - attempt).abs
      if (diff < best_diff)
        #Horizontal can't have an odd number of columns
        if (@options.horizontal && !@options.vertical && (w % 2 != 0))
          #don't do anything, this won't fit
        #Vertical only 
        elsif (@options.vertical && !@options.horizontal && (h % 2 != 0))
          #don't do anything, this won't fit
        else
          best_attempt = attempt
          best_diff = diff
          best_w = w
          best_h = h
        end
      end
    end
    unless quiet
      puts "/* Optimal aspect ratio: " + 
           "#{@orig_width}/#{@orig_height} => #{goal} */"
      puts "/* Actual aspect ratio:  #{best_w}/#{best_h} " + 
           "=> #{(best_w*1.0)/best_h} */" 
    end
    [best_w,best_h]
  end
  
  #given two float values, which int values best fit.
  # we want to not use more doms than we have and want the ratio
  # to be as close to the actual as possible. This optimizes for fit,
  # not domino usage
  # The best at preserving the aspect ratio
  def best_fit(total_doms, quiet = false)
    wr = (Math.sqrt(1.0 * total_doms * @orig_width / @orig_height)).to_i
    hr = (Math.sqrt(1.0 * total_doms * @orig_height  / @orig_width)).to_i

    diff = 1000000
    attempt = 1234567
    best = nil
    goal = ratio(wr,hr)

    # all the potential ways of changing the values that could lead to
    # optimal solutions.
    splits = [[wr-1,hr-1], [wr,hr-1], [wr,hr+1],
              [wr,hr],     [wr-1,hr], [wr+1,hr],
              [wr+1,hr-1], [wr-1,hr+1]]

    #Horizontal can't have an odd number of columns
    if (@options.horizontal && !@options.vertical)
      splits.delete_if do |x,y|
        if (0 != x%2)
          true
        else
          false
        end
      end
    end

    #Vertical only 
    if (@options.vertical && !@options.horizontal)
      splits.delete_if do |x,y|
        0 != y%2
      end
    end

    splits.each do |tw,th|
      #both not odd or too large
      if (!((1 == tw%2) && (1 == th%2)) && 
          (tw*th <= total_doms))
        attempt = ratio(tw,th)
        val = (goal - attempt).abs 
        if (val < diff)
          best = [tw,th]
          diff = val
        end
        #puts "for #{tw}:#{th} val #{val}"
      end
    end
    puts "/* width,height is #{best[0]},#{best[1]} goal ratio: #{goal} actual ratio: #{attempt}.  \n  with diff #{diff} from goal #{goal} */" unless quiet
    return best
  end

  # we can't have odd height and width but any other combination should
  # be fine. We need an even number of pixels. [w,h]
  def compute_size()
    set_size if (@orig_height.nil?)


    # every double-9 set has 55 dominos w/ 2 "pixels" each
    pixels =  @sets * (@dominos_in_set*2) 
    x = @options.x
    if (!x.nil?)
      ratio = (@orig_height) / (@orig_width*1.0)
      y = (ratio*x).floor
      y += 1 if (1 == y%2 && (1 == x%2)) 
      if ((x*y) > pixels)
          $stderr.puts "For the given x:#{x} and the calculated y:#{y}\n" + 
          "you need at least #{((x*y)/(@dominos_in_set*2.0)).ceil} sets." 
        exit(-1)
      end
      return [x, y]
    end

    if (@options.best_fit) # don't necessarily use all the dominos
      return best_fit(pixels) 
    else
      return dom_fit(pixels)
    end

  end

  def makeDominoData
    
    width, height = compute_size()
    #dom-size
    #multiple = Math.sqrt(@sets).to_i
    #    height = 10 * multiple
    #    width = 11 * multiple

    file_parts = @file_name.split('.')
    file_parts.pop
    file_base = file_parts.join('.')
    file_bmpname = file_base + ".bmp"
    system("convert  -type Grayscale  -resize #{width}x#{height}! " +
           "-posterize #{@domino_shades} -type Grayscale #{@file_name} #{file_bmpname}")
    
    img = Magick::Image.read(file_bmpname).first

    unless (@file_name == file_bmpname)
      File.delete(file_bmpname)
    end

    #resize
    #img = img.crop_resized(width,height)
    #img = img.quantize!(256, Magick::GRAYColorspace) 
    #img = img.posterize(@domino_shades)


    #get the pixels, they come out left to right from top to bottom

    pixels = img.dispatch(0,0,img.columns,img.rows,"I",true)
    #prepare the data to hold the right number of columns
    # res[x] contains a column of data
    res = []
    width.times do 
      res.push([])
    end

    # turn the floats into 0-9 and from bottom to top, left to right
    # They come out left to right, top to bottom
    count = 0
    pixels.each do |p|
      res[count % width].push((((p-0.0001) * 100)/10).to_i)
      count += 1
    end
    #somewhere in the code we're getting things reversed, and maybe upside down
    # the ps code flips things but we need to flip again. This is a hack to 
    # get the image to be the right way.
    res.reverse
  end
end

if __FILE__ == $0 
  d = DataCreator.new(4,ARGV[0])
  res = d.makeDominoData
  res.each do |r|
    p r
  end
  exit
  
end


####################################################################
####################################################################
######################## TESTS in test_crate_data.rb  ##############
####################################################################
####################################################################
