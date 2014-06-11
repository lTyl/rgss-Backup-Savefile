#===============================================================================
# Backup Savefile
#===============================================================================
# Written by Synthesize
# version 1.0.0
# February 16, 2008
#===============================================================================
#            * This script is not compatible with RPG Maker VX *
#-------------------------------------------------------------------------------
module SynSaveBU
  Folder_name = "Saves/"   # The folder where all saved files go
  Backup_folder = "Saves/Backup/"   # The folder where all backed up files go
  Save_extension = ".rxdata"   # The extension to the save filenames
  Deleted_folder = "Deleted/"   # The folder where deleted saved games go
  Overwritten_folder = "Overwritten/"   # The folder where overwritten saved games go
  Number_of_saves = 99   # The maximum number of save slots
  Confirm_text = "Confirm"    # The confirm text
  Delete_text = "Delete File"   # The delete text
  Cancel_text = "Cancel"   # The cance; text
  Command_width = 200   # The command window width
  # NOTE:
  # Saved games are saved via the following format:
  # "Folder_Name/Save[Save Number slot]_PH_PM_PS
  # Where PH is Play time in hours
  # PM is Playtime in minutes
  # PS is the playtime in seconds
  # NOTE:
  # The Deleted and Overwritten folders are designed to be within the backup
  # folder. So for example, if you have all of your Saves in the "Saves" folder,
  # Then all of the deleted saved games will go to "Saves/Deleted" and
  # overwritten files will go to "Saves/Overwritten" Of course, you can specify
  # your own folder names.
  # NOTE:
  # In order to restore a previous saved game, copy and paste it from the 
  # backed up folder into your saved game folder and then rename the file
  # to Save[number].[extension]
  # Where:
  # Number is the Save Slot and Extension is your file extension.
  # NOTE:
  # If you want to save the game somewhere other then the project folder
  # Use a folder like this:
  # Drive:/[Save Folder name]
  # Where Drive is the Drive (ie. C)
  # amd Save Folder is your Save Fodlers name.
end
#-------------------------------------------------------------------------------
# Window_SaveFile:: Rewrite the initialize method of Window_SaveFile
#-------------------------------------------------------------------------------
class Window_SaveFile < Window_Base
  def initialize(file_index, filename, position)
    y = 64 + position * 104
    super(0, y, 640, 104)
    self.contents = Bitmap.new(width - 32, height - 32)
    @file_index = file_index
    @filename = "#{SynSaveBU::Folder_name}Save#{@file_index + 1}#{SynSaveBU::Save_extension}"
    @time_stamp = Time.at(0)
    @file_exist = FileTest.exist?(@filename)
    if @file_exist
      file = File.open(@filename, "r")
      @time_stamp = file.mtime
      @characters = Marshal.load(file)
      @frame_count = Marshal.load(file)
      @game_system = Marshal.load(file)
      @game_switches = Marshal.load(file)
      @game_variables = Marshal.load(file)
      @total_sec = @frame_count / Graphics.frame_rate
      file.close
    end
    refresh
    @selected = false
  end
