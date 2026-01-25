#===============================================================================
# Data handling. DO NOT EDIT
#===============================================================================
class IMConversation
    attr_accessor :convo_data
    attr_accessor :group_data
    attr_accessor :member_data
    attr_accessor :messages
    attr_accessor :id
    attr_accessor :group
    attr_accessor :title
    attr_accessor :read
    attr_accessor :important
    attr_accessor :instant
    attr_accessor :received_time

    def initialize(id)
        @convo_data = pbIMGetConversation(id)
        @group_data = pbIMGetGroup(convo_data.group)
        @member_data = []
        @group_data.members.each do |member|
            @member_data[member[0]] = pbIMGetContact(member[1])
        end
        @id = @convo_data.id
        @group = @group_data.id
        @title = @group_data.title
        @important = @convo_data.important
        @instant = @convo_data.instant
        @messages = @convo_data.messages
        @received_time = pbGetTimeNow
    end

end

class IMGroup
    attr_accessor :id
    attr_accessor :group_data
    attr_accessor :member_data
    attr_accessor :original_title
    attr_accessor :title
    attr_accessor :hide_old
    attr_accessor :convo_list
    attr_accessor :has_unread
    attr_accessor :has_important
    attr_accessor :last_received
    attr_accessor :pinned

    def initialize(id)
        @id = id
        @group_data = pbIMGetGroup(id)
        @member_data = []
        @group_data.members.each do |member|
            @member_data[member[0]] = pbIMGetContact(member[1])
        end
        @original_title = @group_data.title
        @title = @group_data.title
        @hide_old = @group_data.hide_old
        @convo_list = []
        @has_unread = false
        @has_important = false
        @last_received = pbGetTimeNow
        @pinned = false
    end

    def title
        return @title if @title
        return @original_title
    end

    def reset_title
        @title = @original_title
    end

    def toggle_pin(val = nil)
        @pinned = val unless val.nil?
        @pinned = !@pinned
    end

    def last_received
        @last_received = pbGetTimeNow if !@last_received
        return @last_received
    end

    def pinned
        @pinned = false if !@pinned
        return @pinned
    end


end

module GameData
	class InstantMessageContact
		attr_reader :id
		attr_reader :name
		attr_reader :image
		attr_reader :bubble
		
		DATA = {}

		extend ClassMethodsSymbols
		include InstanceMethods

		def self.load; end
		def self.save; end

		def initialize(hash)
			@id           	= hash[:id]
			@name    	    = hash[:name] || "???"
			@image    	    = hash[:image] || "default"
			@bubble  	    = hash[:bubble] || "White"
		end
	end
	
	class InstantMessageGroup
		attr_reader :id
		attr_reader :title
		attr_reader :members
		attr_reader :hide_old
		
		DATA = {}

		extend ClassMethodsSymbols
		include InstanceMethods

		def self.load; end
		def self.save; end

		def initialize(hash)
			@id           	= hash[:id]
			@title    	    = hash[:title] || "???"
			@members    	= hash[:members]
			@hide_old    	= hash[:hide_old] || false
		end
	end
	
	class InstantMessageConversation
		attr_reader :id
		attr_reader :group
		attr_reader :messages
		attr_reader :important
		attr_reader :instant
		attr_reader :reltimestamp
		
		DATA = {}

		extend ClassMethodsSymbols
		include InstanceMethods

		def self.load; end
		def self.save; end

		def initialize(hash)
			@id           	= hash[:id]
			@group    	    = hash[:group]
			@messages    	= hash[:messages]
			@important    	= hash[:important] || false
			@instant    	= hash[:instant] || false
			@reltimestamp   = hash[:reltimestamp] || nil
		end
	end
end

def pbIMGetContact(id)
    return GameData::InstantMessageContact.get(id)
end

def pbIMGetGroup(id)
    return GameData::InstantMessageGroup.get(id)
end

def pbIMGetConversation(id)
    return GameData::InstantMessageConversation.get(id)
end

