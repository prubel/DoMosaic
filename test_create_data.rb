#!/usr/bin/env ruby

# tests for creating data. 
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

#     THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#     IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#     PURPOSE.
#           Copyright (c) 2008  Paul Rubel

require 'test/unit'
require 'test/unit/ui/console/testrunner'
require 'create_data.rb'
require 'create_data.rb'
require 'domino_options.rb'
require 'to_dom.rb'


class TestCreateData < Test::Unit::TestCase
  
  def setup
    #empty
  end
  
  def test_dom_set
    assert_equal(1+1,2)
  end

  def test_to_dom
    g = PSGenerator.new
    assert_equal(9, g.black_on_white(0))
    assert_equal(8, g.black_on_white(1))
    assert_equal(7, g.black_on_white(2))
    assert_equal(6, g.black_on_white(3))
    assert_equal(5, g.black_on_white(4))
    assert_equal(4, g.black_on_white(5))
    assert_equal(3, g.black_on_white(6))
    assert_equal(2, g.black_on_white(7))
    assert_equal(1, g.black_on_white(8))
    assert_equal(0, g.black_on_white(9))
  end

  #theory if arg1 < arg2 res[0] < res[1]
  def test_height
    opts = DominoOptions.new
    dc = DataCreator.new(4,"foo", opts)
    dc.t_set_size(10,11)
    res = dc.compute_size()
    assert_equal([20,22], res)
    puts "----------"

    dc.t_set_size(11,11)
    res = dc.compute_size
    assert_equal([20,22], res)
    puts "----------"

    dc.t_set_size(10,12)
    res = dc.compute_size
    assert_equal([20,22], res)
    puts "----------"

    dc.t_set_size(10,13)
    res = dc.compute_size
    assert_equal([20,22], res) # don't trust this value
    puts "--------"
   
    dc.t_set_size(10,25)
    res = dc.compute_size
    assert_equal([11,40], res) # these need to be checked
    puts "----------"

    dc.t_set_size(150,80)
    assert_equal([22,20], dc.dom_fit(440))
    puts "----------"

    dc.t_set_size(330,300)
    assert_equal([11,10], dc.dom_fit(110))
    puts "--------"

    dc.t_set_size(150,80)
    w,h = dc.compute_size
    assert_equal([22,20], [w,h]) # this should be 28,15 I think

  end
  
end
