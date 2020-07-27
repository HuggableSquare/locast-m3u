require "cossack"
require "jwt"
require "http/params"
require "./config"

module Locast
  class Listing
    include JSON::Serializable

    property startTime : UInt64
    property duration : UInt64
    property title : String
    property episodeTitle : String?
    property description : String?
    property episodeNumber : UInt32?
    property seasonNumber : UInt32?
    property preferredImage : String
    property rating : String?
    property releaseDate : Int64?
    property airdate : Int64?
    property isNew : Bool?
    property entityType : String
    property genres : String?
    property showType : String
    property videoProperties : String?
  end

  class Station
    include JSON::Serializable

    property callSign : String
    property id : UInt64
    property logoUrl : String
    property name : String
    property stationId : String
    property streamUrl : String?
    property listings : Array(Locast::Listing)?
  end

  class API
    @token = ""
    @dma = ""
    @http = HTTP::Client.new URI.parse("https://api.locastnet.org")

    @config = Config.new

    private def login
      body = @config.credentials
      params = HTTP::Params.encode({ "client_id" => "" })
      response = @http.post "/api/user/login?" + params, headers: HTTP::Headers { "Content-Type" => "application/json" }
      login = JSON.parse response.body
      puts response.body
      login["token"].as_s
    end

    private def get_token
      puts "get_token called"
      begin
        raise Exception.new if @token.empty?
        JWT.decode @token, verify: false
      rescue e
        puts @token
        puts e.message
        puts "not cached or expired or something"
        @token = self.login
      end

      @token
    end

    private def get_coords
      coords = @config.coords
      [coords["lat"], coords["lon"]]
    end

    private def get_dma
      if @dma.empty?
        lat, lon = self.get_coords
        response = @http.get "/api/watch/dma/#{lat}/#{lon}", headers: HTTP::Headers { "Content-Type" => "application/json" }
        dma = JSON.parse response.body
        @dma = dma["DMA"].as_s
      end

      @dma
    end
    
    def get_stations
      dma = self.get_dma
      start = Time.utc.at_beginning_of_hour
      params = HTTP::Params.encode({ "startTime" => start.to_rfc3339 })
      response = @http.get "/api/watch/epg/#{dma}?" + params

      Array(Locast::Station).from_json response.body
    end
    
    def get_station(id : String | Int)
      token = self.get_token
      lat, lon = self.get_coords

      response = @http.get "/api/watch/station/#{id}/#{lat}/#{lon}", headers: HTTP::Headers { "Authorization" => "Bearer #{token}" }
      
      puts response.body

      Locast::Station.from_json response.body
    end
  end
end
