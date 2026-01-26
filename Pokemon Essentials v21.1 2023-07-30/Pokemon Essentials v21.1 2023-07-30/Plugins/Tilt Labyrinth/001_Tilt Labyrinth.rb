#===============================================================================
# * Tilt Labyrinth Game - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It's a minigame where the player must
# tilt a frame in order to make the ball fall into the goal.
#
#== HOW TO USE =================================================================
#
# To call this script, use the script command 'TiltLabyrinth.play(X)', where X
# is the labyrinth index. There are 5 valid labyrinths (starting in 1) as
# samples. This method will return the time spent (in second, as a float)
# or nil if the player loses or cancels.
#
# There are optional parameters, in order:
# - time: Time limit. Put 0 to infinite. Default is 0
# - balls: Ball limit. Put 0 to infinite. Default is 0
# - can_cancel: When true, player can exit pressing the cancel key. Default is
# true.
#
#== EXAMPLES ===================================================================
#
# - Game with labyrinth index 1:
#
#  TiltLabyrinth.play(1)
#
# - Game with labyrinth index 3 with 5 balls:
#
#  TiltLabyrinth.play(3,0,5)
#
# - Game with labyrinth index 5, with 1 minute as time limit, with 3 balls and
# player can't cancel:
#
#  TiltLabyrinth.play(5,60,3,false)
#
#== NOTES ======================================================================
#
# You can create your own labyrinths. To do this, look at create_labyrinth_array
# method. There ae instructions at this method.
#
# The ball counter label doesn't count the current ball, so if you inform 5
# balls, the counter will show only 4 balls. To change this, change the
# COUNT_CURRENT_BALL value.
#
# The same way that is an exit graphic, you can add an image as entrace graphic,
# without changing code or settings.
#
# Since game returns nil when player doesn't finish the puzzle, you can use
# `TiltLabyrinth.play(3) !=nil` in a control branch to know if player finished.
#
#===============================================================================

