module Utils
  module Derivatives
    class Constants
      COPY_TYPES = {}
      COPY_TYPES['access'] = { :width => 1800,
                               :height => 5000,
                               :extension => 'jpeg',
                               :quality => 90
      }
      COPY_TYPES['preview'] = { :width => 3500,
                                :height => 7000,
                                :extension => 'jpeg',
                                :quality => 90
      }
      COPY_TYPES['preview_thumbnail'] = { :width => 500,
                                          :height => 800,
                                          :extension => 'jpeg',
                                          :quality => 90
      }
      COPY_TYPES['thumbnail'] = { :width => 200,
                                  :height => 200,
                                  :extension => 'jpeg',
                                  :quality => 90
      }
      COPY_TYPES['default'] = { :width => 100,
                                :height => 100,
                                :extension => 'jpeg',
                                :quality => 90
      }
    end
  end
end
