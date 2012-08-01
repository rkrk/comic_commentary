require 'digest/sha1'


PW_FILE = 'pw/pw.txt'

helpers do
  def auth_ok?(id, pw)
    user_auth = load_authinfo
    # p pw
    # user_auth[id] == Digest::SHA1.hexdigest(pw)
    user_auth[id] == Digest::SHA1.hexdigest(pw).chomp ? true : false 

  end

  def load_authinfo
    user_auth = {}
    File.open(PW_FILE,"r").each do |l|
      # p l 
      id,password = l.split(',')
      user_auth.store id,password.chomp
    end
    p user_auth
    return user_auth
  end

  def login
    # p  params[:pw]
    if auth_ok?(params[:id], params[:pw])
      session[:login_id] = "#{params[:id]}"
      redirect '/trans'
    else
      erb :login
    end
  end

  def logout
  session.delete(:login_id)
  redirect '/'
  end

  def need_auth
    unless session[:login_id]
      erb :login
    else
      yield
    end
  end

  def register
    # p params[:id]
    # p params[:pw].chomp
    # p params[:pw_repeat].chomp
    id,pw,pw_repeat = params[:id],params[:pw].chomp,params[:pw_repeat].chomp

    (p "pw not =";return false) unless pw == pw_repeat
    (p "id < 3 or pw < 5";return false) if id.size < 3 || pw.size < 5
    (p "id ald hased.";return false) if load_authinfo.has_key? id

    File.open(PW_FILE,"a") do |io| 
      # p io
      io.puts "#{id},#{Digest::SHA1.hexdigest(pw)}"
    end
    return true
  end
end