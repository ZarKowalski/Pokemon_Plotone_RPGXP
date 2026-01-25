#===============================================================================
# Functions
#===============================================================================

# Opens your list of active IM conversations
def pbInstantMessages(filter = nil)
    pbFadeOutIn {
        scene = InstantMessagesMenu_Scene.new(filter)
        screen = InstantMessagesMenuScreen.new(scene)
        screen.pbStartScreen
    }
end

# Directly opens a group 
def pbInstantMessagesDirect(group_id, old_scene = nil)
    pbFadeOutIn {
        scene = InstantMessages_Scene.new(group_id, old_scene)
        screen = InstantMessagesScreen.new(scene)
        screen.pbStartScreen
    }
end

# Receive an IM
def pbReceiveIM(conversation_id, silent = false)
    ret = pbPlayerIMSaved.pbReceiveMessage(conversation_id)
    return false unless ret
    convo = pbIMGetConversation(conversation_id)
    se = InstantMessagesSettings::MESSAGE_RECEIVED_SOUND_EFFECT
    unless silent || convo.important
        if defined?(pbAddItemSplash)
            pbAddGenericSplash(_INTL("New message!"), style: :Message)
        else
            pbSEPlay(se)
            pbMessage(_INTL("You received a message!"))
        end
    end
    if convo.important
        pbSEPlay(se)
        pbMessage(_INTL("You received a message!"))
        if InstantMessagesSettings::OPEN_IMPORTANT_MESSAGES_DIRECTLY
            pbInstantMessagesDirect(pbIMGetGroup(convo.group).id)
        else
            pbInstantMessages
        end
    end
    return true
end

def pbPendDelayedIM(conversation_id, steps: InstantMessagesSettings::PASSIVE_STEP_MIN, time: InstantMessagesSettings::PASSIVE_STEP_MIN)
    array = [conversation_id, steps + rand(InstantMessagesSettings::PASSIVE_STEP_VARIATION), time + rand(InstantMessagesSettings::PASSIVE_TIME_VARIATION), pbGetTimeNow]
    $player.im_passive[:PendedDelayed].push(array)
end

def pbPendRandomIM(conversation_id)
    return false if InstantMessagesSettings::PASSIVE_TRIGGERS_RANDOM_POOL.include?(conversation_id) || $player.im_passive[:PendedRandoms].include?(conversation_id)
    $player.im_passive[:PendedRandoms].push([conversation_id])
end

def pbHasReceivedIM?(conversation_id)
    ret = pbPlayerIMSaved.pbHasReceivedMessage?(conversation_id)
    return ret
end

def pbSetIMTheme(color)
    pbPlayerIMSaved.theme_color = color
end

def pbHasUnreadIM?
    ret = pbPlayerIMSaved.pbHasUnreadMessages?
    return ret
end

#===============================================================================
# Menu scene
#===============================================================================
class Window_IM_Menu < Window_DrawableCommand
    attr_accessor :item_max

    def initialize(x, y, width, height, viewport)
        @conversations = []
        super(x, y, width, height, viewport)
        self.windowskin = nil
        @file_location = Essentials::VERSION.include?("21") ? "UI" : "Pictures"
        arrow_file = Essentials::VERSION.include?("21") ? "sel_arrow" : "selarrow"
        @selarrow = AnimatedBitmap.new("Graphics/#{@file_location}/#{arrow_file}")
    end
    
    def conversations=(value)
        @conversations = value
        refresh
    end
    
    def itemCount
        return @conversations.length
    end
    
    def drawItem(index, _count, rect)
        return if index >= self.top_row + self.page_item_max
        rect = Rect.new(rect.x + 16, rect.y, rect.width-16, rect.height)
        group = @conversations[index][1]
        name = group.title

        base = self.baseColor
        shadow = self.shadowColor
        name = "<b>" + name + "</b>" if group.has_unread
        drawFormattedTextEx(self.contents, rect.x ,rect.y + 2, 468, name, base, shadow)
        x_adj = 0
        if InstantMessagesSettings::ALLOW_PINNING 
            x_adj = 30
            if group.pinned
                pbDrawImagePositions(self.contents, [[sprintf("Graphics/UI/Instant Messages/pin"), rect.width - 16, rect.y + 4]]) 
            end
        end
        if group.has_unread
            if group.has_important
                pbDrawImagePositions(self.contents, [[sprintf("Graphics/UI/Instant Messages/important"), rect.width - 16 - x_adj, rect.y + 4]]) 
            else
                pbDrawImagePositions(self.contents, [[sprintf("Graphics/UI/Instant Messages/new"), rect.width - 16 - x_adj, rect.y + 4]]) 
            end
        end
    end
  
    def refresh
        @item_max = itemCount
        dwidth  = self.width - self.borderX
        dheight = self.height - self.borderY
        self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
        self.contents.clear
        for i in 0...@item_max
            next if i < self.top_item || i > self.top_item + self.page_item_max
            drawItem(i, @item_max, itemRect(i))
        end
        drawCursor(self.index, itemRect(self.index)) if itemCount > 0
    end
    
    def update
        super
        @uparrow.x -= 10
        @downarrow.x -= 10
    end
end

