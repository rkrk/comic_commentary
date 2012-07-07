require 'digest/sha1'


PW_FILE = 'pw/pw.txt'

helpers do
def auth_ok?(id, pw)
  user_auth = {}
  File.open(PW_FILE,"r").each do |l|
    id,pw = l.split(',')
    user_auth.store id,pw.chomp
  end
  # p user_auth
  # p pw
  # p Digest::SHA1.hexdigest pw
  user_auth[id] == pw.chomp

 end

def login
  # p  params[:pw]
   if auth_ok?(params[:id], params[:pw])
     session[:login] = 'login - blabla... '
     redirect '/trans'
   else
     erb :login
   end
 end

 def logout
   session.delete(:login)
   redirect '/'
 end

 def need_auth
   unless session[:login]
     erb :login
   else
     yield
   end
 end
end