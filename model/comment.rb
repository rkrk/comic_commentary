
#coding: US-ASCII
# requrie 'logger'

require 'fileutils'

class TransRecord 
	attr_reader :content,:font_size,:coordinate_x,:coordinate_y
	attr_accessor :index 
	def initialize(con="some translate",font_s=1,x=0,y=0,t_align="left")
		@content = con
		@font_size = font_s
		@coordinate_x = x
		@coordinate_y = y
		@text_align = t_align
	end
	def to_s
		"CONTENT:[#{@content}.slice[0,10] ... ] @ COORDINATE [#{coordinate_x},#{coordinate_y}]]"
	end
	def to_css(index)
		"
		#comment-#{index} {
			position: absolute;
			top: #{@coordinate_y}px;
			left: #{@coordinate_x}px;
			font-size:.#{@font_size}em;
			text-align: #{@text_align};
			background-color:#FFF;
		}"
	end

	def to_html(index)
		'<div id="comment-'+"#{index}"+'">'+"\n"+"\t#{@content}\n</div>\n"
	end 
end

class ImageAttr

	attr_accessor :comic_name,:vol,:page

	def initialize(c_name="ccct",vol=1,page="page1",width=0,height=0,suffix="png")
		@comic_name = c_name
		@vol = vol
		@page = page
		
		@width = width
		@height = height
		@suffix = suffix
	end
	def to_s 
		"COMIC_NAME:[#{comic_name}] VOL:[#{vol}] PAGE_NUM:[#{page}] 
		PIC(W*H):[#{@width}px*#{@height}px] SUFFIX:[#{@suffix}]"
	end
	def to_css
		"   #comment{
			font-family: 'Microsoft Yahei','Helvetica Neue','Verdana', 'Arial', 'sans-serif';
			position: absolute;
			width: #{@width}px;
			height: #{@height}px;
			overflow: hidden;
			background-image: url(/pic/#{@comic_name}/#{@vol}/#{@page}.#{@suffix});
			background-position: 0;
			background-repeat: no-repeat;
		}"
	end

end

class Comment

	attr_accessor :trans_record,:img
	attr_reader :loc_content,:trans_content

	def initialize 
		@trans_record = []
		@img = nil
		@loc_content = ""
		@trans_content = ""
	end

	def add_r(record)
		@trans_record << record
		self
	end
 
	def add_header
		@trans_content = '<div id= "comment">'+"\n"+"#{@trans_content}\n"+"</div>\n"
	end

	def save_loc_content(dir)

		return if @img == nil || @trans_record.size == 0

		# dir = "./public/pic/#{@img.comic_name}/#{@img.vol}/"
		@loc_content= ""

		@loc_content << @img.to_css
		@trans_record.each_index do |i|
			@loc_content << @trans_record[i].to_css(i+1)
		end

		FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
		File.open(dir+"#{@img.page}.css",'w') do |file| 
			file.puts(@loc_content)
		end
	end

	def save_trans_content(dir)

		return if @img == nil || @trans_record.size == 0 

		# dir = "./public/pic/#{@img.comic_name}/#{@img.vol}/"
		@trans_content = ""

		@trans_record.each_index do |i|
			@trans_content << @trans_record[i].to_html(i+1)
		end
		add_header
		
		FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
		File.open(dir+"#{@img.page}.erb",'w') do |file| 
			file.puts(@trans_content)
		end
	end
	
end
