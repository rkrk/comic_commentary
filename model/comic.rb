#coding: utf-8

require 'json'
require 'date'

class Title

    attr_accessor :title,:intro,:tag,:abbr_pic
    
    def initialize (title="",intro="",tag=[],abbr_pic="")
        @title = title
        @intro = intro
        @tag = tag
        @abbr_pic = abbr_pic
    end

    def store(file)
        File.open(file, "") do |io|
            JSON.dump(self.to_json, io)
        end
    end

    def to_json
        return {@title => [@intro,@tag,@abbr_pic]}
    end

    def self.load(file)
        return false if !File.exist?(file)
        json_obj = File.open(file,"r")  {|io| JSON.load(io)}
    end

end

# t1 = Title.new("some","blabla",["young"],"")
# t2 = Title.new("a2","a2a2a2",["young"],"")


class Comic
    
    attr_accessor :comic_name,:vol,:page_total,:pages,:play_list
    attr_reader :entry_date

    def initialize(c_name="",vol="",p_total=0)
        @comic_name = c_name
        @vol = vol
        @page_total = p_total

        @pages = Array.new(@page_total.size)
        @play_list = []

        @entry_date = Date.today
    end

    def set_page(index,page)
        return false if index >= @page_total.size
        @pages[index] = page
    end

    def add_pl(title,page_from,page_to)
        @play_list << [title.downcase,page_from,page_to]
    end

    def store(path=".")
        p path
        file_name = "#{@comic_name}-#{@vol}.json"
        file_path = path + "/" + file_name

        open(file_path, "w+") do |io|
            JSON.dump(self.to_json, io)
        end
    end

    def to_json
        return {"#{@comic_name}@#{@vol}" => [@pages,@play_list]}
    end

    def to_s
        return "#{@comic_name},#{@vol},#{@page_total}"#,#{@pages},#{@play_list}"
    end

    def self.load(file)
        return false if !File.exist?(file)
        json_obj = File.open(file,"r") {|io| JSON.load(io)}
    end

end

# c = Comic.new("some","123",3)
# c.add_pl("list",1,3)
# c.pages = ["q001","q002","q003"]
