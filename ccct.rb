#coding: utf-8

runtime_path = File.expand_path(File.dirname($0))
model_path = runtime_path+ '/model'
helper_path = runtime_path + '/helper'
$LOAD_PATH.push(model_path).push(helper_path)

require 'sinatra'
require "sinatra/reloader"
require 'logger'
# require 'yaml'

require 'comment'
require 'comic'

require 'basic_auth'

#------------------------define Constants/Variables ----------------------------------------

CCCT_HOME = runtime_path

COMIC_HOME = runtime_path + '/public/trans/pic'
TRANS_HOME = runtime_path + '/public/trans/content'

PLAY_LIST_HOME = runtime_path + '/public/trans/play_list'

@@log = Logger.new("#{CCCT_HOME}/log/ccct.log", 'daily')
# @@log = Logger.new(STDOUT)
@@log.level = Logger::DEBUG


@@log.debug("-- Start at " + Time.now.to_s + "--")

@@comics = []
@@vols = {}

@@play_list_top = {}

@@trans_comics = []
@@trans_vols = {}
@@trans_pages = {}
@@trans_pages_trans_status = {}

@@origin_x = nil
@@origin_y = nil

#------------------------init Variables ----------------------------------------
#init Play_list
Dir.glob( PLAY_LIST_HOME + "/*").each do |file|
	@@play_list_top.merge! Comic.load(file)
end

@@log.debug("1. init @@play_list_top : ")
@@log.debug("#{@@play_list_top}")

# init comics/vols
@@play_list_top.keys.each do |key|
	c,v = key.split("@")
	@@comics << c
	@@vols.has_key?(c) ? (@@vols[c] << v) : (@@vols.store c,[v])
	@@comics.uniq!	
end

@@log.debug("2. init @@comics / @@vols: ")
@@log.debug(@@comics)
@@log.debug(@@vols)

# init trans_params
@@trans_a_page = Comment.new

@@log.debug("3-1. init @@trans_a_page : ")
@@log.debug(@@trans_a_page)

@@play_list = Comic.new

@@log.debug("3-2. init @@play_list : ")
@@log.debug(@@play_list)


#------------------------init trans_params Methods-------------------------------------------

def init_trans_params
	# reload comic
	@@trans_comics = Dir.glob( COMIC_HOME + "/*")
	# reload vols of comic
	@@trans_comics.each do |c| 
		@@trans_vols.store c,Dir.glob(c + "/*")
	end
	# reload pages of vol
	@@trans_vols.each_value do |vols|
		vols.each do |v|
			@@trans_pages.store v,Dir.glob(v+"/*").map { |e| File.basename(e).split('.')[0] }
		end
	end
	
end

def reload_trans_status
	@@trans_pages_trans_status = Marshal.load(Marshal.dump(@@trans_pages))
	@@trans_pages_trans_status.each do |vol,pages|
		#Check trans_content(.erb) and loc_content(.css) exist or not
		c = vol.split('/')[-2]
		v = vol.split('/')[-1]
		# p pages 
		pages.map! do |p|
			target = "#{TRANS_HOME}/#{c}/#{v}/#{p}"
			if (File.exist? "#{target}.erb") && (File.exist? "#{target}.css")
				[p,1]
			else 
				[p,0]
			end
		end
	end
end

#------------------------before filter-------------------------------------------

before '/trans' do 
	# if session[:session_id] 
	init_trans_params
	reload_trans_status

	#Output inited @@params in debug log
	@@log.debug("4. init @@trans_* params : ")
	@@log.debug("@@trans_comics : ")
	@@log.debug(@@trans_comics)
	@@log.debug("@@trans_vols : ")
	@@log.debug(@@trans_vols )
	@@log.debug("@@trans_pages : ")
	@@log.debug(@@trans_pages )
	@@log.debug("@@trans_pages_trans_status : ")
	@@log.debug(@@trans_pages_trans_status )
end

before '/trans/*' do 
	init_trans_params
	reload_trans_status
end

#----------------enable session----------------------------------------------------------

enable :sessions
	