end
#-------------------------------------------------------------------------------
# Scene_Title:: Rewrites (:() the main method of Scene_Title
#-------------------------------------------------------------------------------
class Scene_Title
  def main
    # If battle test
    if $BTEST
      battle_test
      return
    end
    # Load database
    $data_actors        = load_data("Data/Actors.rxdata")
    $data_classes       = load_data("Data/Classes.rxdata")
    $data_skills        = load_data("Data/Skills.rxdata")
    $data_items         = load_data("Data/Items.rxdata")
    $data_weapons       = load_data("Data/Weapons.rxdata")
    $data_armors        = load_data("Data/Armors.rxdata")
    $data_enemies       = load_data("Data/Enemies.rxdata")
    $data_troops        = load_data("Data/Troops.rxdata")
    $data_states        = load_data("Data/States.rxdata")
    $data_animations    = load_data("Data/Animations.rxdata")
    $data_tilesets      = load_data("Data/Tilesets.rxdata")
    $data_common_events = load_data("Data/CommonEvents.rxdata")
    $data_system        = load_data("Data/System.rxdata")
    # Make system object
    $game_system = Game_System.new
    # Make title graphic
    @sprite = Sprite.new
    @sprite.bitmap = RPG::Cache.title($data_system.title_name)
    # Make command window
    s1 = "New Game"
    s2 = "Continue"
    s3 = "Shutdown"
    @command_window = Window_Command.new(192, [s1, s2, s3])
    @command_window.back_opacity = 160
    @command_window.x = 320 - @command_window.width / 2
    @command_window.y = 288
    # Continue enabled determinant
    # Check if at least one save file exists
    # If enabled, make @continue_enabled true; if disabled, make it false
    @continue_enabled = false
    for i in 0..SynSaveBU::Number_of_saves
      if FileTest.exist?("#{SynSaveBU::Folder_name}Save#{i+1}#{SynSaveBU::Save_extension}")
        @continue_enabled = true
      end
    end
    # If continue is enabled, move cursor to "Continue"
    # If disabled, display "Continue" text in gray
    if @continue_enabled
      @command_window.index = 1
    else
      @command_window.disable_item(1)
    end
    # Play title BGM
    $game_system.bgm_play($data_system.title_bgm)
    # Stop playing ME and BGS
    Audio.me_stop
    Audio.bgs_stop
    # Execute transition
    Graphics.transition
    # Main loop
    loop do
      # Update game screen
      Graphics.update
      # Update input information
      Input.update
      # Frame update
      update
      # Abort loop if screen is changed
      if $scene != self
        break
      end
    end
    # Prepare for transition
    Graphics.freeze
    # Dispose of command window
    @command_window.dispose
    # Dispose of title graphic
    @sprite.bitmap.dispose
    @sprite.dispose
  end
