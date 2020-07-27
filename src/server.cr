require "kemal"
require "xml"
require "./locast-api"
require "./config"

config = Config.new
locast_api = Locast::API.new

get "/playlist" do
	address = "#{Kemal.config.scheme}://#{config.hostname}:#{Kemal.config.port}"
  m3u = ["#EXTM3U"]
  stations = locast_api.get_stations
  stations.each do |station|
    m3u << "#EXTINF:-1 tvg-name=\"#{station.callSign}\" tvg-logo=\"#{station.logoUrl}\" tvg-id=\"#{station.id}\",#{station.callSign}"
    m3u << "#{address}/station/#{station.id}"
  end
  m3u.join "\n"
end

get "/station/:id" do |env|
  station = locast_api.get_station env.params.url["id"]
  env.redirect station.streamUrl.not_nil!
end

get "/epg" do |env|
  env.response.content_type = "application/xml"
  stations = locast_api.get_stations
  string = XML.build indent: "  " do |xml|
    xml.element "tv" do
      stations.each do |station|
        xml.element "channel", id: station.id do
          xml.element "display-name" { xml.text station.callSign }
          xml.element "icon", src: station.logoUrl
        end
      end
      stations.each do |station|
        station.listings.not_nil!.each do |listing|
          start = Time.unix_ms(listing.startTime).to_s "%Y%m%d%H%M%S %z"
          stop = Time.unix_ms(listing.startTime + (listing.duration * 1000)).to_s "%Y%m%d%H%M%S %z"
          xml.element "programme", start: start, stop: stop, channel: station.id do
            xml.element "title" { xml.text listing.title }
            if !listing.episodeTitle.nil?
              xml.element "sub-title" { xml.text listing.episodeTitle.not_nil! }
            end
            if !listing.description.nil?
              xml.element "desc" { xml.text listing.description.not_nil! }
            end
            xml.element "icon", src: listing.preferredImage
            if !listing.seasonNumber.nil? && !listing.episodeNumber.nil?
              xml.element "episode-num", system: "xmltv_ns" { xml.text "#{listing.seasonNumber.not_nil! - 1}.#{listing.episodeNumber.not_nil! - 1}." }
            end
            if !listing.rating.nil?
              xml.element "rating", system: "VCHIP" {
                xml.element "value" { xml.text listing.rating.not_nil! }
              }
            end
          end
        end
      end
    end
  end
  string
end

Kemal.run