class InstantMessagesMenu_Scene
        attr_accessor :sprites

    def initialize(filter = nil)
        @filter = filter
    end

    def pbStartScene

        @sort_method = 0

        pbGetConverstationList

        @sprites = {}
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @base_color = MessageConfig::DARK_TEXT_MAIN_COLOR
        @shadow_color = MessageConfig::DARK_TEXT_SHADOW_COLOR
        # @title_color = MessageConfig::DARK_TEXT_MAIN_COLOR
        # @title_shadow_color = MessageConfig::DARK_TEXT_SHADOW_COLOR
        @title_color = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        @title_shadow_color = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
        @theme = pbPlayerIMSaved.theme_color
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["background"].setBitmap("Graphics/UI/Instant Messages/Themes/#{@theme}/bg_menu")        
        @last_convo =  nil
        @sprites["itemlist"] = Window_IM_Menu.new(22, 28, Graphics.width - 22, Graphics.height - 28, @viewport)
        @sprites["itemlist"].index = 0
        @sprites["itemlist"].baseColor = @base_color
        @sprites["itemlist"].shadowColor = @shadow_color
        @sprites["itemlist"].conversations = @conversation_list
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["overlay"].bitmap)
        textpos = [[InstantMessagesSettings::MESSAGE_LIST_TITLE,Graphics.width / 2, 6, 2, @title_color, @title_shadow_color]]
        if @sprites["itemlist"].item_max == 0
            if @filter
                textpos.push([_INTL("No matching messages found."), Graphics.width / 2, Graphics.height / 2 - 12, 2, @base_color, @shadow_color])
            else
                textpos.push([_INTL("You have no messages."), Graphics.width / 2, Graphics.height / 2 - 12, 2, @base_color, @shadow_color])
            end
        end
        if InstantMessagesSettings::ALLOW_SORTING && @conversation_list.length > 1
            @sprites["sort_button"] = IconSprite.new(0, 0, @viewport)
            @sprites["sort_button"].setBitmap("Graphics/UI/Instant Messages/sort_button")
            @sprites["sort_button"].x = 4
            @sprites["sort_button"].y = 6
            # @sprites["sort_button"].x = (Graphics.width - @sprites["sort_button"].width) / 2
            # @sprites["sort_button"].y = Graphics.height - @sprites["sort_button"].height - 2
        end

        if InstantMessagesSettings::ALLOW_PINNING && @conversation_list.length > 0
            @sprites["pin_button"] = IconSprite.new(0, 0, @viewport)
            @sprites["pin_button"].setBitmap("Graphics/UI/Instant Messages/pin_button")
            @sprites["pin_button"].x = Graphics.width - @sprites["pin_button"].width - 4
            @sprites["pin_button"].y = 6
            # @sprites["pin_button"].x = Graphics.width * 3 / 4 # - @sprites["pin_button"].width / 2
            # @sprites["pin_button"].y = Graphics.height - @sprites["pin_button"].height - 2
            pbSortConversations 
        end

        pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def pbScene
        loop do
            selected = @sprites["itemlist"].index
            @sprites["itemlist"].active = true
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::BACK)
                if pbCheckForImportant
                    pbMessage(_INTL("You should view your important messages!"))
                else
                    pbPlayCloseMenuSE
                    break
                end
            elsif Input.trigger?(Input::USE)
                if @conversation_list.length == 0
                    #pbPlayBuzzerSE
                else
                    pbPlayDecisionSE
                    pbInstantMessagesDirect(@conversation_list[selected][0], self)
                    #@sprites["itemlist"].refresh
                end
            elsif Input.trigger?(Input::ACTION) && InstantMessagesSettings::ALLOW_PINNING && @conversation_list.length > 0
                pbPlayDecisionSE
                @conversation_list[selected][1].toggle_pin
                pbSortConversations
            elsif Input.trigger?(Input::SPECIAL) && InstantMessagesSettings::ALLOW_SORTING && @conversation_list.length > 1
                commands = [_INTL("Sort by Newest First"),_INTL("Sort by Unread First"),_INTL("Sort Alphabetically")]
                ret = pbShowCommands(nil, commands, -1, @sort_method)
                if ret >= 0 && ret != @sort_method
                    pbPlayDecisionSE
                    @sort_method = ret
                    pbSortConversations
                end
            end
        end
    end

    def pbSortConversations
        if InstantMessagesSettings::ALLOW_PINNING
            case @sort_method
            when 0 # Newest First, default
                @conversation_list.sort_by! { |c| [c[1].pinned ? 1 : 0, c[1].last_received, c[1].title] }
                @conversation_list.reverse!
            when 1 # Unread First
                @conversation_list.sort_by! { |c| [c[1].pinned ? 0 : 1, c[1].has_unread ? 0 : 1, c[1].title] }
            when 2 # Sort Alphabetically
                @conversation_list.sort_by! { |c| [c[1].pinned ? 0 : 1, c[1].title] }
            end
        else
            case @sort_method
            when 0 # Newest First, default
                @conversation_list.sort! { |a, b| a[1].last_received <=> b[1].last_received}
                @conversation_list.reverse!
            when 1 # Unread First
                @conversation_list.sort_by! { |c| c[1].has_unread ? 0 : 1 }
            when 2 # Sort Alphabetically
                @conversation_list.sort! { |a, b| a[1].title <=> b[1].title}
            end
        end
        @sprites["itemlist"].refresh
    end

    def pbGetConverstationList
        @conversation_list = []
        pbPlayerIMSaved.saved_messages.each do |key, value| 
            if @filter && @filter[0] == :Contact
                next unless value.group_data.members.has_value?(@filter[1])
            end
            @conversation_list.push([key, value]) 
        end
    end

    def pbCheckForImportant
        @conversation_list.each do |convo|
            return true if convo[1].has_unread && convo[1].has_important
        end
        return false
    end

    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites) { pbUpdate }
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
    end

end

class InstantMessagesMenuScreen
    def initialize(scene)
        @scene = scene
    end

    def pbStartScreen
        @scene.pbStartScene
        @scene.pbScene
        @scene.pbEndScene
    end
end

