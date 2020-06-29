require "cossack"
require "jwt"
require "http/params"
require "./config"

module Locast
  class Listing
    JSON.mapping(
      startTime: UInt64,
      duration: UInt64,
      title: String,
      episodeTitle: String?,
      description: String?,
      episodeNumber: UInt32?,
      seasonNumber: UInt32?,
      preferredImage: String,
      rating: String?
    )
  end

  class Station
    JSON.mapping(
      callSign: String,
      id: UInt32,
      logoUrl: String,
      name: String,
      stationId: String,
      streamUrl: String?,
      listings: Array(Locast::Listing)?
    )
  end

  class API
    @token = ""
    @dma = ""
    @cossack = Cossack::Client.new "https://api.locastnet.org/api"

    @config = Config.new

    private def login
      body = @config.credentials
      params = HTTP::Params.encode({ "client_id" => "" })
      response = @cossack.post "/user/login?#{params.to_s}", body.to_json do |client|
        client.headers["Content-Type"] = "application/json"
      end
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
        response = @cossack.get "/watch/dma/#{lat}/#{lon}" do |client|
          client.headers["Content-Type"] = "application/json"
        end
        dma = JSON.parse response.body
        @dma = dma["DMA"].as_s
      end

      @dma
    end
    
    def get_stations
      dma = self.get_dma
      start = Time.utc.at_beginning_of_hour
      params = HTTP::Params.encode({ "startTime" => start.to_rfc3339 })
      response = @cossack.get "/watch/epg/#{dma}?#{params.to_s}"

      Array(Locast::Station).from_json response.body
    end
    
    def get_station(id : String | Int)
      token = self.get_token
      lat, lon = self.get_coords

      response = @cossack.get "/watch/station/#{id}/#{lat}/#{lon}" do |client|
        client.headers["Authorization"] = "Bearer #{token}"
      end
      
      puts response.body

      Locast::Station.from_json response.body
    end
  end
end
