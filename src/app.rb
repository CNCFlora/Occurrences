Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?
require 'cncflora_commons'

if development?
    also_reload "routes/*"
end

if test? then
    set :test , true
else
    set :test , false
end

setup '../config.yml'

def require_logged_in
    redirect('/') unless is_authenticated?
end
 
def is_authenticated?
    return !!session[:logged]
end

def view(page,data)
    @config = settings.config
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || {}, :user_json => session[:user].to_json }
    if session[:logged] 
        session[:user]['roles'].each do | role |
            @session_hash["role-#{role['role'].downcase}"] = true
        end
    end
    mustache page, {}, @config.merge(@session_hash).merge(data)
end

post '/login' do
    session[:logged] = true
    preuser =  JSON.parse(params[:user])

    if settings.test then
        session[:user] = preuser
    else
        user = http_get("#{settings.connect}/api/token?token=#{preuser["token"]}")
        puts user
        session[:user] = user
    end
    204
end

post '/logout' do
    session[:logged] = false
    session[:user] = false
    204
end

# load all routes
Dir["src/routes/*.rb"].each {|file|
    require_relative file.gsub('src/','')
}

