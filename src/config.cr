require "yaml"

class Config
	YAML.mapping(
		hostname: String,
		credentials: Hash(String, String),
		coords: Hash(String, Float64)
	)

	def self.new
		File.open("config.yml") do |file|
			self.from_yaml file
		end
	end
end
