
# Parse the cmd line options.

#           Copyright (c) 2008,2009,2010  Paul Rubel
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

class DominoOptions

  attr_accessor :sets, 
    :horizontal,     # Should all the dominos be oriented left/right?
    :white_on_black, # Should the dots be white(true) or black(false)
    :best_fit,       # true if we fit the dominos to the picture, perhaps
                     #  leaving some dominos unused. 
                     # false if we use all the dominos even if it means
                     #  a bad aspect ratio.
    :vertical,       # Should all the dominos be oriented up/down?
    :spots,          # How many spost on the dominos?
    :x               # x-width of the final result or nil if unset

  def vertical
    @vertical
  end

  def horizontal
    @horizontal
  end

  def vert(b)
    @vertical = b
    @horizontal = !b
  end

  def horiz(b)
    @vertical = !b
    @horizontal = b
  end

  # When orientation doesn't matter.
  def mix(b)
    @mix = b
    if (b)
      @horizontal = true
      @vertical = true
    end
  end

  def initialize
    @white_on_black = true
    @best_fit = false
    @spots = 9
    x=nil
    @sets = nil
    mix(true)
  end

  def to_s
    res = "Sets:#{@sets} Spots:#{@spots}"
    if (!x.nil?)
      res += " Width set to #{@x}" 
    else
      if (@best_fit)
        res += " Optimizing for fit, may not use all dominos. "
      else 
        res += " Optimizing to use all dominos. "
      end
    end
    res += "\n            "
    if (@horizontal && @vertical)
      res += "Mixed orientations"
    elsif (@horizontal)
      res += "Horizontal orientation "
    elsif (@vertical)
      res += "Vertical orientation "
    end


  end

  
end
