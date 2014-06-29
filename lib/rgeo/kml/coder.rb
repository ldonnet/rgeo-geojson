# -----------------------------------------------------------------------------
#
# GeoJSON encoder object
#
# -----------------------------------------------------------------------------
# Copyright 2010-2012 Daniel Azuma
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
require 'rexml/parsers/pullparser'

module RGeo

  module Kml


    # This object encapsulates encoding and decoding settings (principally
    # the RGeo::Feature::Factory and the RGeo::Kml::EntityFactory to
    # be used) so that you can encode and decode without specifying those
    # settings every time.

    class Coder


      @@kml_available = nil
      @@activesupport_available = nil


      # Create a new coder settings object. The geo factory is passed as
      # a required argument.
      #
      # Options include:
      #
      # [<tt>:geo_factory</tt>]
      #   Specifies the geo factory to use to create geometry objects.
      #   Defaults to the preferred cartesian factory.
      # [<tt>:entity_factory</tt>]
      #   Specifies an entity factory, which lets you override the types
      #   of Kml entities that are created. It defaults to the default
      #   RGeo::Kml::EntityFactory, which generates objects of type
      #   RGeo::Kml::Feature or RGeo::Kml::FeatureCollection.
      #   See RGeo::Kml::EntityFactory for more information.

      def initialize(opts_={})
        @geo_factory = opts_[:geo_factory] || ::RGeo::Cartesian.preferred_factory
        @entity_factory = opts_[:entity_factory] || EntityFactory.instance
        @kml_parser = ::Proc.new{ |str_| ::REXML::Parsers::PullParser.new(str_) }
        
        @num_coordinates = 2
        @num_coordinates += 1 if @geo_factory.property(:has_z_coordinate)
        @num_coordinates += 1 if @geo_factory.property(:has_m_coordinate)
      end


      # Encode the given object as Kml. The object may be one of the
      # geometry objects specified in RGeo::Feature, or an appropriate
      # Kml wrapper entity supported by this coder's entity factory.
      #
      # This method returns a KML object (xml with Placemark).
      #
      # Returns nil if nil is passed in as the object.

      def encode(object_)
        if @entity_factory.is_feature_collection?(object_)
          {
            'type' => 'FeatureCollection',
            'features' => @entity_factory.map_feature_collection(object_){ |f_| _encode_feature(f_) },
          }
        elsif @entity_factory.is_feature?(object_)
          _encode_feature(object_)
        elsif object_.nil?
          nil
        else
          _encode_geometry(object_)
        end
      end

      
      # Returns the RGeo::Feature::Factory used to generate geometry objects.

      def geo_factory
        @geo_factory
      end


      # Returns the RGeo::Kml::EntityFactory used to generate Kml
      # wrapper entities.

      def entity_factory
        @entity_factory
      end


      def _encode_feature(object_)  # :nodoc:
        id_ = @entity_factory.get_feature_id(object_)
        kml_ = '<?xml version="1.0" encoding="UTF-8"?>\n'
        kml_ += '<kml xmlns="http://www.opengis.net/kml/2.2">\n'
        kml_ += "<Document>"
        kml_ += "<name>Kml File</name>"
        kml_ += "<Placemark id="#{id_}">\n"
        kml_ += _encode_geometry(@entity_factory.get_feature_geometry(object_))
        kml_ += "</Placemark>\n"
        kml_ += "</Document>"
        kml_ += "</kml>"
        
        # 'properties' => @entity_factory.get_feature_properties(object_).dup,        
        # id_ = @entity_factory.get_feature_id(object_)
        # json_['id'] = id_ if id_
        kml_
      end


      def _encode_geometry(object_, point_encoder_=nil)  # :nodoc:
        unless point_encoder_
          if object_.factory.property(:has_z_coordinate)
            if object_.factory.property(:has_m_coordinate)
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y, p_.z, p_.m].join(",") }
            else
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y, p_.z].join(",") }
            end
          else
            if object_.factory.property(:has_m_coordinate)
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y, p_.m].join(",") }
            else
              point_encoder_ = ::Proc.new{ |p_| [p_.x, p_.y].join(",") }
            end
          end
        end
        case object_
        when ::RGeo::Feature::Point
          result = "<Point>\n"
          #result += options[:geom_data] if options[:geom_data]
          result += "<coordinates>" + point_encoder_.call(object_)
          result += "</coordinates>\n"
          result += "</Point>\n"
        when ::RGeo::Feature::LineString
          result = "<LineString>\n"
          #result += options[:geom_data] if options[:geom_data]
          result += "<coordinates>\n"
          result += object_.points.map(&point_encoder_).join("\n")
          result += "\n</coordinates>\n"
          result += "</LineString>\n"
        when ::RGeo::Feature::Polygon
          result = "<Polygon>\n"
          #result += options[:geom_data] if options[:geom_data]
          result += "<outerBoundaryIs><LinearRing><coordinates>\n"
          result += object_.exterior_ring.points.map(&point_encoder_).join("\n")
          result += "\n</coordinates></LinearRing></outerBoundaryIs>\n"
          object_.interior_rings.each do |interior_ring|
            result += "<innerBoundaryIs><LinearRing><coordinates>\n"
            result += interior_ring.points.map(&point_encoder_).join("\n")
            result += "\n</coordinates></LinearRing></innerBoundaryIs>\n"
          end
          result += "</Polygon>\n"
        when ::RGeo::Feature::MultiPoint
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            result += "<Point>\n<coordinates>"
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += point_encoder_.call(geometry)
            result += "</coordinates>\n</Point>\n"
          end
          result += "</MultiGeometry>\n"
        when ::RGeo::Feature::MultiLineString
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += "<LineString>\n"
            #result += options[:geom_data] if options[:geom_data]
            result += "<coordinates>\n"
            result += geometry.points.map(&point_encoder_).join("\n")
            result += "\n</coordinates>\n"
            result += "</LineString>\n"            
          end
          result += "</MultiGeometry>\n"
        when ::RGeo::Feature::MultiPolygon
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += "<Polygon>\n"
            #result += options[:geom_data] if options[:geom_data]
            result += "<outerBoundaryIs><LinearRing><coordinates>\n"
            result += geometry.exterior_ring.points.map(&point_encoder_).join("\n")
            result += "\n</coordinates></LinearRing></outerBoundaryIs>\n"
            geometry.interior_rings.each do |interior_ring|
              result += "<innerBoundaryIs><LinearRing><coordinates>\n"
              result += interior_ring.points.map(&point_encoder_).join("\n")
              result += "\n</coordinates></LinearRing></innerBoundaryIs>\n"
            end
            result += "</Polygon>\n"
          end
          result += "</MultiGeometry>\n"
        when ::RGeo::Feature::GeometryCollection
          result = "<MultiGeometry>\n"
          object_.each do |geometry|
            #options[:id_attr] = "" #the subgeometries do not have an ID
            result += object_.map{ |geom_| _encode_geometry(geom_, point_encoder_) }
          end
          result += "</MultiGeometry>\n"
        else
          nil
        end
      end


      # Decode an object from Kml. The input may a
      # String, or an IO object from which to read the KML string.
      # If an error occurs, nil is returned.

      def decode(input_)
        if input_.kind_of?(::IO)
          input_ = input_.read rescue nil
        end
        if input_.kind_of?(::String)
          input_ = @kml_parser.call(input_) rescue nil
        end
        
        case input_['type']
        when 'FeatureCollection'
          features_ = input_['features']
          features_ = [] unless features_.kind_of?(::Array)
          decoded_features_ = []
          features_.each do |f_|
            if f_['type'] == 'Feature'
              decoded_features_ << _decode_feature(f_)
            end
          end
          @entity_factory.feature_collection(decoded_features_)
        when 'Feature'
          _decode_feature(input_)
        else
          _decode_geometry(input_)
        end
      end


      def _decode_feature(input_)  # :nodoc:
        geometry_ = input_['geometry']
        if geometry_
          geometry_ = _decode_geometry(geometry_)
          return nil unless geometry_
        end
        @entity_factory.feature(geometry_, input_['id'], input_['properties'])
      end


      def _decode_geometry(input_)  # :nodoc:
        case input_['type']
        when 'Point'
          _decode_point_coords(input_['coordinates'])
        when 'LineString'
          _decode_line_string_coords(input_['coordinates'])
        when 'LinearRing'
          _decode_line_string_coords(input_['coordinates'])
        when 'Polygon'
          _decode_polygon_coords(input_['coordinates'])
        when 'MultiGeometry'
          _decode_geometry_collection(input_)
        # when 'Model'
        #   _decode_multi_polygon_coords(input_['coordinates'])
        # when 'gx:Track'
        #   _decode_multi_polygon_coords(input_['coordinates'])
        else
          nil
        end
      end


      def _decode_geometry_collection(input_)  # :nodoc:
        geometries_ = input_['geometries']
        geometries_ = [] unless geometries_.kind_of?(::Array)
        decoded_geometries_ = []
        geometries_.each do |g_|
          g_ = _decode_geometry(g_)
          decoded_geometries_ << g_ if g_
        end
        @geo_factory.collection(decoded_geometries_)
      end


      def _decode_point_coords(point_coords_)  # :nodoc:
        return nil unless point_coords_.kind_of?(::Array)
        @geo_factory.point(*(point_coords_[0...@num_coordinates].map{ |c_| c_.to_f })) rescue nil
      end


      def _decode_line_string_coords(line_coords_)  # :nodoc:
        return nil unless line_coords_.kind_of?(::Array)
        points_ = []
        line_coords_.each do |point_coords_|
          point_ = _decode_point_coords(point_coords_)
          points_ << point_ if point_
        end
        @geo_factory.line_string(points_)
      end


      def _decode_polygon_coords(poly_coords_)  # :nodoc:
        return nil unless poly_coords_.kind_of?(::Array)
        rings_ = []
        poly_coords_.each do |ring_coords_|
          return nil unless ring_coords_.kind_of?(::Array)
          points_ = []
          ring_coords_.each do |point_coords_|
            point_ = _decode_point_coords(point_coords_)
            points_ << point_ if point_
          end
          ring_ = @geo_factory.linear_ring(points_)
          rings_ << ring_ if ring_
        end
        if rings_.size == 0
          nil
        else
          @geo_factory.polygon(rings_[0], rings_[1..-1])
        end
      end


      def _decode_multi_point_coords(multi_point_coords_)  # :nodoc:
        return nil unless multi_point_coords_.kind_of?(::Array)
        points_ = []
        multi_point_coords_.each do |point_coords_|
          point_ = _decode_point_coords(point_coords_)
          points_ << point_ if point_
        end
        @geo_factory.multi_point(points_)
      end


      def _decode_multi_line_string_coords(multi_line_coords_)  # :nodoc:
        return nil unless multi_line_coords_.kind_of?(::Array)
        lines_ = []
        multi_line_coords_.each do |line_coords_|
          line_ = _decode_line_string_coords(line_coords_)
          lines_ << line_ if line_
        end
        @geo_factory.multi_line_string(lines_)
      end


      def _decode_multi_polygon_coords(multi_polygon_coords_)  # :nodoc:
        return nil unless multi_polygon_coords_.kind_of?(::Array)
        polygons_ = []
        multi_polygon_coords_.each do |poly_coords_|
          poly_ = _decode_polygon_coords(poly_coords_)
          polygons_ << poly_ if poly_
        end
        @geo_factory.multi_polygon(polygons_)
      end

      # argument should be a valid kml geometry fragment ie. <Point> .... </Point>
      # returns the GeoRuby geometry object back
      def parse(kml)
        @factory.reset
        @with_z = false
        @parser = REXML::Parsers::PullParser.new(kml)
        while @parser.has_next?
          e = @parser.pull
          if e.start_element?
            if(type = ELEMENT_MAP[e[0]])
              @factory.begin_geometry(type)
            else
              @buffer = "" if(e[0] == "coordinates") # clear the buffer
              accumulate_start(e)
            end
          elsif e.end_element?
            if(ELEMENT_MAP[e[0]])
              @factory.end_geometry(@with_z)
              @buffer = "" # clear the buffer
            else
              accumulate_end(e)
              if(e[0] == "coordinates")
                parse_coordinates(@buffer)
                @buffer = "" # clear the buffer
              end
            end
          elsif e.text? 
            accumulate_text(e)
          elsif e.cdata?
            accumulate_cdata(e)
          end
        end
        @factory.geometry.dup
      end
      
      private      
      def accumulate_text(e); @buffer << e[0]; end
      def accumulate_cdata(e); @buffer << "<![CDATA[#{e[0]}]]>"; end
      def accumulate_start(e)
        @buffer << "<#{e[0]}"
        if(e[1].class == Hash)
          e[1].each_pair {|k,v| @buffer << " #{k}='#{v}'" }
        end
        @buffer << ">"
      end
      def accumulate_end(e); @buffer << "</#{e[0]}>"; end
      
      def parse_coordinates(buffer)
        if(buffer =~ /<coordinates>(.+)<\/coordinates>/m)
          $1.gsub(/\n/, " ").strip.split(/\s+/).each do |coord|
            x,y,z = coord.split(',')
            if(x.nil? || y.nil?) 
              raise StandardError, "coordinates must have at least x and y elements"
            end
            @factory.begin_geometry(SimpleFeatures::Point)
            if(z.nil?)
              @factory.add_point_x_y(x,y)
            else
              @factory.add_point_x_y_z(x,y,z)
              @with_z = true unless @with_z # is the conditional even necessary
            end
            @factory.end_geometry(@with_z)
          end
        end
      rescue
        raise StandardError, "error parsing coordinates: check your kml for errors"
      end
    end     

  end

end
