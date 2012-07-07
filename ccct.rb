runtime_path = File.expand_path(File.dirname($0))
model_path = runtime_path+ '/model'
helper_path = runtime_path + '/helper'
$LOAD_PATH.push(model_path).push(helper_path)

require 'sinatra'
require 'logger'
require 'yaml'
require 'comment'

require 'basic_auth'

# CCCT_MAX_NUMBER = 9
CCCT_HOME = runtime_path

COMIC_HOME = runtime_path + '/trans/pic'
TRANS_HOME = runtime_path + '/trans/content'

@@log = Logger.new("#{CCCT_HOME}/log/ccct.log", 'daily')
# @@log = Logger.new(STDOUT)
@@log.level = Logger::DEBUG


@@log.debug("-- Start at " + Time.now.to_s + "--")

@@comics = []
@@vols = {}
@@pages = {}
@@pages_trans_status = {}

@@trans_comics = []
@@trans_vols = {}
@@trans_pages = {}
@@trans_pages_trans_status = {}


# init @@comic
@@comics = Dir.glob( COMIC_HOME + "/*")
# init @@vols of comic
@@comics.each do |c| 
	@@vols.store c,Dir.glob(c + "/*")
end
# init @@pages of vol
@@vols.each_value do |vols|
	vols.each do |v|
		@@pages.store v,Dir.glob(v+"/*").map { |e| File.basename(e).split('.')[0] }
	end
end

#Output inited @@params in debug log
@@log.debug("@@comics : ")
@@log.debug(@@comics)
@@log.debug("@@vols : ")
@@log.debug(@@vols )
@@log.debug("@@pages : ")
@@log.debug(@@pages )
@@log.debug("@@pages_trans_status : ")
@@log.debug(@@pages_trans_status )

# Init a tranlate job for '/trans/**/*'
@@trans_a_page = Comment.new



before '/trans' do 
	
	# if session[:session_id] 
		# p session[:session_id] 
		init_trans_params
	
		#Output inited @@params in debug log
		@@log.debug("@@trans_comics : ")
		@@log.debug(@@trans_comics)
		@@log.debug("@@trans_vols : ")
		@@log.debug(@@trans_vols )
		@@log.debug("@@trans_pages : ")
		@@log.debug(@@trans_pages )
		@@log.debug("@@trans_pages_trans_status : ")
		@@log.debug(@@trans_pages_trans_status )

		# erb :"/trans/#{params[:splat]}"
	# else 
	# 	redirect '/login'
	# end
end

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
	# p params
	@comics = @@comics.map { |e| File.basename(e) }
	# c = @@comics.map { |e| File.basename(e) }
	erb :'/comic/comics'
end

get '/comic/:comic_name' do 
	# request.env.map { |e| e.to_s + "\n" }
	# p params
	@comic_name = params[:comic_name]
	comic_dir = COMIC_HOME + "/" + params[:comic_name]
	@vols = @@vols[comic_dir].map { |e| File.basename(e) }

	@@log.debug("-*- Show page /comic/some_comic -*- : ")	
	@@log.debug(params)	
	@@log.debug(@comic_name)
	@@log.debug(@vols)
	
	erb :'/comic/vols'
end	

get '/comic/:comic_name/:vol' do 
	request.env.map { |e| e.to_s + "\n" }
	@comic_name,@vol  = params[:comic_name], params[:vol]
	comic_dir = COMIC_HOME + "/" + params[:comic_name] + "/" + params[:vol]
	@pages = @@pages[comic_dir]

	@@log.debug("-**- Show page /comic/some_comic/some_vol -**- : ")
	@@log.debug(params)	
	@@log.debug(@comic_name)
	@@log.debug(@vol)
	@@log.debug(@pages)

	erb :'/comic/pages'
end	

get '/comic/:comic_name/:vol/:page' do 
	request.env.map { |e| e.to_s + "\n" }
	@comic_name,@vol,@page = params[:comic_name],params[:vol],params[:page]
	@comic_path = COMIC_HOME + "/" + params[:comic_name] + "/" + params[:vol] + "/" + params[:page]
	@translate_path = TRANS_HOME + "/" + params[:comic_name] + "/" + params[:vol] + "/" + params[:page]

	@@log.debug("-***- Show page /comic/some_comic/some_vol/some_page -***- : ")
	@@log.debug(params)		
	@@log.debug(@comic_name)
	@@log.debug(@vol)
	@@log.debug(@page)
	
	erb :'/comic/page_trans'
end	

get '/about' do
	request.env.map { |e| e.to_s + "\n" }
	@readme = File.open('./README')
	erb :about_me
end


#------------------------Trans/Edit Tool-------------------------------------------

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

get '/trans' do
	# request.env.map { |e| e.to_s + "\n" }
	# p params
	need_auth do 
		@comics = @@trans_comics.map { |e| File.basename(e) }
		erb :'/trans/trans'
	end
end

# get '/trans/*' do
# 	login
# end

get '/trans/:comic_name' do 
	# request.env.map { |e| e.to_s + "\n" }
	# p params
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
		@comic_name,@vol,@page = params[:comic_name],params[:vol],params[:page]
		erb :'/trans/page_detail'
	end
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
	x,y = params[:x],params[:y]
	t_align = params[:text_align]

	tr = TransRecord.new(con,font_s,x,y,t_align)
	@@trans_a_page.add_r(tr)

	redirect back
end

post '/trans/save' do
	if @@trans_a_page.img 
		img = @@trans_a_page.img
		comic_name,vol,page = img.comic_name,img.vol,img.page
		# @comic_path = COMIC_HOME + "/" + comic_name + "/" + vol + "/" + page
		save_dir = TRANS_HOME + "/" + comic_name + "/" + vol 
	else 
		redirect back
	end

	if @@trans_a_page.save_loc_content(save_dir) && @@trans_a_page.save_trans_content(save_dir)
		@@trans_a_page.img = nil
		@@trans_a_page.trans_record = []
		
		erb :'/trans/pages'
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
	@@pages = {}
	@@pages_trans_status = {}

	@@comics = @@trans_comics.dup
	@@vols = @@trans_vols.dup
	@@pages = @@trans_pages.dup
	@@pages_trans_status = @@trans_pages_trans_status.dup
	
	erb :'/comic/comics'
end





#------------------------Other Methods-------------------------------------------

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
	
	# reload translate status
	## For deep clone @@trans\pages, use Marshal
	@@trans_pages_trans_status = Marshal.load(Marshal.dump(@@trans_pages))
	# k,v = @@trans_pages.keys.dup,@@trans_pages.values.dup
	# k.size.times do |i| 
	# 	@@trans_pages_trans_status.store k[i],v[i]
	# end 
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