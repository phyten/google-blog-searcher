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
        def self.parse(words=[])
          result = []
          [1, 11, 21, 31, 41, 51, 61, 71].each do |start|
            result.concat(_parse("https://www.google.co.jp/search?tbm=blg&hl=ja&q=#{words.join(' ')}&output=rss&start=#{start}&qscrl=1"))
            sleep(60)
          end
          result.each do |item|
            item[:xvideos_links] = _xvideos(item[:link])
            item[:xvideos_links] = item[:xvideos_links].exclude_bad_links unless item[:xvideos_links].blank?
          end
          result.delete_if {|item| item[:xvideos_links].blank?}
        end
        private
        def self._parse(url)
          # URLへアクセスしページを取得
          begin
            useragent = "Mac Safari"
            mechanize = Mechanize.new
            mechanize.read_timeout = 20
            mechanize.max_history = 1
            mechanize.user_agent = useragent
            page = mechanize.get(url)
            content = page.content.to_s.toutf8
          rescue Exception => e
            puts e
            return Array.new
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

class Array
  def exclude_bad_links
    useragent = "Mac Safari"
    mechanize = Mechanize.new
    mechanize.read_timeout = 20
    mechanize.max_history = 10
    mechanize.user_agent_alias = useragent
    self.inject(Array.new) do |result, link|
      result ||= []
      xvideos_number = link.scan(/[0-9].+?$/).first.to_i
      url = "http://jp.xvideos.com/video#{xvideos_number}/"
      begin
        page = mechanize.get(url)
        content = page.content.to_s.toutf8
      rescue Exception
        STDERR.puts "#{link} is not found."
        next
      end
      if content =~ /Sorry, this video is not available/
        STDERR.puts "#{link} is not found."
        next
      else
        STDERR.puts "#{link} is found."
        result.push(link)
      end
    end
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
