# -----------------------------------------------------------------------------
#
# Kml implementation for RGeo
#
# -----------------------------------------------------------------------------

# Dependencies
require 'rgeo'

# RGeo is a spatial data library for Ruby, provided by the "rgeo" gem.
#
# The optional RGeo::GeoJSON module provides a set of tools for GeoJSON
# encoding and decoding.

module RGeo


  # This is a namespace for a set of tools that provide KML encoding.
  # See https://developers.google.com/kml/documentation/ for more information about this specification.

  module Kml
  end


end


# Implementation files
require 'rgeo/kml/version'
require 'rgeo/kml/entities'
require 'rgeo/kml/coder'
require 'rgeo/kml/interface'
require 'rgeo/kml/kml_stream_listener'
require 'rgeo/kml/coordinates_builder'
require 'rgeo/kml/point_builder'
require 'rgeo/kml/line_string_builder'
require 'rgeo/kml/linear_ring_builder'
require 'rgeo/kml/polygon_builder'
require 'rgeo/kml/multi_geometry_builder'
