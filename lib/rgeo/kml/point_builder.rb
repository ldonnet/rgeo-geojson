module RGeo
  module Kml
    
    class PointBuilder
      attr_reader :parent, :point, :geo_factory
      attr_accessor :points, :text
      
      def initialize(geo_factory, parent)
        @geo_factory = geo_factory
        @parent = parent
      end
      
      def build
        @point = points.first
      end
      
    end

  end
end
