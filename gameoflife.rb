require 'colorize'
require 'binding_of_caller'

module GameOfLife

  class Cell
    attr_accessor :currentState

    class << self
      attr_accessor :board
    end

    def initialize(x,y,state,len)
      @x = x
      @y = y
      @currentState = state
      @len = len
      @neighbours_alive = 0
      @neighbours_dead = 0
      Cell.board ||= binding.of_caller(1).eval("board")
    end

    def nextState
      val = if @neighbours_alive < 2
              false
            elsif @neighbours_alive > 3
              false
            elsif @currentState && @neighbours_alive == 2
              true
            elsif @neighbours_alive === 3
              true
            else
              false
            end
    end

    def getAllNeighboursStates
      positions = getAllNeighboursPos
      states = {}
      positions.keys.each do |pos|
        states[pos] = getNeighbor(positions[pos])
      end
      counts = Hash.new 0
      states.values.each do |value|
        counts[value] += 1
      end
      @neighbours_alive = counts[true]
      @neighbours_dead = counts[false]      
      counts
    end

    def getNeighbor(pos)
      Cell.board[pos[1]][pos[0]].currentState
    end

    def getAllNeighboursPos      
      positions = {
        :left => [getNeighborPos(@x,true),@y],
        :right => [getNeighborPos(@x,false),@y],
        :bottom => [@x,getNeighborPos(@y,true)],
        :top => [@x,getNeighborPos(@y,false)]
      }      
      positions[:leftBottom] = [positions[:left][0],positions[:bottom][1]]
      positions[:leftTop] = [positions[:left][0],positions[:top][1]]
      positions[:rightBottom] = [positions[:right][0],positions[:bottom][1]]
      positions[:rightTop] = [positions[:right][0],positions[:top][1]]
      positions
    end

    def getNeighborPos(axis,before)			
      if !isAtEdge?(axis) && before
        pos = axis - 1
      elsif !isAtEdge?(axis) && !before
        pos = axis + 1
      elsif isAtEdge?(axis) && axis == 0 && !before        
        pos = axis + 1
      elsif isAtEdge?(axis) && axis == 0 && before
        pos = @len - 1
      elsif isAtEdge?(axis) && axis == (@len - 1) && before
        pos = axis - 1
      elsif isAtEdge?(axis) && axis == (@len - 1) && !before
        pos = 0
      elsif isAtEdge?(axis) && before
        pos = axis - 1
      elsif isAtEdge?(axis) && !before
        pos = axis + 1
      else
        pos = 0
      end
      return pos
    end

    def isAtEdge?(pos)
      pos == 0 || pos == (@len - 1)
    end
  end

  class Board
    attr_accessor :board

    def initialize(square_length = 5,initial_board = nil)
      Cell.board = nil
      @board = []
      @square_length = square_length
      if not initial_board
        square_length.times do |y| 
          @board << []
          square_length.times do |x|
            on = rand > 0.70 ? true : false
            cell = Cell.new(x,y,on,square_length)
            @board[y] << cell
          end
        end
      else
        initial_board.each_with_index do |row,y|
          @board << []
          row.each_with_index do |cell_val,x|
            cell = Cell.new(x,y,cell_val,square_length)
            @board[y] << cell
          end
        end
      end
    end

    def printBoard
      @board.each do |row|
        puts "\n"
        row.each do |cell|
          print "x ".green if cell.currentState
          print "o " unless cell.currentState
        end
      end      
    end

    def refresh
      nextBoard = []
      atLeastOneAlive = false
      @board.each_with_index  do |row,i|
        nextBoard << []
        row.each do |cell|
          cell.instance_eval do
            getAllNeighboursStates
            deadOrAlive = nextState
            atLeastOneAlive = true if deadOrAlive
            nextBoard[i] << nextState
          end
        end
      end
      @board = GameOfLife::Board.new(@square_length,nextBoard)
      result = atLeastOneAlive ? @board : false
    end
  end

  class TickManager

    def initialize(tickTime,board)
      @generation = 0
      @tickTime = tickTime      
      @board = board
    end

    def run
      while true do
        system "clear" or system "cls"
        @board.printBoard
        puts; puts; puts "Generation: "+ @generation.to_s.green
        sleep @tickTime
        nextTick
      end
    end

    def nextTick
      nextBoard = []
      atLeastOneAlive = false
      if @board = @board.refresh
        @generation += 1
      else
        puts;raise "Game Over".red
      end
    end

  end
end
false_row = [false,false,false,false,false]
bfalse_row = false_row << false
beacon_1 = [false,true,true,false,false,false]
beacon_2 = beacon_1.reverse
# middle_row = [false,true,true,true,false]
#blinker_board = [false_row,false_row,middle_row,false_row,false_row]
beacon_board = [bfalse_row,beacon_1,beacon_1,beacon_2,beacon_2,bfalse_row]

# board = GameOfLife::Board.new(5,blinker_board)
board = GameOfLife::Board.new(6,beacon_board)
# board = GameOfLife::Board.new
manager = GameOfLife::TickManager.new(0.2,board)
manager.run
