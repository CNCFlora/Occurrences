
config_file ENV['config'] || 'config.yml'
use Rack::Session::Pool
set :session_secret, '1flora2'

def http_get(uri)
    JSON.parse(Net::HTTP.get(URI(uri)))
end

def http_post(uri,doc) 
    uri = URI.parse(uri)
    header = {'Content-Type'=> 'application/json'}
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = doc.to_json
    http.request(request)
end

def search(index,query)
    query="*" unless query != nil && query.length > 0
    result = []
    http_get("#{settings.config[:elasticsearch]}/#{index}/_search?size=9999&q=#{URI.encode(query)}")['hits']['hits'].each{|hit|
        result.push(hit["_source"])
    }
    result
end

config = {}

config[:etcd] = ENV["ETCD"] || settings.etcd

if config[:etcd]
    etcd = http_get("#{config[:etcd]}/v2/keys/?recursive=true") 
    etcd['node']['nodes'].each {|node|
        if node.has_key?('nodes')
            node['nodes'].each {|entry|
                if entry.has_key?('value') && entry['value'].length >= 1 
                    key = entry['key'].gsub("/","_").gsub("-","_").downcase()[1..-1]
                    config[key.to_sym] = entry['value']
                end
            }
        end
    }
end

config[:connect] = "#{config[:connect_url]}"
config[:datahub] = "#{config[:datahub_url]}"
config[:elasticsearch] = "#{config[:elasticsearch_url]}"
config[:strings] = JSON.parse(File.read("locales/#{settings.lang}.json", :encoding => "BINARY"))
config[:services] = "#{config[:dwc_services_url]}/api/v1"
config[:base] = settings.base

set :config, config

def view(page,data)
    @config = settings.config
    @session_hash = {:logged => session[:logged] || false, :user => session[:user] || '{}'}
    if session[:logged] 
        session[:user]['roles'].each do | role |
            @session_hash["role-#{role['role'].downcase}"] = true
        end
    end
    mustache page, {}, @config.merge(@session_hash).merge(data)
end
