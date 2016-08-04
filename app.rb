require 'sinatra'
require 'sinatra/reloader'
require 'faker'
require 'pony'
require './env'

enable :sessions
use Rack::MethodOverride

#Basic Authentication (pretty much useless)
# use Rack::Auth::Basic, "Restricted Area" do |username, password|
#   username == 'admin' and password == 'admin'
# end

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end

get '/free' do
  'This is public content'
end

get '/special' do
  protected!
  'This is private'
end

get '/' do
  protected!
  session[:count] = session[:count].to_i + 1
  erb :index, layout: :default
end


post '/' do
  session[:language] = params[:language]
  session[:bgcolor] = params[:bgcolor]

  # def invert_color(color)
  #   color.gsub!(/^#/, '')
  #   sprintf("%X", color.hex ^ 0xFFFFFF)
  # end
  # p invert_color(session[:bgcolor])
  # session[:font] == invert_color(session[:bgcolor].to_s)

  session[:bgcolor] >= '#00f900' ? session[:font] = '#333333' : session[:font] = '#ffffff'
  puts params
  # erb :index, layout: :default
  redirect back
end

delete '/remove_bg' do
  session[:color] = nil
  redirect back
end

get '/about' do
  session[:count] = session[:count].to_i + 1
  erb :about, layout: :default
end

post 'about' do

  # erb :about, layout: :default
  redirect back
end

get '/contact' do

erb :contact, layout: :default
end

post '/contact' do
  @name = params[:name]
  @email = params[:email]
  @message = params[:message]
  @subject = params[:subject]
  Pony.mail({
  :to => "#{@email}",
  :via => :smtp,
  :via_options => {
    :address              => 'smtp.gmail.com',
    :port                 => '587',
    :enable_starttls_auto => true,
    :user_name            => ENV['gmail_username'],
    :password             => ENV['gmail_password'],
    :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
    :domain               => "localhost.localdomain" # the HELO domain provided by the client to the server
  },
  :subject => "#{@subject}",
  :body => "Hello, #{@name}\n\n#{@message}\n\nBest\n\nRoderick",
})

erb :contact, layout: :default
end