end
#==============================================================================
# ** Scene_File
#------------------------------------------------------------------------------
#  This is a superclass for the save screen and load screen.
#==============================================================================
class Scene_File
  def main
    @help_window = Window_Help.new
    @help_window.set_text(@help_text)
    @savefile_windows = []
    @selection = false
    @cursor_displace = 0
    @index = 0
    call_command
    @command_window.visible = false
    @command_window.active = false
    @command_window.z = 9999
    for i in 0..3
      @savefile_windows.push(Window_SaveFile.new(i, make_filename(i), i))
    end
    @file_index = 0
    @savefile_windows[@file_index].selected = true
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      if $scene != self
        break
      end
    end
    Graphics.freeze
    @help_window.dispose
    @command_window.dispose
    for i in @savefile_windows
      i.dispose
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    @help_window.update
    for i in @savefile_windows
      i.update
    end
    # Check Confirm Input
    if Input.trigger?(Input::C)
      if @command_window.active == false
        @index = @file_index
        @selection = true
        @command_window.active = true
        @command_window.visible = true
        end
      return
    end
    # Check Cancel Input
    if Input.trigger?(Input::B)
      @selection = false
      if @command_window.active == false
        on_cancel
      else
        @command_window.active = false
        @command_window.visible = false
      end
      return
    end
    # Check Down Input
    if Input.repeat?(Input::DOWN)
      if Input.trigger?(Input::DOWN) or @file_index < SynSaveBU::Number_of_saves - 1
        if @file_index == SynSaveBU::Number_of_saves - 1
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        @cursor_displace += 1
        if @cursor_displace == 4
          @cursor_displace = 3
          for i in @savefile_windows
            i.dispose
          end
          @savefile_windows = []
          for i in 0..3
            f = i - 2 + @file_index
            name = make_filename(f)
            @savefile_windows.push(Window_SaveFile.new(f, name, i))
            @savefile_windows[i].selected = false
          end
        end
        $game_system.se_play($data_system.cursor_se)
        @file_index = (@file_index + 1)
        if @file_index == SynSaveBU::Number_of_saves
          @file_index = SynSaveBU::Number_of_saves - 1
        end
        for i in 0..3
          @savefile_windows[i].selected = false
        end
        @savefile_windows[@cursor_displace].selected = true
        return
      end 
    end
    # Check UP Input
    if Input.repeat?(Input::UP)
      if Input.trigger?(Input::UP) or @file_index > 0
        if @file_index == 0
          $game_system.se_play($data_system.buzzer_se)
          return
        end
        @cursor_displace -= 1
        if @cursor_displace == -1
          @cursor_displace = 0
          for i in @savefile_windows
            i.dispose
          end
          @savefile_windows = []
          for i in 0..3
            f = i - 1 + @file_index
            name = make_filename(f)
            @savefile_windows.push(Window_SaveFile.new(f, name, i))
            @savefile_windows[i].selected = false
          end
        end
        $game_system.se_play($data_system.cursor_se)
        @file_index = (@file_index - 1)
        if @file_index == -1
          @file_index = 0
        end
        for i in 0..3
          @savefile_windows[i].selected = false
        end
        @savefile_windows[@cursor_displace].selected = true
        return
      end
    end
  end
  #-----------------------------------------------------------------------------
  # Call_Command:: Call the command window
  #-----------------------------------------------------------------------------
  def call_command
    s1 = SynSaveBU::Confirm_text 
    s2 = SynSaveBU::Delete_text
    s3 = SynSaveBU::Cancel_text
    @command_window = Window_Command.new(SynSaveBU::Command_width,[s1,s2,s3])
    @command_window.x = 240
    @command_window.y = 200
  end
  #-----------------------------------------------------------------------------
  # * Make File Name
  #-----------------------------------------------------------------------------
  def make_filename(file_index)
    return "#{SynSaveBU::Folder_name}Save#{file_index + 1}#{SynSaveBU::Save_extension}"
  end
  #-----------------------------------------------------------------------------
  # Update_Commad:: Update the confirm window
  #-----------------------------------------------------------------------------
  def update_command
    if @command_window.active && Input.trigger?(Input::C)
      case @command_window.index
      when 0 # Confirm
        filename = "#{SynSaveBU::Folder_name}Save#{@file_index + 1}#{SynSaveBU::Save_extension}"
        total_sec = Graphics.frame_count / Graphics.frame_rate
        hour = total_sec / 60 / 60
        min = total_sec / 60 % 60
        sec = total_sec % 60
        text = sprintf("%02d_%02d_%02d", hour, min, sec)
        next_directory = "#{SynSaveBU::Backup_folder}#{SynSaveBU::Overwritten_folder}Save#{@file_index + 1}_#{text}#{SynSaveBU::Save_extension}"
        file_exist = FileTest.exist?(filename)
        if file_exist && $scene.is_a?(Scene_Save)
          File.rename(filename, next_directory)
        end
        on_decision(make_filename(@index))
        $game_temp.last_file_index = @file_index
      when 1 # Delete
        filename = "#{SynSaveBU::Folder_name}Save#{@file_index + 1}#{SynSaveBU::Save_extension}"
        total_sec = Graphics.frame_count / Graphics.frame_rate
        hour = total_sec / 60 / 60
        min = total_sec / 60 % 60
        sec = total_sec % 60
        text = sprintf("%02d_%02d_%02d", hour, min, sec)
        next_directory = "#{SynSaveBU::Backup_folder}#{SynSaveBU::Deleted_folder}Save#{@file_index + 1}_#{text}#{SynSaveBU::Save_extension}"
        file_exist = FileTest.exist?(filename)
        if file_exist
          File.rename(filename, next_directory)
          if $scene.is_a?(Scene_Save)
            $scene = Scene_Save.new
          else
            $scene = Scene_Load.new
          end
        end
      when 2 # Cancel
        @command_window.active = false
        @command_window.visible = false
        @selection = false
      end
    end
  end
end
#-------------------------------------------------------------------------------
# Scene_Save:: Create the Update method
#-------------------------------------------------------------------------------
class Scene_Save < Scene_File
  #-----------------------------------------------------------------------------
  # Update the Confirm Window
  #-----------------------------------------------------------------------------
  def update
    if @selection == false
      super
    else
      @command_window.update
      update_command
    end
  end
end
#-------------------------------------------------------------------------------
# Scene_Load:: Create the Update method
#-------------------------------------------------------------------------------
class Scene_Load < Scene_File
  #-----------------------------------------------------------------------------
  # Update the Confirm Window
  #-----------------------------------------------------------------------------
  def update
    if @selection == false
      super
    else
      @command_window.update
      update_command
    end
  end
end
#===============================================================================
#              * This script is not compatible with RMVX *
#===============================================================================
# Written by Synthesize
# Version 1.0.0
#===============================================================================
# Backup Save Files
#===============================================================================