#===============================================================================
# Messages scene
#===============================================================================
class InstantMessages_Scene
    attr_accessor :theme

    def initialize(group_id, old_scene = nil)
        @group = pbPlayerIMSaved.saved_messages[group_id]
        @old_scene = old_scene
    end

    def pbStartScene
        @members = @group.member_data
        
        @old_texts = []
        @old_convos = []
        @old_convos_timestamps = []
        @unread_convos = []
        @texts = []
        @texts_linked_convos = []
        @new_convos_timestamps = []
        @texts_code_to_execute = []
        @group.convo_list.each do |conversation|
            if conversation.read && !@group.hide_old
                ts_index = @old_texts.length
                @old_convos_timestamps[ts_index] = conversation.received_time || nil
                @old_convos.push(conversation)
                @old_texts += conversation.messages
            else
                ts_index = @texts.length
                @new_convos_timestamps[ts_index] = conversation.received_time || nil
                @unread_convos.push(conversation)
                conversation.messages.each do |message|
                    @texts.push(message)
                    @texts_linked_convos.push(conversation)
                end
            end
        end
        
        @max_texts = @texts.length
        @only_old = @max_texts <= 0
        @player_bubble = InstantMessagesSettings::PLAYER_BUBBLE_COLOR || "White"
        @player_picture = "Graphics/UI/Instant Messages/Characters/Player_#{$player.character_ID}#{($player.outfit > 0 ? "_#{$player.outfit}" : "")}"
        @picture_alignment = InstantMessagesSettings::PICTURE_ALIGNMENT
        @theme = pbPlayerIMSaved.theme_color

        @max_width = 338
        @show_index = 0
        @pause_time = pbTXWSecondsToFrameConvert(1.5)
        @system_pause_time = pbTXWSecondsToFrameConvert(0.5)
        @speed_up = false
        @scroll_rate = 32
        @timer = 0
        @typing_timer = 0
        @sprites = {}
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @viewport2 = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport2.z = 99999
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["background"].setBitmap("Graphics/UI/Instant Messages/Themes/#{@theme}/bg")
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        @sprites["top_cover"] = IconSprite.new(0, 0, @viewport2)
        @sprites["top_cover"].setBitmap("Graphics/UI/Instant Messages/Themes/#{@theme}/top_cover")
        @sprites["top_cover"].y = 0
        @sprites["bottom_cover"] = IconSprite.new(0, 0, @viewport2)
        @sprites["bottom_cover"].setBitmap("Graphics/UI/Instant Messages/Themes/#{@theme}/bottom_cover")
        @sprites["bottom_cover"].y = Graphics.height - @sprites["bottom_cover"].height
        
        @sprites["playerreplypicture"] = IconSprite.new(0, 0, @viewport)
        @sprites["playerreplypicture"].setBitmap(@player_picture)
        @sprites["playerreplypicture"].visible = false
        @sprites["overlay_bottom"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport2)
        @sprites["overlay_title"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport2)
        if InstantMessagesSettings::SHOW_CLOSE_BUTTON
            @sprites["closebutton"] = IconSprite.new(4, 4, @viewport2)
            @sprites["closebutton"].setBitmap("Graphics/UI/Instant Messages/close")
            @sprites["closebutton"].opacity = 100
            #@sprites["closebutton"].visible = false
        end
        if InstantMessagesSettings::ALLOW_FAST_FORWARD
            @sprites["ffwdbutton"] = IconSprite.new(Graphics.width - 50, Graphics.height - 30, @viewport2)
            @sprites["ffwdbutton"].setBitmap("Graphics/UI/Instant Messages/ffwd")
            @sprites["ffwdbutton"].opacity = 100
            #@sprites["ffwdbutton"].visible = false
        end
        @top_margin = @sprites["top_cover"].height - 6
        @side_margin = 20
        @bottom_margin = @sprites["bottom_cover"].y + 6

        pbRefreshGroupTitle
        
        # # Precreate old texts
        # @old_texts = []
        # @old_convos.each do |old| 
        #      @old_texts += old.messages
        # end
        @previously_saved_y = nil
        @old_texts.length.times do |i|
            if @old_texts[i][0] > 0
                bubble_color = @members[@old_texts[i][0]].bubble
            elsif @old_texts[i][0] < 0
                bubble_color = InstantMessagesSettings::SYSTEM_BUBBLE_COLOR
                skip_picture = true
            else
                bubble_color = @player_bubble
            end

            #replace choice arrays with the one that was selected
            case @old_texts[i][1]
            when :Text, :RedoText
                if @old_texts[i][2].is_a?(Array)
                    if @old_texts[i][4]
                        @old_texts[i][2] = @old_texts[i][2][@old_texts[i][4]]
                    else
                        @old_texts[i][2] = @old_texts[i][2][0]
                    end
                    pbRunTextThroughReplacement(@old_texts[i][2])
                else
                    pbRunTextThroughReplacement(@old_texts[i][2])
                end
            when :Leave
                text_to_show = _INTL("{1} left.", @members[@old_texts[i][2]].name)
            when :Enter
                text_to_show = _INTL("{1} entered.", @members[@old_texts[i][2]].name)
            when :GroupName
                text_to_show = _INTL("Chat name changed to: {1}", @old_texts[i][2])
            when :Picture
                @sprites["old_text_picture#{i}"] = IconSprite.new(0, 0, @viewport)
                @sprites["old_text_picture#{i}"].setBitmap("Graphics/UI/Instant Messages/Pictures/#{@old_texts[i][2]}")
                @sprites["old_text_picture#{i}"].visible = false
                height_override =  @sprites["old_text_picture#{i}"].height
                width_override = @sprites["old_text_picture#{i}"].width
            end

            # Added for proper text replacement
            @sprites["oldtext#{i}"] = Window_AdvancedTextPokemonMessages.new(text_to_show || @old_texts[i][2])
            @sprites["oldtext#{i}"].setSkin("Graphics/UI/Instant Messages/Bubbles/#{bubble_color}")
            @sprites["oldtext#{i}"].resizeToFit(@sprites["oldtext#{i}"].text, @max_width)
            @sprites["oldtext#{i}"].text = "" if @sprites["old_text_picture#{i}"]
            @sprites["oldtext#{i}"].viewport = @viewport
            @sprites["oldtext#{i}"].x = (@old_texts[i][0] != 0 ? @side_margin : Graphics.width - @side_margin - @sprites["oldtext#{i}"].width)
            @sprites["oldtext#{i}"].y = (@sprites["oldtext#{i-1}"] ? @sprites["oldtext#{i-1}"].y + @sprites["oldtext#{i-1}"].height : @top_margin)
            if InstantMessagesSettings::SHOW_TIME_STAMPS && @old_convos_timestamps[i]
                @sprites["oldmessagetimestamp#{i}"] = InstantMessageDivider.new(0, 0, pbConvertTimeStamp(@old_convos_timestamps[i]), false, self, @viewport)
                @sprites["oldmessagetimestamp#{i}"].y = @sprites["oldtext#{i}"].y
                @sprites["oldmessagetimestamp#{i}"].visible = true 
                @sprites["oldtext#{i}"].y += @sprites["oldmessagetimestamp#{i}"].height
            end
            if @sprites["old_text_picture#{i}"]
                sides = @sprites["oldtext#{i}"].edges
                @sprites["old_text_picture#{i}"].x = @sprites["oldtext#{i}"].x + sides[1].width
                @sprites["old_text_picture#{i}"].y = @sprites["oldtext#{i}"].y + sides[0].height
                @sprites["old_text_picture#{i}"].z = @sprites["oldtext#{i}"].z + 1
                @sprites["oldtext#{i}"].height = height_override + sides[0].height + sides[3].height
                @sprites["oldtext#{i}"].width = width_override + sides[1].width + sides[2].width
            end
            @sprites["oldtext#{i}"].orig_y = @sprites["oldtext#{i}"].y
            @sprites["oldtext#{i}"].visible = true
            @sprites["old_text_picture#{i}"]&.visible = true

            # Make picture appear for first unique message
            unless skip_picture
                if @old_texts[i][0] != 0 && (@sprites["oldtext#{i-1}"].nil? || (@old_texts[i-1][0] != @old_texts[i][0]))
                    @sprites["oldpicture#{i}"] = IconSprite.new(0, 0, @viewport)
                    @sprites["oldpicture#{i}"].setBitmap("Graphics/UI/Instant Messages/Characters/#{@members[@old_texts[i][0]].image}")
                    @sprites["oldpicture#{i}"].x = @sprites["oldtext#{i}"].x + @sprites["oldtext#{i}"].width + 4
                    @sprites["oldpicture#{i}"].y = @sprites["oldtext#{i}"].y + get_y_adj(@sprites["oldtext#{i}"].height, @sprites["oldpicture#{i}"].height)
                    @sprites["oldpicture#{i}"].visible = true
                elsif @old_texts[i][0] == 0 && (@sprites["oldtext#{i-1}"].nil? || (@old_texts[i-1][0] != @old_texts[i][0]))
                    @sprites["oldpicture#{i}"] = IconSprite.new(0, 0, @viewport)
                    @sprites["oldpicture#{i}"].setBitmap(@player_picture)
                    @sprites["oldpicture#{i}"].x = @sprites["oldtext#{i}"].x - @sprites["oldpicture#{i}"].width - 4
                    @sprites["oldpicture#{i}"].y = @sprites["oldtext#{i}"].y + get_y_adj(@sprites["oldtext#{i}"].height, @sprites["oldpicture#{i}"].height)
                    @sprites["oldpicture#{i}"].visible = true
                end 
            end
            if i == @old_texts.length - 1
                if @max_texts > 0
                    @sprites["unreaddivider"] = InstantMessageDivider.new(0, 0, _INTL("Unread"), true, self, @viewport)
                    @sprites["unreaddivider"].y = @sprites["oldtext#{i}"].y + @sprites["oldtext#{i}"].height
                    @sprites["unreaddivider"].visible = true
                    @previously_saved_y_end = @sprites["unreaddivider"].y + @sprites["unreaddivider"].height 
                    # if InstantMessagesSettings::SHOW_TIME_STAMPS
                    #     @sprites["newmessagetimestamp0"] = InstantMessageDivider.new(0, 0, @new_convos_timestamps[0].to_s, false, self, @viewport)
                    #     @sprites["newmessagetimestamp0"].y = @previously_saved_y_end
                    #     @sprites["newmessagetimestamp0"].visible = true 
                    #     @previously_saved_y_end = @sprites["newmessagetimestamp0"].y + @sprites["newmessagetimestamp0"].height
                    # else
                    #     @sprites["oldmessagedivider"] = IconSprite.new(0, 0, @viewport)
                    #     @sprites["oldmessagedivider"].setBitmap("Graphics/UI/Instant Messages/Themes/#{@theme}/divider")
                    #     @sprites["oldmessagedivider"].y = @sprites["oldtext#{i}"].y + @sprites["oldtext#{i}"].height
                    #     @sprites["oldmessagedivider"].visible = true
                    #     @previously_saved_y_end = @sprites["oldmessagedivider"].y + @sprites["oldmessagedivider"].height 
                    # end
                else
                    @previously_saved_y_end = @sprites["oldtext#{i}"].y + @sprites["oldtext#{i}"].height 
                end
                last_text = @sprites["oldtext#{i}"]
                if last_text.y + last_text.height > @bottom_margin
                    diff = last_text.y + last_text.height - @bottom_margin
                    pbMoveUp(value: diff)
                end

            end
        end

        if @max_texts > 0
            @retype = []
            @max_texts.times do |i|
                if @texts[i][0] > 0
                    bubble_color = @members[@texts[i][0]].bubble
                elsif @texts[i][0] < 0
                    bubble_color = InstantMessagesSettings::SYSTEM_BUBBLE_COLOR
                    skip_picture = true
                else
                    bubble_color = @player_bubble
                end

                # Added for proper text replacement
                case @texts[i][1]
                when :Text, :RedoText
                    if @texts[i][2].is_a?(Array)
                        @texts[i][2].each do |txt|
                            pbRunTextThroughReplacement(txt)
                        end
                        text_to_show = @texts[i][2][0]
                    else
                        pbRunTextThroughReplacement(@texts[i][2])
                    end
                    @retype[i] = true if @texts[i][1] == :RedoText
                when :Leave
                    text_to_show = _INTL("{1} left.", @members[@texts[i][2]].name)
                when :Enter
                    text_to_show = _INTL("{1} entered.", @members[@texts[i][2]].name)
                when :GroupName
                    @texts_code_to_execute[i] = [@texts[i][1], @texts[i][2]]
                    text_to_show = _INTL("Chat name changed to: {1}", @texts[i][2] || @group.original_title)
                when :Picture
                    @sprites["text_picture#{i}"] = IconSprite.new(0, 0, @viewport)
                    @sprites["text_picture#{i}"].setBitmap("Graphics/UI/Instant Messages/Pictures/#{@texts[i][2]}")
                    @sprites["text_picture#{i}"].visible = false
                    height_override =  @sprites["text_picture#{i}"].height
                    width_override = @sprites["text_picture#{i}"].width
                end
                @sprites["text#{i}"] = Window_AdvancedTextPokemonMessages.new(text_to_show || @texts[i][2])
                @sprites["text#{i}"].setSkin("Graphics/UI/Instant Messages/Bubbles/#{bubble_color}")
                @sprites["text#{i}"].resizeToFit(@sprites["text#{i}"].text, @max_width)
                @sprites["text#{i}"].text = "" if @sprites["text_picture#{i}"]
                @sprites["text#{i}"].viewport = @viewport
                @sprites["text#{i}"].x = (@texts[i][0] != 0 ? @side_margin : Graphics.width - @side_margin - @sprites["text#{i}"].width)
                if @previously_saved_y_end
                    @sprites["text#{i}"].y = @previously_saved_y_end
                    @previously_saved_y_end = nil
                else
                    @sprites["text#{i}"].y = (@sprites["text#{i-1}"] ? @sprites["text#{i-1}"].y + @sprites["text#{i-1}"].height : @top_margin)
                end
                if InstantMessagesSettings::SHOW_TIME_STAMPS && ((i > 0 && @texts_linked_convos[i-1] != @texts_linked_convos[i] && @texts_linked_convos[i-1].instant) || i == 0)
                    @sprites["newmessagetimestamp#{i}"] = InstantMessageDivider.new(0, 0, pbConvertTimeStamp(@new_convos_timestamps[i]), false, self, @viewport)
                    @sprites["newmessagetimestamp#{i}"].y = @sprites["text#{i}"].y
                    @sprites["newmessagetimestamp#{i}"].visible = true 
                    @sprites["text#{i}"].y += @sprites["newmessagetimestamp#{i}"].height
                end
                if @sprites["text_picture#{i}"]
                    sides = @sprites["text#{i}"].edges
                    @sprites["text_picture#{i}"].x = @sprites["text#{i}"].x + sides[1].width
                    @sprites["text_picture#{i}"].y = @sprites["text#{i}"].y + sides[0].height
                    @sprites["text_picture#{i}"].z = @sprites["text#{i}"].z + 1
                    @sprites["text#{i}"].height = height_override + sides[0].height + sides[3].height
                    @sprites["text#{i}"].width = width_override + sides[1].width + sides[2].width
                end
                @sprites["text#{i}"].orig_y = @sprites["text#{i}"].y
                @sprites["text#{i}"].visible = @texts_linked_convos[i].instant #If a convo is instant, it will be already there once created
                @sprites["text_picture#{i}"]&.visible = @sprites["text#{i}"].visible
                # Make picture appear for first unique message
                unless skip_picture
                    if @texts[i][0] != 0 && (@sprites["text#{i-1}"].nil? || (@texts[i-1][0] != @texts[i][0]))
                        @sprites["picture#{i}"] = IconSprite.new(0, 0, @viewport)
                        @sprites["picture#{i}"].setBitmap("Graphics/UI/Instant Messages/Characters/#{@members[@texts[i][0]].image}")
                        @sprites["picture#{i}"].x = @sprites["text#{i}"].x + @sprites["text#{i}"].width + 4
                        @sprites["picture#{i}"].y = @sprites["text#{i}"].y + get_y_adj(@sprites["text#{i}"].height, @sprites["picture#{i}"].height)
                        @sprites["picture#{i}"].visible = @texts_linked_convos[i].instant
                    elsif @texts[i][0] == 0 && (@sprites["text#{i-1}"].nil? || (@texts[i-1][0] != @texts[i][0]))
                        @sprites["picture#{i}"] = IconSprite.new(0, 0, @viewport)
                        @sprites["picture#{i}"].setBitmap(@player_picture)
                        @sprites["picture#{i}"].x = @sprites["text#{i}"].x - @sprites["picture#{i}"].width - 4
                        @sprites["picture#{i}"].y = @sprites["text#{i}"].y + get_y_adj(@sprites["text#{i}"].height, @sprites["picture#{i}"].height)
                        @sprites["picture#{i}"].visible = @texts_linked_convos[i].instant
                    end
                end
            end
        else
            pbEnableScrolling
        end

        pbSetSystemFont(@sprites["overlay"].bitmap)
        pbFadeInAndShow(@sprites)

    end

    def pbScene
        @allow_scroll = false
        loop do
            Graphics.update
            Input.update
            pbUpdate
            if Input.trigger?(Input::SPECIAL) && InstantMessagesSettings::ALLOW_FAST_FORWARD && !@allow_scroll
                pbToggleFastForward
            elsif Input.trigger?(Input::BACK) && @allow_scroll
                pbPlayCloseMenuSE
                break
            elsif Input.trigger?(Input::USE)

            elsif Input.repeat?(Input::DOWN) && @allow_scroll
                pbMoveUp
            elsif Input.repeat?(Input::JUMPDOWN) && @allow_scroll
                pbMoveUp(true)
            elsif Input.repeat?(Input::UP) && @allow_scroll
                pbMoveDown
            elsif Input.repeat?(Input::JUMPUP) && @allow_scroll
                pbMoveDown(true)
            end
            if check_next_text
                pbEnableScrolling
            end
        end
        @unread_convos.each { |c| c.read = true}
        @group.has_unread = false
        @group.has_important = false
        return
    end

    def get_y_adj(text_height, picture_height)
        y_adj = 0
        case @picture_alignment
        when 1
            y_adj = text_height - picture_height - 6
        when 2
            y_adj = (text_height - picture_height) / 2
        else
            y_adj = 4
        end
        return y_adj
    end

    def check_next_text
        return false if @allow_scroll
        return true if @texts[@show_index].nil?
        show_next_message = false
        pause_time = (@texts[@show_index][0] > 0 && !@texts[@show_index][3].nil?) ? pbTXWSecondsToFrameConvert(@texts[@show_index][3]) : @pause_time 
        if @texts_linked_convos[@show_index].instant
            check_next_text_y
            @show_index += 1
            return false
        end
        @sprites["overlay_bottom"].bitmap.clear
        if @show_index == 0 # First message of the chat
            pbMakeMessageVisible(@sprites["text#{@show_index}"], @sprites["picture#{@show_index}"], @show_index)
            check_next_text_y #Do this before adding to index, so it adjusts the first message if long or after old texts
            pbSEPlay(InstantMessagesSettings::MESSAGE_BUBBLE_SOUND_EFFECT, 100)
            @show_index += 1
        elsif @texts[@show_index][0] < 0 # System Text
            skip_typing = true
            pause_time = pbTXWSecondsToFrameConvert(@texts[@show_index][3]) || @system_pause_time
            show_next_message = true if @timer > pause_time
        elsif @texts[@show_index][0] == 0 #Player Choice
            pbTXWSecondsToFrameConvert(1).times do
                Graphics.update
                Input.update
                pbUpdate
            end
            if @texts[@show_index][2].is_a?(Array)
                cmds = @texts[@show_index][2]
                choice = pbDisplayForcedCommands(nil,cmds)
                @texts[@show_index][4] = choice #Add choice selection to index 4
                if @texts[@show_index][3] #saves value to variable
                    val = @texts[@show_index][3]
                    if val.is_a?(String) #Run eval
                        val.gsub!(/{VALUE}/i, choice.to_s)
                        eval(val)
                    elsif val.is_a?(Integer) #game variable
                        pbSet(val, choice)
                    end
                end
                @sprites["text#{@show_index}"].text = @texts[@show_index][2][choice]
            else
                choice = 0
                @texts[@show_index][4] = choice
                if @texts[@show_index][3] 
                    val = @texts[@show_index][3]
                    if val.is_a?(String) #Run eval
                        val.gsub!(/{VALUE}/i, choice.to_s)
                        eval(val)
                    elsif val.is_a?(Integer) #game variable
                        pbSet(val, choice)
                    end
                end
                @sprites["text#{@show_index}"].text = @texts[@show_index][2]
            end
            @sprites["text#{@show_index}"].resizeToFit(@sprites["text#{@show_index}"].text, @max_width)
            @sprites["text#{@show_index}"].x = Graphics.width - @side_margin - @sprites["text#{@show_index}"].width
            @sprites["text#{@show_index}"].y = (@sprites["text#{@show_index-1}"] ? @sprites["text#{@show_index-1}"].y + @sprites["text#{@show_index-1}"].height : @top_margin)
            @sprites["text#{@show_index}"].orig_y = @sprites["text#{@show_index}"].y
            if @sprites["picture#{@show_index}"]
                @sprites["picture#{@show_index}"].x = @sprites["text#{@show_index}"].x - @sprites["picture#{@show_index}"].width - 4
                @sprites["picture#{@show_index}"].y = @sprites["text#{@show_index}"].y + get_y_adj(@sprites["text#{@show_index}"].height, @sprites["picture#{@show_index}"].height)
            end
            @choice_made = choice

            #Adjust the next text to get the proper height updates
            if @sprites["text#{@show_index + 1}"]
                @sprites["text#{@show_index + 1}"].y = (@sprites["text#{@show_index}"] ? @sprites["text#{@show_index}"].y + @sprites["text#{@show_index}"].height : @top_margin)
                @sprites["text#{@show_index + 1}"].orig_y = @sprites["text#{@show_index + 1}"].y
                if @sprites["picture#{@show_index + 1}"]
                    @sprites["picture#{@show_index + 1}"].x = @sprites["text#{@show_index + 1}"].x + @sprites["text#{@show_index + 1}"].width + 4
                    @sprites["picture#{@show_index + 1}"].y = @sprites["text#{@show_index + 1}"].y + get_y_adj(@sprites["text#{@show_index + 1}"].height, @sprites["picture#{@show_index + 1}"].height)
                end
            end
			
            show_next_message = true
        elsif @timer >= pause_time + (skip_typing ? 0 : pbGetTypingTime )
            if @retype[@show_index]
                @timer = 0
                @retype[@show_index] = nil
                return false
            end
            if @choice_made #Player made a choice before, react to it.
                if @texts[@show_index][2].is_a?(Array)
                    @texts[@show_index][4] = @choice_made  #Add choice selection to index 4
                    @sprites["text#{@show_index}"].text = @texts[@show_index][2][@choice_made]
                    @sprites["text#{@show_index}"].resizeToFit(@sprites["text#{@show_index}"].text, @max_width)
                    @sprites["text#{@show_index}"].y = (@sprites["text#{@show_index-1}"] ? @sprites["text#{@show_index-1}"].y + @sprites["text#{@show_index-1}"].height : @top_margin)
                    @sprites["text#{@show_index}"].orig_y = @sprites["text#{@show_index}"].y
                    if @sprites["picture#{@show_index}"]
                        @sprites["picture#{@show_index}"].x = @sprites["text#{@show_index}"].x + @sprites["text#{@show_index}"].width + 4
                        @sprites["picture#{@show_index}"].y = @sprites["text#{@show_index}"].y + get_y_adj(@sprites["text#{@show_index}"].height, @sprites["picture#{@show_index}"].height)
                    end
                end
            end

            #Adjust the next text to get the proper height updates
            if @sprites["text#{@show_index + 1}"]
                @sprites["text#{@show_index + 1}"].y = (@sprites["text#{@show_index}"] ? @sprites["text#{@show_index}"].y + @sprites["text#{@show_index}"].height : @top_margin)
                @sprites["text#{@show_index + 1}"].orig_y = @sprites["text#{@show_index + 1}"].y
                if @sprites["picture#{@show_index + 1}"]
                    @sprites["picture#{@show_index + 1}"].x = @sprites["text#{@show_index + 1}"].x + @sprites["text#{@show_index + 1}"].width + 4
                    @sprites["picture#{@show_index + 1}"].y = @sprites["text#{@show_index + 1}"].y + get_y_adj(@sprites["text#{@show_index + 1}"].height, @sprites["picture#{@show_index + 1}"].height)
                end
            end

            show_next_message = true
        elsif skip_typing.nil? && @show_index > 0 && @timer > pause_time
            typing_text = _INTL("{1} is typing", @members[@texts[@show_index][0]].name)
            if @typing_timer < pbTXWSecondsToFrameConvert(1) / 4
            elsif @typing_timer < pbTXWSecondsToFrameConvert(1) / 2
                typing_text += "."
            elsif @typing_timer < pbTXWSecondsToFrameConvert(3) / 4
                typing_text += ".."
            else
                typing_text += "..."
            end
            # case @typing_timer
            # when 10..19
            #     typing_text += "."
            # when 20..29
            #     typing_text += ".."
            # when 30..39
            #     typing_text += "..."            
            # end
            pbSetSmallFont(@sprites["overlay_bottom"].bitmap)
            textpos = []
            textpos.push([typing_text, 80, Graphics.height - 20, 0, MessageConfig::LIGHT_TEXT_MAIN_COLOR, MessageConfig::LIGHT_TEXT_SHADOW_COLOR])
            pbDrawTextPositions(@sprites["overlay_bottom"].bitmap,textpos)
            @typing_timer += 1
            @typing_timer += 1 if @speed_up
            @typing_timer = 0 if @typing_timer >= pbTXWSecondsToFrameConvert(1)
        end
        if show_next_message
            check_next_text_y
            pbMakeMessageVisible(@sprites["text#{@show_index}"], @sprites["picture#{@show_index}"], @show_index)
            pbSEPlay(InstantMessagesSettings::MESSAGE_BUBBLE_SOUND_EFFECT, 100)
            @show_index += 1
            @timer = 0
            @typing_timer = 0
            return true if @show_index >= @max_texts
        end
        @timer += 1
        @timer += 1 if @speed_up
        return false
    end

    def check_next_text_y
        next_text = @sprites["text#{@show_index}"]
        if next_text.y + next_text.height > @bottom_margin
            diff = next_text.y + next_text.height - @bottom_margin
            pbMoveUp(value: diff)
        end
    end

    def pbConvertTimeStamp(instance)
        now = pbGetTimeNow
        diff = now - instance
        if diff < 86400 && now.day == instance.day # now.strftime("%m/%d/%Y") == instance.strftime("%m/%d/%Y")
            val = _INTL("Today at {1}", instance.strftime("%I:%M %p"))
        elsif diff < 86400 * 2 && (now - 86400).day == instance.day
            val = _INTL("Yesterday at {1}", instance.strftime("%I:%M %p"))
        else 
            days = (diff / 86400).floor
            if days >= 7
                val = _INTL("{1} days ago at {2}", days.to_s_formatted, instance.strftime("%I:%M %p"))
            else
                case instance.wday
                when 0
                    wd = "Sun"
                when 1
                    wd = "Mon"
                when 2
                    wd = "Tue"
                when 3
                    wd = "Wed"
                when 4
                    wd = "Thur"
                when 5
                    wd = "Fri"
                when 6
                    wd = "Sat"
                end
                val = _INTL("{1} at {2}", wd, instance.strftime("%I:%M %p"))
            end
        end
        return val
    end

    def pbGetTypingTime
        text = @sprites["text#{@show_index}"].text.clone
        text.gsub!(/\<(\w+)\>/i,   "")
        text.gsub!(/\<\/(\w+)\>/i,   "")
        text.gsub!(/\<icon\=(\w+)\>/i,   "...")       
        return text.length * pbTXWSecondsToFrameConvert(1)/20 
    end

    def pbMakeMessageVisible(text_sprite, picture_sprite, index)
        text_sprite.visible = true
        picture_sprite&.visible = true# if picture_sprite
        if @sprites["text_picture#{index}"]
            @sprites["text_picture#{index}"].y = text_sprite.y + text_sprite.edges[0].height
            @sprites["text_picture#{index}"].visible = true
        end
        pbExecuteCode(index)
    end

    def pbRunTextThroughReplacement(text)
        text.gsub!(/\\pn/i,  $player.name) if $player
        text.gsub!(/\\pm/i,  _INTL("${1}", $player.money.to_s_formatted)) if $player
        text.gsub!(/\\n/i,   "\n")
        text.gsub!(/\\\[([0-9a-f]{8,8})\]/i) { "<c2=" + $1 + ">" }
        text.gsub!(/\\pg/i,  "\\b") if $player&.male?
        text.gsub!(/\\pg/i,  "\\r") if $player&.female?
        text.gsub!(/\\pog/i, "\\r") if $player&.male?
        text.gsub!(/\\pog/i, "\\b") if $player&.female?
        text.gsub!(/\\pg/i,  "")
        text.gsub!(/\\pog/i, "")
        text.gsub!(/\\b/i,   "<c3=3050C8,D0D0C8>")
        text.gsub!(/\\r/i,   "<c3=E00808,D0D0C8>")
        loop do
            last_text = text.clone
            text.gsub!(/\\v\[([0-9]+)\]/i) { $game_variables[$1.to_i] }
            break if text == last_text
        end
        return text
    end

    def pbMoveUp(large = false, value: nil)
        move_val = value || @scroll_rate * (large ? 5 : 1)
        if @only_old
            last_text = @sprites["oldtext#{@old_texts.length - 1}"]
        else
            last_text = @sprites["text#{@max_texts - 1}"]
        end
        return if last_text.nil?
        if last_text.y + last_text.height <= @bottom_margin
            return
        elsif last_text.y + last_text.height - move_val < @bottom_margin
            diff = last_text.y + last_text.height - move_val - @bottom_margin
            move_val += diff
        end
        @old_texts.length.times do |j|
            @sprites["oldtext#{j}"].y -= move_val
            @sprites["oldpicture#{j}"]&.y -= move_val 
            @sprites["old_text_picture#{j}"]&.y -= move_val
            @sprites["oldmessagetimestamp#{j}"]&.y -= move_val
        end
        @sprites["oldmessagedivider"]&.y -= move_val 
        @sprites["unreaddivider"]&.y -= move_val 
        @max_texts.times do |i|
            @sprites["text#{i}"].y -= move_val
            @sprites["picture#{i}"]&.y -= move_val 
            @sprites["text_picture#{i}"]&.y -= move_val
            @sprites["newmessagetimestamp#{i}"]&.y -= move_val
        end
    end

    def pbMoveDown(large = false, value: nil)
        move_val = value || @scroll_rate * (large ? 5 : 1)
        if @only_old
            first_text = @sprites["oldtext0"]
        else
            first_text = @sprites["text0"]
        end
        return if first_text.nil?
        if first_text.y == first_text.orig_y
            return
        elsif first_text.y + move_val > first_text.orig_y
            diff = first_text.y + move_val - first_text.orig_y
            move_val -= diff
        end
        @old_texts.length.times do |j|
            @sprites["oldtext#{j}"].y += move_val
            @sprites["oldpicture#{j}"]&.y += move_val 
            @sprites["old_text_picture#{j}"]&.y += move_val
            @sprites["oldmessagetimestamp#{j}"]&.y += move_val
        end
        @sprites["oldmessagedivider"]&.y += move_val 
        @sprites["unreaddivider"]&.y += move_val 
        @max_texts.times do |i|
            @sprites["text#{i}"].y += move_val
            @sprites["picture#{i}"]&.y += move_val 
            @sprites["text_picture#{i}"]&.y += move_val
            @sprites["newmessagetimestamp#{i}"]&.y += move_val
        end
    end

    def pbEnableScrolling
        @allow_scroll = true
        @sprites["closebutton"]&.opacity = 255
        pbToggleFastForward(false)
        #@sprites["closebutton"]&.visible = true
    end

    def pbToggleFastForward(value = nil)
        return if !InstantMessagesSettings::ALLOW_FAST_FORWARD
        if value.nil?
            @speed_up = !@speed_up
        else
            @speed_up = value
        end
        #@sprites["ffwdbutton"].visible = @speed_up
        @sprites["ffwdbutton"].opacity = (@speed_up ? 255 : 100)
    end

    def pbEndScene
        pbFadeOutAndHide(@sprites)
        pbDisposeSpriteHash(@sprites)
        @viewport.dispose
        @viewport2.dispose
        @old_scene.sprites["itemlist"].refresh if @old_scene && @old_scene.sprites["itemlist"]
    end

    def pbExecuteCode(index)
        array = @texts_code_to_execute[index]
        return unless array
        id = array[0]
        val = array[1]
        case id
        when :GroupName
            if val
                @group.title = val
            else
                @group.reset_title
            end
            pbRefreshGroupTitle
        end
    end

    def pbRefreshGroupTitle
        @sprites["overlay_title"].bitmap.clear
        show_prefix = InstantMessagesSettings::SHOW_CONVERSATION_PREFIX
        case show_prefix
        when 1, true
            prefix = InstantMessagesSettings::CONVERSATION_PREFIX + " "
        when 2
            if @members.length > 2
                prefix = ""
            else
                prefix = InstantMessagesSettings::CONVERSATION_PREFIX + " "
            end
        else
            prefix = ""
        end
        pbSetSmallFont(@sprites["overlay_title"].bitmap)
        textpos = [[_INTL("{1}{2}", prefix, @group.title), Graphics.width / 2, 4, 2, MessageConfig::LIGHT_TEXT_MAIN_COLOR, MessageConfig::LIGHT_TEXT_SHADOW_COLOR]]
        pbDrawTextPositions(@sprites["overlay_title"].bitmap,textpos)
    end
  
    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def pbDisplayForcedCommands(text, commands) #TDW Added
        ret = -1
        using(cmdwindow = Window_CommandPokemonMessages.new(commands)) {
            cmdwindow.visible = false
            @sprites["playerreplypicture"].visible = false
            player_bubble_color = InstantMessagesSettings::PLAYER_BUBBLE_COLOR || "White"
            cmdwindow.setSkin("Graphics/UI/Instant Messages/Bubbles/#{player_bubble_color}")
            cmdwindow.resizeToFit(commands)
            cmdwindow.x = Graphics.width - cmdwindow.width - @side_margin
            cmdwindow.y = @bottom_margin - cmdwindow.height
            @sprites["playerreplypicture"].x = cmdwindow.x - @sprites["playerreplypicture"].width - 4
            case @picture_alignment
            when 1
                y_adj = cmdwindow.height - @sprites["playerreplypicture"].height - 6
            when 2
                y_adj = (cmdwindow.height - @sprites["playerreplypicture"].height) / 2
            else
                y_adj = 4
            end
            @sprites["playerreplypicture"].y = cmdwindow.y + y_adj
            if @sprites["text#{@show_index-1}"]
                last_text = @sprites["text#{@show_index-1}"]
                if last_text.y + last_text.height > cmdwindow.y
                    diff = last_text.y + last_text.height - cmdwindow.y
                    pbMoveUp(value: diff)
                end
            end
            cmdwindow.z = @viewport.z + 1
            loop do
                Graphics.update
                Input.update
                cmdwindow.visible = true
                @sprites["playerreplypicture"].visible = true
                cmdwindow.update
                self.pbUpdate
                if Input.trigger?(Input::USE) 
                    ret = cmdwindow.index
                    @sprites["playerreplypicture"].visible = false
                    break
                elsif Input.trigger?(Input::SPECIAL) && InstantMessagesSettings::ALLOW_FAST_FORWARD && !@allow_scroll
                    pbToggleFastForward
                end
            end
        }
        return ret
    end