module TiltLabyrinth
  # Labyrinths are generated here. The parameters are: 
  # - grid: A 2D grid array. Grid values: 1=Wall 2=Hole 3=Entrace 4=Exit.
  # - background: Color or string with a image path for background.
  # - tile_path: String with a image path for custom tiles. Optional.
  # - gravity: Custom gravity. In grid positions per second. Optional.
  def self.create_labyrinth_array
    ret = []

    ret[1] = Labyrinth.new([
      [0,3,0,0,0],
      [0,0,0,0,0],
      [0,1,0,0,0],
      [0,1,0,0,0],
      [0,1,1,1,0],
      [0,0,0,0,0],
      [0,0,0,0,0],
      [1,1,1,1,0],
      [4,0,0,0,0],
    ], Color.new(0x20,0x50,0xc0)) # Blue

    ret[2] = Labyrinth.new([
      [3,0,0,1,0,0,0,0,0,0,0,0,0],
      [1,1,0,1,0,1,0,1,0,1,1,1,0],
      [0,0,3,0,0,1,4,1,0,0,4,0,0],
      [0,1,1,1,0,1,0,1,0,1,1,1,0],
      [3,0,0,0,0,0,0,0,0,0,0,0,0],
    ], Color.new(0x51,0x96,0x31), nil, GRAVITY*0.5) # Green with low gravity

    ret[3] = Labyrinth.new([
      [0,0,0,0,0,0,0,0,1,0,0,3],
      [0,1,1,1,1,0,1,0,1,0,1,1],
      [0,0,0,0,0,0,1,0,0,0,0,0],
      [1,1,1,1,0,0,1,1,1,1,1,0],
      [0,0,0,1,0,2,1,0,0,0,0,0],
      [0,1,0,1,0,0,1,0,1,1,0,0],
      [2,1,0,0,0,0,0,0,0,1,0,2],
      [0,1,1,0,1,1,1,1,0,1,1,1],
      [0,0,0,0,1,0,0,0,0,0,0,0],
      [1,1,1,1,1,0,1,1,1,1,0,1],
      [0,0,0,0,0,2,0,0,0,0,0,0],
      [0,1,0,1,0,0,0,1,0,1,1,0],
      [0,1,0,1,0,0,0,1,0,1,0,0],
      [1,1,0,1,1,1,1,1,0,1,1,1],
      [0,0,0,1,0,0,0,0,0,0,0,0],
      [0,0,0,0,0,0,1,1,1,1,1,0],
      [1,1,0,0,1,0,1,0,2,0,0,0],
      [0,0,2,0,1,0,0,0,0,1,1,1],
      [0,0,0,0,1,0,0,0,0,0,0,2],
      [1,1,0,0,1,1,1,0,1,0,1,0],
      [0,0,0,0,0,0,0,2,0,0,1,0],
      [0,0,0,0,1,0,0,0,0,1,1,0],
      [4,0,0,0,1,0,0,0,0,0,0,0],
    ], Color.new(0xc0,0x20,0x50)) # Red

    ret[4] = Labyrinth.new([
      [0,3,0,0,0,0,0,0,2],
      [0,1,0,1,0,1,0,1,0],
      [0,0,2,0,0,0,0,0,0],
      [0,1,0,1,0,1,0,1,0],
      [0,0,0,0,0,0,0,0,0],
      [0,1,0,1,0,1,4,1,0],
      [0,0,0,0,2,0,0,0,0],
      [0,1,0,1,0,1,0,1,0],
      [2,0,0,0,0,0,0,0,2],
    ], "Graphics/UI/Tilt Labyrinth/custom_board_background", "Graphics/UI/Tilt Labyrinth/custom_tile") # Custom graphics

    ret[5] = Labyrinth.new([
      [0,0,0,0,0,0,0,0,0,0,0,2],
      [0,1,1,1,0,1,0,1,1,1,0,0],
      [0,0,4,0,0,1,0,1,0,0,0,0],
      [0,1,1,1,0,1,0,1,1,1,1,1],
      [0,0,0,0,0,0,0,0,0,0,0,3],
    ], Color.new(128,32,128), nil, GRAVITY*2) # Purple with high gravity

    return ret
  end
  
  # Change this value and replace the images to change tile size.
  TILE_SIZE = 16

  # Change this value and replace the images to change balls size.
  BALL_RADIUS = 8

  # Default gravity, in grid positions. Can be override in every labyrinth.
  GRAVITY = 6
  
  # Raise to turn board faster.
  TILT_ANGLE_SPEED = 150

  # Min distance for ball drop in hole/exit, between both objects centers.
  DROP_MIN_DISTANCE = 10

  # Count current ball in the display (so 3 balls will display "Balls: 3").
  COUNT_CURRENT_BALL = false

  # When true, pause time while the exit confirm dialog is open.
  PAUSE_TIME = true

  class Board
    attr_reader   :labyrinth
    attr_accessor :angle
    attr_accessor :ball
    attr_accessor :remaining_balls
    attr_reader   :ball_finished_this_frame # Used for checking victory and for SFXs

    def initialize(labyrinth)
      @angle = 0
      @remaining_balls = nil
      @labyrinth = labyrinth
      @ball = Ball.new(labyrinth.entrace_pos_array[rand(labyrinth.entrace_pos_array.size)])
    end

    def update_ball
      return if !@ball
      @ball.update(self)
      @remaining_balls-=1 if @remaining_balls && @ball.at_hole_this_frame
      if @ball.should_finish
        @ball_finished_this_frame = true
        @ball=nil
      end
    end
  end

  class Labyrinth
    attr_reader :grid
    attr_reader :background
    attr_reader :height
    attr_reader :width
    attr_reader :gravity
    attr_reader :tile_path
    attr_reader :hole_pos_array
    attr_reader :entrace_pos_array
    attr_reader :exit_pos_array
    
    TILE = 1
    HOLE = 2
    ENTRACE = 3
    EXIT = 4

    # Easy access for labyrinth coordinates number
    def get(x,y)
      return @grid[y][x]
    end

    def passable?(x,y)
      return x>=0 && y>=0 && x<@width && y<@height && get(x,y) != TILE
    end

    def initialize(grid, background, tile_path=nil, gravity=GRAVITY)
      @grid = grid
      @background = background
      @tile_path = tile_path
      @height = grid.size
      @width = grid[0].size
      @gravity = gravity
      validate_grid
      @hole_pos_array = get_pos_array(HOLE)
      @entrace_pos_array = get_pos_array(ENTRACE)
      @exit_pos_array = get_pos_array(EXIT)
    end

    # Get the grid position of target value
    def get_pos_array(target)
      ret = []
      for y in 0...@height
        for x in 0...@width
          ret.push([x,y]) if get(x,y)==target
        end
      end
      return ret
    end

    # Find a line with different size than @width.
    # Returns the line index or nil if wasn't found
    def find_invalid_line
      return Bridge.find_index(@grid){|line| line.size != @width}
    end

    def validate_grid
      raise ArgumentError, _INTL(
        "Labyrinth line {1} width is {2}! All lines should have the same size in a labyrinth",
        find_invalid_line,@grid[find_invalid_line].size
      ) if find_invalid_line
      raise ArgumentError, _INTL("Labyrinth has no entraces!") if get_pos_array(ENTRACE).empty?
      raise ArgumentError, _INTL("Labyrinth has no exits!") if get_pos_array(EXIT).empty?
    end
  end

  class Ball
    attr_reader :speed
    attr_reader :start_pos
    attr_reader :grid_pos
    attr_reader :should_finish
    attr_reader :at_hole_this_frame

    def initialize(start_pos)
      @should_finish = false
      @at_hole_this_frame = false
      @start_pos = start_pos
      reset_pos
      @tile_min_distance = BALL_RADIUS/TILE_SIZE.to_f + 0.5
      @drop_min_distance = DROP_MIN_DISTANCE/TILE_SIZE.to_f
    end

    def reset_pos
      @grid_pos = @start_pos.clone
      @speed = [0,0]
    end
    
    def update(board)
      @at_hole_this_frame = false
      @last_grid_pos = @grid_pos.clone
      apply_gravity(board.labyrinth.gravity*Bridge.formatted_delta, TiltLabyrinth.round_angle(board.angle))
      update_direction(0, board)
      update_direction(1, board)
      if @grid_pos[0] != @last_grid_pos[0] || @grid_pos[1] != @last_grid_pos[1]
        update_hole(board.labyrinth.hole_pos_array)
        update_exit(board.labyrinth.exit_pos_array)
      end
    end

    def apply_gravity(base_value, int_angle)
      @speed[0] += -(int_angle>=0 ? 1 : -1)*base_value*TiltLabyrinth.sin_basic_array[int_angle.abs]
      @speed[1] += base_value*TiltLabyrinth.cos_basic_array[int_angle.abs]
    end

    # Check one axis
    def update_direction(axis, board)
      return if @speed[axis]==0
      update_direction_tiles(axis, (@speed[axis]>0 ? 1 : -1)*@tile_min_distance, board.labyrinth)
    end

    # Update movement checking tiles.
    # Tile bonus is the min distance possible between ball and tiles. Positive when 
    # checked in positive axis and vice-versa
    def update_direction_tiles(axis, tile_bonus, labyrinth)
      target_new_pos = [@grid_pos[0], @grid_pos[1]]
      target_new_pos[axis] += @speed[axis]*Bridge.formatted_delta + tile_bonus
      pos_to_check_array = all_pos_in_way(@grid_pos, target_new_pos, axis, (tile_bonus>0 ? 1 : -1))
      @grid_pos[axis] = target_new_pos[axis]
      for pos_to_check in pos_to_check_array
        next if labyrinth.passable?(pos_to_check[0].round, pos_to_check[1].round)
        @grid_pos[axis] = limit_surpass(target_new_pos[axis], pos_to_check[axis].round, @speed[axis])
        @speed[axis] = 0 if @grid_pos[axis] == target_new_pos[axis].round
        break
      end
      @grid_pos[axis] -= tile_bonus
    end

    # Update if ball goes into a hole
    def update_hole(hole_pos_array)
      for hole_pos in hole_pos_array
        if TiltLabyrinth.distance(@grid_pos, hole_pos) <= @drop_min_distance
          @at_hole_this_frame = true
          reset_pos
          return
        end
      end
    end

    # Update if ball goes into an exit
    def update_exit(exit_pos_array)
      for exit_pos in exit_pos_array
        if TiltLabyrinth.distance(@grid_pos, exit_pos) <= @drop_min_distance
          @should_finish = true
          return
        end
      end
    end

    # Return an array of points in the way to check. Used to avoid skipping checks.
    # Way is 1 or -1
    def all_pos_in_way(current_pos, target_new_pos_rounded, axis, way)
      ret=[]
      for new_pos in reverse_range_if_possible((current_pos[axis].round)..target_new_pos_rounded[axis].round)
        ret.push([current_pos[0].round, current_pos[1].round])
        ret[-1][axis] = new_pos
      end
      ret.reverse! if way<0
      return ret
    end
  
    # If range is reversed, fix it. Else does nothing
    def reverse_range_if_possible(range)
      return range if range.first <= range.last
      return range.exclude_end? ? range.last...range.first  : range.last..range.first
    end

    # Avoid current surpassing target
    def limit_surpass(current, target, way)
      return way>0 ? [current, target].min : [current, target].max
    end
  end

  # Class to hold the sprites frame, including the background
  # Z is + 10 of current z, except background
  class SpriteFrame
    attr_reader   :x
    attr_reader   :y
    attr_reader   :z
    attr_reader   :width
    attr_reader   :height
    attr_reader   :angle
    attr_reader   :color
    attr_reader   :visible

    def disposed?
      return @disposed
    end

    def visible=(value)
      @visible = value
      for sprite in @sprites.values
        sprite.visible = @visible
      end
    end

    def color=(value)
      @color = value
      for sprite in @sprites.values
        sprite.color = @color
      end
    end

    def z=(value)
      @z = value
      for key in @sprites.keys
        @sprites[key].z = @z
        @sprites[key].z+=10 if key!="background"
      end
    end

    def angle=(value)
      @angle = value
      for sprite in @sprites.values
        sprite.angle = @angle
      end
    end

    def inside_rect=(value)
      @inside_rect = value
      @x = value.x - @tile_width
      @y = value.y - @tile_height
      @width = value.width + @tile_width*2
      @height = value.height + @tile_height*2
    end

    def initialize(rect, path, pivot, background_param, viewport)
      @pivot = pivot
      @viewport = viewport
      generate_base_bitmap(path)
      self.inside_rect = rect
      @angle = 0
      @disposed = false
      @visible = true
      @color = Color.new(0,0,0,0)
      generate_sprites(background_param)
      self.z = 0
      refresh_positions
      assign_pivot_all
    end

    def generate_base_bitmap(path)
      @bitmap = Bitmap.new(path)
      raise _INTL("Bitmap's width should be a multiple of 3. Value is #{@bitmap.width}") if @bitmap.width % 3 !=0
      raise _INTL("Bitmap's height should be a multiple of 3. Value is #{@bitmap.height}") if @bitmap.height % 3 !=0
      @tile_width = @bitmap.width/3
      @tile_height = @bitmap.height/3
    end

    def generate_sprites(background_param)
      @sprites = {}
      @sprites["background"] = create_background(background_param)
      generate_corner_sprites
      generate_side_sprites
    end

    # If the param is a color, fill the background with the color
    # if is a path, load it as wrapped background
    def create_background(param)
      ret=BitmapSprite.new(@inside_rect.width, @inside_rect.height, @viewport)
      if param.is_a?(Color)
        ret.bitmap.fill_rect(ret.src_rect, param)
      else
        fill_wrapped_background(ret.bitmap, Bitmap.new(param))
      end
      return ret
    end

    # Manually do, since Plane doesn't support angle
    def fill_wrapped_background(dest_bitmap, src_bitmap)
      y=0
      while @inside_rect.height>y
        x=0
        while @inside_rect.width>x
          dest_bitmap.blt(x,y, src_bitmap, src_bitmap.rect)
          x+=src_bitmap.rect.width
        end
        y+=src_bitmap.rect.height
      end
    end

    def generate_corner_sprites
      generate_element_sprites("corner")
      for i in 0...4
        @sprites["corner#{i}"].bitmap = @bitmap
        @sprites["corner#{i}"].src_rect.set(
          i%2==0 ? 0 : @tile_width*2, i/2==0 ? 0 : @tile_height*2, @tile_width, @tile_height
        )
      end
    end
    
    def generate_side_sprites
      generate_element_sprites("side")
      for i in 0...4
        if horizontal_side_index?(i)
          @sprites["side#{i}"].bitmap = Bitmap.new(@width - @tile_width*2, @tile_height) 
        else
          @sprites["side#{i}"].bitmap = Bitmap.new(@tile_width, @height - @tile_height*2)
        end
      end
      stretch_side(0, @tile_width, 0)
      stretch_side(1, 0, @tile_height)
      stretch_side(2, @tile_width*2, @tile_height)
      stretch_side(3, @tile_width, @tile_height*2)
    end

    def stretch_side(index, x, y)
      @sprites["side#{index}"].bitmap.stretch_blt(
        @sprites["side#{index}"].src_rect, @bitmap, Rect.new(x,y,@tile_width, @tile_height)
      )
    end

    # Create the 4 position element sprites.
    # Parts numbered by table position, starting in top left, ending in bottom right
    def generate_element_sprites(key_base)
      for i in 0...4
        @sprites["#{key_base}#{i}"] = Sprite.new(@viewport)
      end
    end

    def horizontal_side_index?(index)
      return [0,3].include?(index)
    end

    def refresh_positions
      set_sprite_pos("background", @x+@tile_width, @y+@tile_height)
      set_sprite_pos("corner0", @x, @y)
      set_sprite_pos("corner1", @x + @width - @tile_width, @y)
      set_sprite_pos("corner2", @x, @y + @height - @tile_height)
      set_sprite_pos("corner3", @x + @width - @tile_width, @y + @height - @tile_height)
      set_sprite_pos("side0", @x + @tile_width, @y)
      set_sprite_pos("side1", @x, @y + @tile_height)
      set_sprite_pos("side2", @x + @width - @tile_width, @y + @tile_height)
      set_sprite_pos("side3", @x + @tile_width, @y + @height - @tile_height)
    end

    def set_sprite_pos(key, x, y)
      @sprites[key].x = x
      @sprites[key].y = y
    end

    def assign_pivot_all
      for sprite in @sprites.values
        TiltLabyrinth.set_pivot(sprite, @pivot)
      end
    end

    def update
      for sprite in @sprites.values
        sprite.update
      end
    end

    def dispose
      for sprite in @sprites.values
        sprite.dispose
      end
      @sprites = nil
    end
  end

  class Scene    
    def start(screen)
      @screen = screen
      @sprites={} 
      @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z=99999
      @current_time = nil
      @sprites["background"]=IconSprite.new(0,0,@viewport)
      @sprites["background"].setBitmap("Graphics/UI/Tilt Labyrinth/background")
      generate_tileset(@screen.board.labyrinth)
      generate_ball(@screen.board.ball.grid_pos)
      @sprites["frame"]=SpriteFrame.new(Rect.new(
        @pivot[0]-@board_pixel_size[0]/2,@pivot[1]-@board_pixel_size[1]/2,
        @board_pixel_size[0],@board_pixel_size[1]
      ),"Graphics/UI/Tilt Labyrinth/border", @pivot, @screen.board.labyrinth.background, @viewport)
      @sprites["overlay"]=BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      draw_text
      pbBGMPlay(Bridge.bgm_path)
      pbFadeInAndShow(@sprites) { update }
    end

    def draw_text
      @sprites["overlay"].bitmap.clear
      @current_time = displayable_time_value
      @current_balls = displayable_ball_value if @screen.has_ball_limit?
      Bridge.drawTextPositions(@sprites["overlay"].bitmap, create_text_args(Color.new(248,248,248),Color.new(0,0,0)))
    end

    def create_text_args(font_color, shadow_color)
      ret = []
      ret.push([
        sprintf("%d:%02d", @current_time / 60, @current_time % 60), 
        Graphics.width-8, 12, true, font_color,shadow_color
      ])
      ret.push([
        _INTL("Balls: {1}", @current_balls), 8, 12, false, font_color, shadow_color
      ]) if @screen.has_ball_limit?
      return ret
    end

    def should_redraw_text?
      return @current_time != displayable_time_value || (
        @screen.has_ball_limit? && @current_balls != displayable_ball_value
      )
    end

    def displayable_time_value
      return [0,(@screen.has_time_limit? ? @screen.max_time-@screen.time_count : @screen.time_count).floor].max
    end

    def displayable_ball_value
      ret = @screen.board.remaining_balls
      ret -= 1 if !COUNT_CURRENT_BALL
      ret = [ret,0].max
      return ret
    end

    def generate_tileset(labyrinth)
      @pivot = [Graphics.width/2, Graphics.height/2]
      @board_pixel_size = [labyrinth.width*TILE_SIZE, labyrinth.height*TILE_SIZE]
      for y in 0...labyrinth.height
        for x in 0...labyrinth.width
          case labyrinth.get(x,y)
          when Labyrinth::TILE;     generate_tile([x,y], labyrinth.tile_path)
          when Labyrinth::HOLE;     generate_hole([x,y])
          when Labyrinth::ENTRACE;  generate_entrace([x,y])
          when Labyrinth::EXIT;     generate_exit([x,y])
          end
        end
      end
    end

    def generate_tile(grid_pos, custom_tile_path)
      return generate_element(grid_pos, 2, custom_tile_path || "Graphics/UI/Tilt Labyrinth/tile", "tile")
    end

    def generate_ball(grid_pos)
      return generate_element(grid_pos, 3, "Graphics/UI/Tilt Labyrinth/ball", "ball")
    end

    def generate_hole(grid_pos)
      return generate_element(grid_pos, 1, "Graphics/UI/Tilt Labyrinth/hole", "hole")
    end

    def generate_entrace(grid_pos)
      return generate_element(grid_pos, 1, "Graphics/UI/Tilt Labyrinth/entrace", "entrace")
    end

    def generate_exit(grid_pos)
      return generate_element(grid_pos, 1, "Graphics/UI/Tilt Labyrinth/exit", "exit")
    end

    def get_next_sprite_index(base_key)
      for i in 0...10000
        return i if !@sprites.has_key?("#{base_key}#{i}")
      end
      return nil
    end

    def generate_element(grid_pos, z, image_path, base_key, index=nil)
      return if !pbResolveBitmap(image_path)
      index||= get_next_sprite_index(base_key)
      @sprites["#{base_key}#{index}"] = IconSprite.new(0,0,@viewport)
      @sprites["#{base_key}#{index}"].setBitmap(image_path)
      @sprites["#{base_key}#{index}"].z = z
      set_sprite_pos(@sprites["#{base_key}#{index}"], grid_pos)
      set_pivot(@sprites["#{base_key}#{index}"])
      return @sprites["#{base_key}#{index}"]
    end

    def set_sprite_pos(sprite, grid_pos)
      sprite.x = grid_to_world_x(sprite, grid_pos[0])
      sprite.y = grid_to_world_y(sprite, grid_pos[1])
      sprite.ox = 0
      sprite.oy = 0
      set_pivot(sprite)
    end

    # As angle 0
    def grid_to_world_x(sprite, x)
      return (x+0.5)*TILE_SIZE - (sprite.bitmap.width + @board_pixel_size[0])*0.5 + @pivot[0]
    end

    # As angle 0
    def grid_to_world_y(sprite, y)
      return (y+0.5)*TILE_SIZE - (sprite.bitmap.height + @board_pixel_size[1])*0.5 + @pivot[1]
    end

    def set_pivot(sprite)
      TiltLabyrinth.set_pivot(sprite, @pivot)
    end

    def main(canCancel)
      loop do
        Graphics.update
        Input.update
        self.update
        if Input.trigger?(Input::B) && canCancel && Bridge.confirmMessage(_INTL("Exit?")){ update_at_prompt }
          pbPlayCursorSE
          break
        end
        update_angle(input_press) if input_press!=0 
        @screen.update
        update_ball_sprite(@screen.board.ball)
        draw_text if should_redraw_text?
        update_sounds
        break if @screen.completed || @screen.time_limit_triggered? || @screen.ball_limit_triggered? 
      end
    end

    def update_sounds
      pbSEPlay(Bridge.hole_se_path) if @screen.board.ball && @screen.board.ball.at_hole_this_frame
      pbMEPlay(Bridge.victory_me_path) if @screen.board.ball_finished_this_frame
    end

    # Return 1 if pressed right or -1 if pressed left 
    def input_press
      ret=0
      ret-=1 if Input.press?(Input::LEFT)
      ret+=1 if Input.press?(Input::RIGHT)
      return ret
    end

    def update_ball_sprite(ball)
      if !ball
        @sprites["ball0"].visible = false
        return
      end
      set_sprite_pos(@sprites["ball0"], ball.grid_pos)
    end

    def update_angle(value)
      @screen.update_angle(value)
      update_sprites_angle(@screen.board.angle, ["ball", "tile", "hole", "entrace", "exit"])
      @sprites["frame"].angle = @screen.board.angle
    end

    # Update angle of all elements in key_array 
    def update_sprites_angle(angle, key_array)
      for base_key in key_array
        for i in 0...get_next_sprite_index(base_key)
          next if !@sprites["#{base_key}#{i}"].visible
          @sprites["#{base_key}#{i}"].angle = angle
        end
      end
    end
    
    def update_at_prompt
      update
      @screen.update(true)
      draw_text if should_redraw_text?
    end
    
    def update
      pbUpdateSpriteHash(@sprites)
    end
    
    def finish
      $game_map.autoplay
      pbFadeOutAndHide(@sprites) { update }
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
    end
  end

  class Screen
    attr_reader :board
    attr_reader :time_count
    attr_reader :max_time
    attr_reader :completed

    def initialize(scene, labyrinth_index, time, balls)
      @board = create_board(labyrinth_index, TiltLabyrinth.create_labyrinth_array)
      @board.remaining_balls = balls if balls>0
      @time_count = 0
      @max_time = time
      @completed = false
      @scene = scene
    end

    def create_board(labyrinth_index, labyrinth_array)
      raise ArgumentError, _INTL(
        "labyrinth_index informed is {1}, but there is only {2} labyrinths!", 
        labyrinth_index, labyrinth_array.size
      ) if labyrinth_array.size <= labyrinth_index
      return Board.new(labyrinth_array[labyrinth_index])
    end

    def start(can_cancel)
      @scene.start(self)
      @scene.main(can_cancel)
      @scene.finish
      return @completed ? @time_count : nil
    end

    # Dir is 0, -1 or 1
    def update_angle(dir)
      return if dir==0
      @board.angle += dir*TILT_ANGLE_SPEED*Bridge.formatted_delta
    end

    def update(prompt_active=false)
      if !prompt_active
        @board.update_ball
        @completed = true if @board.ball_finished_this_frame
      end
      @time_count+=Bridge.formatted_delta if !prompt_active || !PAUSE_TIME
    end

    def has_time_limit?
      return @max_time>0
    end

    def time_limit_triggered?
      return has_time_limit? && @time_count>=@max_time
    end

    def has_ball_limit?
      return @board.remaining_balls
    end

    def ball_limit_triggered?
      return @board.remaining_balls && @board.remaining_balls<=0
    end
  end
  
  @@sin_basic_array = nil
  @@cos_basic_array = nil

  module_function

  # Simple sin table, so Won't calculate it in runtime
  def sin_basic_array
    @@sin_basic_array ||= (0..180).to_a.map{|i| Math.sin(i*Math::PI/180.0)}
    return @@sin_basic_array
  end

  def cos_basic_array
    @@cost_basic_array ||= (0..180).to_a.map{|i| Math.cos(i*Math::PI/180.0)}
    return @@cost_basic_array
  end

  def round_angle(angle)
    angle-=360 while angle>180
    angle+=360 while angle<-180
    return angle.round
  end

  def distance(a_pos, b_pos)
    ret = 0
    for i in 0...2
      ret += (a_pos[i] - b_pos[i])**2
    end
    ret = Math.sqrt(ret)
    return ret
  end

  def set_pivot(sprite, pivot)
    diff_x = pivot[0] - sprite.x + sprite.ox
    diff_y = pivot[1] - sprite.y + sprite.oy
    sprite.x = pivot[0]
    sprite.y = pivot[1]
    sprite.ox = diff_x
    sprite.oy = diff_y
  end
  
  def play(labyrinth_index, time=0, balls=0, can_cancel=true)
    ret = nil
    pbFadeOutIn(99999){
      scene=Scene.new
      screen=Screen.new(scene, labyrinth_index, time, balls)
      ret=screen.start(can_cancel)
    }
    return ret
  end

  # Essentials multiversion layer
  module Bridge
    @@audioNameHash = nil
    module_function

    def major_version
      ret = 0
      if defined?(Essentials)
        ret = Essentials::VERSION.split(".")[0].to_i
      elsif defined?(ESSENTIALS_VERSION)
        ret = ESSENTIALS_VERSION.split(".")[0].to_i
      elsif defined?(ESSENTIALSVERSION)
        ret = ESSENTIALSVERSION.split(".")[0].to_i
      end
      return ret
    end

    MAJOR_VERSION = major_version

    def formatted_delta
      return 0.025 if MAJOR_VERSION < 21
      return [0.1, Graphics.delta].min # Avoid too big, or balls will surpass tiles
    end

    def find_index(array, &block)
      if MAJOR_VERSION < 19
        for i in 0...array.length
          return i if yield(array[i])
        end
        return nil
      end
      return array.find_index(&block)
    end

    def confirmMessage(string, &block)
      return Kernel.pbConfirmMessage(string, &block) if MAJOR_VERSION < 20
      return pbConfirmMessage(string, &block)
    end

    def drawTextPositions(bitmap,textpos)
      if MAJOR_VERSION < 20
        for singleTextPos in textpos
          singleTextPos[2] -= MAJOR_VERSION==19 ? 12 : 6
        end
      end
      return pbDrawTextPositions(bitmap,textpos)
    end

    def hole_se_path
      return "balldrop" if MAJOR_VERSION < 17
      return "Battle ball drop"
    end

    def victory_me_path
      return "Voltorb Flip win"
    end

    def bgm_path
      return "021-Field04" if MAJOR_VERSION < 17
      return "Safari Zone"
    end
  end
end