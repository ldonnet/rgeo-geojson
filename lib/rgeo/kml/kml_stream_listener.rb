require "rexml/document"
require "rexml/streamlistener"
require "set"

module RGeo
  module Kml
    
    class KmlStreamListener
      include REXML::StreamListener
      
      attr_reader :geo_factory, :tags, :current_builder, :first_builder, :result

      def initialize( geo_factory, interesting_tags = %w{coordinates Point LineString LinearRing Polygon MultiGeometry}.freeze )
        @geo_factory = geo_factory
        @tags = interesting_tags
      end

      def tag_start(name, attrs)
        case name
        when "coordinates"    
          @current_builder = CoordinatesBuilder.new(geo_factory, @current_builder)
        when "Point"
          @current_builder = PointBuilder.new(geo_factory, @current_builder)
        when "LineString"
          @current_builder = LineStringBuilder.new(geo_factory, @current_builder)
        when "LinearRing"
          @current_builder = LinearRingBuilder.new(geo_factory, @current_builder)
        when "Polygon"
          @current_builder = PolygonBuilder.new(geo_factory, @current_builder)
        when "MultiGeometry"
          @current_builder = MultiGeometryBuilder.new(geo_factory, @current_builder)
        else
          #puts "Unknown or unparsed tag #{name}"
        end

        if tags.include?(name)
          @first_builder = @current_builder if @first_builder == nil
        end
      end

      def tag_end(name)
        if @first_builder == @current_builder
          @result = @first_builder.build
        else
          @current_builder.build
          
          case name
          when "coordinates"      
            @current_builder.parent.points = @current_builder.points
            @current_builder = @current_builder.parent
          when "Point"
            @current_builder.parent.add_point( @current_builder.point )
            @current_builder = @current_builder.parent
          when "LineString"
            @current_builder.parent.add_line_string( @current_builder.line_string )
            @current_builder = @current_builder.parent
          when "LinearRing"
            @current_builder.parent.add_linear_ring( @current_builder.linear_ring )
            @current_builder = @current_builder.parent
          when "Polygon"
            @current_builder.parent.add_polygon( @current_builder.polygon )
            @current_builder = @current_builder.parent
          else
            #puts "Unknown or unparsed tag #{name}"
          end
        end
      end

      def text(text)
        @cur_text = text
        @current_builder.text = text 
      end

      def parse(text)
        return nil if text.nil?
        REXML::Document.parse_stream(text, self)
      end
      
    end

  end
end
