
require_relative 'base.rb'

describe "Test EOO and AOO calculations" do

    before (:each) do 
        post "/upload", "file" => Rack::Test::UploadedFile.new("test/aphelandra_aurantiaca_test.xlsx"), "type"=>"xlsx"
        sleep 1
        before_each() 
    end

    after (:each) do after_each() end

    it "EOO and AOO calcs" do
        pending("Not implemented")
        this_should_not_get_executed
    end

end