#----------------Comic Show APP----------------------------------------------------------

['/','/home'].each do |home|
	get home do
		request.env.map { |e| e.to_s + "\n" }
		erb :home
	end
end

get '/comic' do
	# request.env.map { |e| e.to_s + "\n" }
	@comics = @@comics
	erb :'/comic/comics'
end

get '/comic/:comic_name' do 
	# request.env.map { |e| e.to_s + "\n" }
	@comic_name = params[:comic_name]
	@vols = @@vols[@comic_name]

	@@log.debug("-*- Show page /comic/some_comic -*- : ")	
	@@log.debug(params)	
	@@log.debug(@comic_name)
	@@log.debug(@vols)
	
	erb :'/comic/vols'
end	

get '/comic/:comic_name/:vol' do 
	request.env.map { |e| e.to_s + "\n" }
	@comic_name,@vol  = params[:comic_name], params[:vol]
	hash_key = "#{@comic_name}@#{@vol}"

	comic_dir = COMIC_HOME + "/" + @comic_name + "/" + @vol

	@pages = @@play_list_top[hash_key][0]
	@play_list = @@play_list_top[hash_key][1]

	if @play_list.size > 0 
		erb :'/comic/vol_play_list'
	else
		erb :'/comic/pages'
	end 
end	

get '/comic/:comic_name/:vol/:page_num' do 
	request.env.map { |e| e.to_s + "\n" }
	@comic_name,@vol,@page_num = params[:comic_name],params[:vol],params[:page_num]

	hash_key = "#{@comic_name}@#{@vol}"
	@pages = JSON::parse(@@play_list_top[hash_key][0])
	@play_list = @@play_list_top[hash_key][1]
	@page_num_max = @pages.size

	@page = @pages[@page_num.to_i - 1]

	@comic_path = COMIC_HOME + "/" + @comic_name + "/" + @vol + "/" + @page
	@translate_path = TRANS_HOME + "/" + @comic_name + "/" + @vol + "/" + @page

	erb :'/comic/page_trans'
end	

get '/about' do
	request.env.map { |e| e.to_s + "\n" }
	@readme = File.open('./README')
	erb :about
end

#------------------------login/out , regist-----------------------------------------

get '/login' do 
	erb :login
end

post '/login' do
	login
end

get '/logout' do
	logout
end

post '/logout' do
	logout
end

get '/regist'do
	erb :regist
end

#------------------------Comic Trans/Edit Tool-----------------------------------------

post '/regist' do
	if regist 
		redirect '/login'
	else
		redirect back
	end
end

get '/trans' do
	# request.env.map { |e| e.to_s + "\n" }
	need_auth do 
		@comics = @@trans_comics.map { |e| File.basename(e) }
		erb :'/trans/trans'
	end
end

get '/trans/play_list' do
	need_auth do 
		erb :'/trans/play_list'
	end
end 

post '/trans/play_list/setbase' do
	need_auth do
		c_name,vol,p_total = params[:comic_name],params[:vol],params[:p_total]
		@@play_list.comic_name = c_name
		@@play_list.vol = vol
		@@play_list.page_total = p_total
		redirect back
	end
end

post '/trans/play_list/addlist' do
	need_auth do 
		title,p_from,p_to = params[:title],params[:p_from],params[:p_to]
		pl = [] << title << p_from << p_to
		@@play_list.play_list << pl 
		redirect back
	end
end

get '/trans/play_list/remove/:index' do 
	need_auth do 
		@@play_list.play_list.delete_at params[:index].to_i
		redirect back
	end
end

post '/trans/play_list/setpages' do
	need_auth do 
		p params[:pages]
		p params[:pages].class
		@@play_list.pages=params[:pages]
		redirect back
	end
end


post '/trans/play_list/save' do
	need_auth do
		# @@play_list.to_s

		if @@play_list.play_list.size > 0 
			comic_name,vol = @@play_list.comic_name,@@play_list.vol
		else 
			redirect back
		end

		if @@play_list.store(PLAY_LIST_HOME)
			@@play_list = nil
			@@play_list = Comic.new

			redirect "/trans"
		else
			redirect back
		end
	end
