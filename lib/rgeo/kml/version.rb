# -----------------------------------------------------------------------------
#
# Version of rgeo-kml
#
# -----------------------------------------------------------------------------

begin
  require 'versionomy'
rescue ::LoadError
end


module RGeo

  module Kml

    # Current version of RGeo::Kml as a frozen string
    VERSION_STRING = ::File.read(::File.dirname(__FILE__)+'/../../../Version').strip.freeze

    # Current version of RGeo::Kml as a Versionomy object, if the
    # Versionomy gem is available; otherwise equal to VERSION_STRING.
    VERSION = defined?(::Versionomy) ? ::Versionomy.parse(VERSION_STRING) : VERSION_STRING

  end

end
