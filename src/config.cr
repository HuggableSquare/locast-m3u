require "yaml"

class Config
	include YAML::Serializable

	property hostname : String
	property credentials : Hash(String, String)
	property coords : Hash(String, Float64)

	def self.new
		File.open("config.yml") do |file|
			self.from_yaml file
		end
	end
end
