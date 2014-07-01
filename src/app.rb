Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?

if development?
    also_reload "routes/*"
end

config_file ENV['config'] || '../config.yml'
use Rack::Session::Pool
set :session_secret, '1flora2'
set :views, 'src/views'

require 'cncflora_commons'

if ENV["db"] then
    set :db, ENV["db"]
end

config = etcd2settings(ENV["ETCD"] || settings.etcd)

config[:strings] = JSON.parse(File.read("src/locales/#{settings.lang}.json", :encoding => "BINARY"))
config[:elasticsearch] = "#{config[:datahub]}/#{settings.db}"
config[:couchdb] = config[:datahub]
config[:base] = settings.base

config.keys.each { |key| set key, config[key] }

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
    session[:user] = JSON.parse(params[:user])
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

