# locast-m3u

The ability to use locast as a normal IPTV provider, built for use with xTeVe and Plex  

## Installation

At some point I want to publish binaries, but until then follow the development instructions to get the project running

## Usage

A config.yml file will need to be created and filled out, an example is provided as config.yml.example, which can be used as a template for the settings that need to be filled in.

## Development

```
git clone https://github.com/huggablesquare/locast-m3u.git
cd locast-m3u
shards install
crystal run src/server.cr
```
