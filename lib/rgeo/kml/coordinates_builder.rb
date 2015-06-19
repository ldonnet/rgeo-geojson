module RGeo
  module Kml
    
    class CoordinatesBuilder
      attr_reader :geo_factory, :parent, :points
      attr_accessor :text
      
      def initialize( geo_factory, parent)
        @geo_factory = geo_factory
        @parent = parent
        @points = []
      end

      def build
        @text.gsub(/\n/, ' ').strip.split(/\s+/).each do |coord|
          x, y, z = coord.split(',')
          if x.nil? || y.nil?
            fail StandardError, 'Coordinates must have at least x and y elements'
          end
          if z.nil?
            @points << @geo_factory.point(x, y)
          else
            @points << @geo_factory.point(x, y, z)
          end

          @points
        end
        
      rescue Exception => e
        puts "Exception #{e.message} \n #{e.backtrace}"
        raise StandardError, 'Error parsing coordinates: check your kml for errors'
      end
      
    end

  end
end
