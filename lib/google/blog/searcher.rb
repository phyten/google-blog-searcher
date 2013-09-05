require "google/blog/searcher/version"

require 'rubygems'
require "rss/maker"
require 'open-uri'
require "kconv"
require 'rss'


module Google
  module Blog
    module Searcher
      class Core
        
      end
    end
  end
end

class String
  def exclude_tag
    self.gsub(/<[^<>]*>/,"")
  end
end
