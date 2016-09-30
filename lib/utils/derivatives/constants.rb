module Utils
  module Derivatives
    class Constants
      COPY_TYPES = {}
      COPY_TYPES['access'] = { :width => 300,
        :height => 500,
        :extension => 'jpeg'
      }
      COPY_TYPES['thumbnail'] = { :width => 100,
        :height => 100,
        :extension => 'jpeg'
      }
      COPY_TYPES['default'] = { :width => 100,
        :height => 100,
        :extension => 'jpeg'
      }
    end
  end
end
