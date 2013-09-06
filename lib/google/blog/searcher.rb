# -*- coding: utf-8 -*-
require "google/blog/searcher/version"

require 'rubygems'
require "rss/maker"
require 'open-uri'
require "kconv"
require 'rss'
require 'mechanize'
require 'scraper'


module Google
  module Blog
    module Searcher
      class Core
        
      end
      class Parser
        def self.parse(words=[], start=1)
          _parse("https://www.google.co.jp/search?tbm=blg&hl=ja&q=#{words.join(' ')}&output=rss&start=#{start}")
        end
        private
        def self._parse(url)
          # URLへアクセスしページを取得
          begin
            useragent = 'Mac Safari'
            mechanize = Mechanize.new
            mechanize.read_timeout = 20
            mechanize.max_history = 1
            mechanize.user_agent_alias = useragent
            page = mechanize.get(url)
            content = page.content.to_s.toutf8
          rescue Exception
            return nil
          end
          # XMLをパース
          rss = nil
          begin
            rss = RSS::Parser.parse(content)
          rescue RSS::InvalidRSSError
            rss = RSS::Parser.parse(content, false)
          end
          rss.items.map do |item|
            {
              title: item.title.exclude_tag,
              description: item.description.exclude_tag,
              link: item.link,
              publisher: item.dc_publisher,
              creator: item.dc_creator,
              date: item.dc_date,
            }
          end
        end
        private
        def self._xvideos(link)
          scraper = Scraper::Core.new
          scraper.url = link.to_s.toutf8
          begin
            scraper.reload            
            return scraper.content.xvideos
          rescue Exception
            return nil
          end          
        end
      end
    end
  end
end

class String
  def exclude_tag
    self.gsub(/<[^<>]*>/,"")
  end
end

module Hpricot
  class Doc
    def xvideos
      search('iframe[@src*="flashservice.xvideos.com"]').map do |iframe|
        iframe[:src].to_s.toutf8
      end
    end
  end
end
