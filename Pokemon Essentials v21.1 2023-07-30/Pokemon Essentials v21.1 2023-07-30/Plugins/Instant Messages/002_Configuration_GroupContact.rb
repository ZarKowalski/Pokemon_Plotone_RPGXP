#===============================================================================
# Contact registrations
#
# These are individual NPCs that the player chats with in conversations.
#===============================================================================
# Parameters:
#   - :id => Symbol - The ID used to add the contact to groups 
#   - :name => String - The name of the contact the player will see
#   - :image => String - The filename of the image used to represent the contact. 
#               File location: UI/Instant Messages/Characters
#   - :bubble => String - The filename of the windowskin used by the contact. 
#               File location: UI/Instant Messages/Bubbles
#===============================================================================

GameData::InstantMessageContact.register({
    :id             => :CHATBOT,
    :name		    => _INTL("Chatbot"),
    :image		    => "Chatbot",
    :bubble         => "Green"
})

GameData::InstantMessageContact.register({
    :id             => :ADVERTISEMENT,
    :name		    => _INTL("Advertisement"),
    :image		    => "Advertisement",
    :bubble         => "Blue"
})

GameData::InstantMessageContact.register({
    :id             => :PROFOAK,
    :name		    => _INTL("Prof. Oak"),
    :image		    => "Oak",
    :bubble         => "Purple"
})

#===============================================================================
# Group registrations
#
# These are the groups/containers/threads that can contain several conversations.
# These are what appear in the selection menu, and will load conversations once
# opened.
#===============================================================================
# Parameters:
#   - :id => Symbol - The ID used to house specific conversations
#   - :title => String - The name of the group as seen by the player
#   - :members => Hash - Contains contacts included in the group and their
#                 reference numbers used when creating conversation messages.
#                 { <Interger - Reference Number => <Symbol - :id of a contact}         
#   - :hide_old => (Optional) Boolean - Set to false to hide already read message
#===============================================================================

GameData::InstantMessageGroup.register({
    :id             => :CHATBOT,
    :title		    => _INTL("Chatbot"),
    :members		=> {1 => :CHATBOT}
})

GameData::InstantMessageGroup.register({
    :id             => :ADVERTISEMENT_1,
    :title		    => _INTL("Advertisement"),
    :members		=> {1 => :ADVERTISEMENT}
})

GameData::InstantMessageGroup.register({
    :id             => :ADVERTISEMENT_2,
    :title		    => _INTL("Advertisement Two"),
    :members		=> {1 => :ADVERTISEMENT}
})

GameData::InstantMessageGroup.register({
    :id             => :PROFOAK,
    :title		    => _INTL("Prof. Oak"),
    :members		=> {1 => :PROFOAK, 2 => :CHATBOT}
})