end

#===============================================================================
# Messages screen
#===============================================================================
class InstantMessagesScreen
    attr_reader :scene

    def initialize(scene)
        @scene = scene
    end

    def pbStartScreen
        @scene.pbStartScene
        ret = @scene.pbScene
        @scene.pbEndScene
        return ret
    end

    def pbUpdate
        @scene.update
    end

    def pbRefresh
        @scene.pbRefresh
    end

    def pbDisplay(text)
        @scene.pbDisplay(text)
    end

    def pbDisplayForcedCommands(text, commands)
        @scene.pbDisplayForcedCommands(text, commands)
    end

    def pbConfirm(text)
        return @scene.pbDisplayConfirm(text)
    end

    def pbShowCommands(helptext, commands, index = 0)
        return @scene.pbShowCommands(helptext, commands, index)
    end

end


class Window_AdvancedTextPokemonMessages < Window_AdvancedTextPokemon
    attr_accessor :orig_y
    #attr_accessor :sidebitmaps

    def edges
        edges = []
        4.times do |i|
            edges.push(@sprites["side#{i}"])
        end
        return edges
    end

end

class Window_CommandPokemonMessages < Window_CommandPokemon

    def drawItem(index, _count, rect)
        pbSetSystemFont(self.contents)
        rect = drawCursor(index, rect)
        if toUnformattedText(@commands[index]).gsub(/\n/, "") == @commands[index]
          # Use faster alternative for unformatted text without line breaks
          pbDrawShadowText(self.contents, rect.x, rect.y + 8, rect.width, rect.height,
                           @commands[index], self.baseColor, self.shadowColor)
        else
          chars = getFormattedText(self.contents, rect.x, rect.y + 8, rect.width, rect.height,
                                   @commands[index], rect.height, true, true)
          drawFormattedChars(self.contents, chars)
        end
    end
    
    # Use v22 code to allow it so emojis can appear in choices.
    def getAutoDims(commands, dims, width = nil)
        rowMax = ((commands.length + self.columns - 1) / self.columns).to_i
        windowheight = (rowMax * self.rowHeight)
        windowheight += self.borderY
        if !width || width < 0
            width = 0
            tmp_bitmap = Bitmap.new(1, 1)
            pbSetSystemFont(tmp_bitmap)
            commands.each do |cmd|
              txt = toUnformattedText(cmd).gsub(/\n/, "")
              txt_width = tmp_bitmap.text_size(txt).width
              check_text = cmd
              while check_text[FORMATREGEXP]
                if $~[2].downcase == "icon" && $~[3]
                  check_text = $~.post_match
                  filename = $~[4].sub(/\s+$/, "")
                  temp_graphic = Bitmap.new("Graphics/Icons/#{filename}")
                  txt_width += temp_graphic.width
                  temp_graphic.dispose
                else
                  check_text = $~.post_match
                end
              end
              width = [width, txt_width].max
            end
            # one 16 to allow cursor
            width += 16 + 16 + (Essentials::VERSION.include?("21") ? SpriteWindow_Base::TEXT_PADDING : SpriteWindow_Base::TEXTPADDING)
            tmp_bitmap.dispose
          end
        # Store suggested width and height of window
        dims[0] = [self.borderX + 1,
                   (width * self.columns) + self.borderX + ((self.columns - 1) * self.columnSpacing)].max
        dims[1] = [self.borderY + 1, windowheight].max
        dims[1] = [dims[1], Graphics.height].min
    end  

    def setSkin(skin)
        super(skin)
        file_location = Essentials::VERSION.include?("21") ? "UI" : "Pictures"
        arrow_name = (Essentials::VERSION.include?("21") ? "sel_arrow" : "selarrow")
        if isDarkWindowskin(self.windowskin)
            @selarrow = AnimatedBitmap.new("Graphics/#{file_location}/#{arrow_name}_white")
        else
            @selarrow = AnimatedBitmap.new("Graphics/#{file_location}/#{arrow_name}")
        end
    end
