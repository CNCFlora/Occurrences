Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/mustache'
require "sinatra/reloader" if development?
require 'multi_json'
require 'time'
require 'uri-handler'
require 'rest-client'

config_file ENV['config'] || 'config.yml'
use Rack::Session::Pool
set :session_secret, '1flora2'

config = {}

if settings.etcd
    etcd = MultiJson.load(RestClient.get("#{settings.etcd}/v2/keys/?recursive=true"),:symbolize_keys=>true) 
    etcd[:node][:nodes].each {|node|
        if node.has_key?(:nodes)
            node[:nodes].each {|entry|
                if entry.has_key?(:value) && entry[:value].length >= 1 
                    key = entry[:key].gsub("/","_").downcase()[1..-1]
                    config[key.to_sym] = entry[:value]
                end
            }
        end
    }
end

config[:connect] = "http://#{config[:connect_host ]}:#{config[:connect_port]}"
config[:strings] = MultiJson.load(File.read("locales/#{settings.lang}.json", :encoding => "BINARY"),:symbolize_keys => true)
config[:base] = settings.base

set :config, config

def view(page,data)
    @config = settings.config
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || '{}'}
    if session[:logged] 
        session[:user][:roles].each do | role |
            @session_hash["role-#{role[:role].downcase}"] = true
        end
    end
    mustache page, {}, @config.merge(@session_hash).merge(data)
end

get '/' do
    view :index,{}
end

post '/login' do
    session[:logged] = true
    session[:user] = MultiJson.load(params[:user],:symbolize_keys => true)
    204
end

post '/logout' do
    session[:logged] = false
    session[:user] = false
    204
end