end

get '/trans/:comic_name' do 
	# request.env.map { |e| e.to_s + "\n" }
	need_auth do 
		@comic_name = params[:comic_name]
		@comic_dir = COMIC_HOME + "/" + @comic_name
		@vols = @@trans_vols[@comic_dir].map { |e| File.basename(e) }

		erb :'/trans/vols'
	end
	
end	

get '/trans/:comic_name/:vol' do 
	# request.env.map { |e| e.to_s + "\n" }
	need_auth do 
		@comic_name,@vol  = params[:comic_name], params[:vol]
		@comic_dir = COMIC_HOME + "/" + @comic_name + "/" + @vol
		@trans_status = @@trans_pages_trans_status[@comic_dir]

		erb :'/trans/pages'
	end
end	

get '/trans/:comic_name/:vol/:page' do 
	# @trans_home = 
	need_auth do
		@origin_x,@origin_y = @@origin_x,@@origin_y
		@comic_name,@vol,@page = params[:comic_name],params[:vol],params[:page]
		comic_dir = COMIC_HOME + "/" + @comic_name + "/" + @vol
		trans_dir = TRANS_HOME + "/" + @comic_name + "/" + @vol
		erb_f = trans_dir + "/" + @page + ".erb"
		css_f = trans_dir + "/" + @page + ".css"

		erb :'/trans/page_detail'
	end
end	

get '/trans/:comic_name/:vol/:page/remove_record/:index' do
	@@trans_a_page.trans_record.delete_at(params[:index].to_i)
	redirect back 
end

post '/trans/set/img' do 
	c_name,vol,page = params[:comic_name],params[:vol],params[:page]
	width,height = params[:width],params[:height]
	suffix = params[:suffix]
	
	@@trans_a_page.img = ImageAttr.new(c_name,vol,page,width,height,suffix)

	redirect back
	# erb :edit
end	

post '/trans/add/transrecord' do
	con = params[:content]
	font_s = params[:font_size]
	x,y = params[:x_fix],params[:y_fix]
	origin_x,origin_y = params[:origin_x],params[:origin_y]
	t_align = params[:text_align]
	aspect = params[:aspect]

	tr = TransRecord.new(con,font_s,x,y,t_align,aspect)
	@@trans_a_page.add_r(tr)
	@@origin_x = origin_x
	@@origin_y = origin_y

	redirect back
end

post '/trans/save' do
	p @@trans_a_page.to_s

	if @@trans_a_page.img 
		img = @@trans_a_page.img
		comic_name,vol,page = img.comic_name,img.vol,img.page
		save_dir = TRANS_HOME + "/" + comic_name + "/" + vol + "/"
	else 
		redirect back
	end

	if @@trans_a_page.save_trans_content(save_dir) and @@trans_a_page.save_loc_content(save_dir) 
		@@trans_a_page.img = nil
		@@trans_a_page.trans_record = []

		# reload_trans_status
		
		redirect "/trans/#{comic_name}/#{vol}"
	else
		redirect back
	end
end

post '/trans/clear' do 
	@@trans_a_page.img = nil
	@@trans_a_page.trans_record = []
	redirect back
end

post '/trans/comit' do
	@@comics = []
	@@vols = {}

	@@play_list_top = {}
	
	#init Play_list
	Dir.glob( PLAY_LIST_HOME + "/*").each do |file|
		@@play_list_top.merge! Comic.load(file)
	end

	@@log.debug("5-1. reload @@play_list_top from <play_list>.json: ")
	@@log.debug("#{@@play_list_top}")

	# init comics/vols
	@@play_list_top.keys.each do |key|
		# key 
		c,v = key.split("@")
		@@comics << c
		@@vols.has_key?(c) ? (@@vols[c] << v) : (@@vols.store c,[v])
		@@comics.uniq!	
	end
	
	@@log.debug("5-2. reload @@comics / @@vols from @@play_list_top:")
	@@log.debug(@@comics)
	@@log.debug(@@vols)

	redirect '/trans'
end