end

class InstantMessageDivider < IconSprite
    attr_reader :text
  
    def initialize(x, y, text, divider_visible, scene, viewport)
      super(viewport)
      @text = text
      divider_suffix =""
      if ["Unread", "New"].include?(@text)
        divider_suffix ="_unread"
        @text_base_color = MessageConfig::LIGHT_TEXT_MAIN_COLOR
        @text_shadow_color = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
      elsif @text
        divider_suffix ="_text"
        @text_base_color = MessageConfig::DARK_TEXT_MAIN_COLOR
        @text_shadow_color = MessageConfig::DARK_TEXT_SHADOW_COLOR
      end
      @scene = scene
      @viewport = viewport
      @divider_visible = divider_visible
      @sprites = {}
      self.x = x
      self.y = y
      @sprites["bg"] = IconSprite.new(0, 0, @viewport)
      @sprites["bg"].setBitmap("Graphics/UI/Instant Messages/Themes/#{@scene.theme}/divider#{divider_suffix}")
      @sprites["bg"].x = self.x
      @sprites["bg"].y = self.y
      @sprites["bg"].visible = @divider_visible
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      refresh
    end

    def x=(value)
        super
        refresh
    end

    def y=(value)
        super
        refresh
    end

    def color=(value)
      super
      refresh
    end
    
    def visible=(value)
        @sprites["bg"].visible = value && @divider_visible
        @sprites["overlay"].visible = value
    end

    def text=(value)
      return if @text == value
      @text = value
      refresh
    end

    def width
        return @sprites["bg"].width
    end

    def height
        return @sprites["bg"].height
    end

    def refresh_overlay_information
      @sprites["overlay"].bitmap&.clear
      draw_text
    end

    def draw_text
      return if !@text || @text.length == 0
      pbSetSmallFont(@sprites["overlay"].bitmap)
      pbDrawTextPositions(@sprites["overlay"].bitmap,
                          [[@text, self.width/2, 2, 2, @text_base_color, @text_shadow_color]])
    end

    def refresh
      return if disposed?
      if @sprites["overlay"] && !@sprites["overlay"].disposed?
        @sprites["overlay"].x     = self.x
        @sprites["overlay"].y     = self.y
        @sprites["overlay"].color = self.color
        refresh_overlay_information
      end
      if @sprites["bg"] && !@sprites["bg"].disposed?
        @sprites["bg"].x     = self.x
        @sprites["bg"].y     = self.y
        @sprites["bg"].color = self.color
      end
    end

    def update
      super
      @sprites["overlay"].update if @sprites["overlay"] && !@sprites["overlay"].disposed?
      @sprites["bg"].update if @sprites["bg"] && !@sprites["bg"].disposed?
    end

end

def pbTXWSecondsToFrameConvert(seconds)
    return nil if seconds.nil?
    if Essentials::VERSION.include?("21")
        t = ((1 / Graphics.delta) * seconds).round
        i = 0
        while t > seconds * 120
                tt = ((1 / Graphics.delta) * seconds).round
                t = tt if tt < t
                i += 1
                if i > 100
                    t = seconds * 120
                    break
                end
        end
        return t
    else
        return Graphics.frame_rate * seconds
    end
end