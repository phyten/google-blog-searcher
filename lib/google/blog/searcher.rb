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
      class Parser
        attr_accessor :result, :scraper
        def initialize
        end
        def search(words=[], sleep_time=60, step=71)
          # googleから検索したいブログを割り出す
          @results = []
          1.step(step, 10).each do |start|
            @results.concat(_parse("https://www.google.co.jp/search?tbm=blg&hl=ja&q=#{words.join(' ')}&output=rss&start=#{start}&qscrl=1"))
            sleep(sleep_time)
          end
          @results.delete_if {|item| item[:title] !~ /#{words.first}/i}
          @results
        end
        def xvideos_with_title(link)
          @scraper = Scraper::Core.new
          @scraper.url = link.to_s.toutf8
          begin
            @scraper.reload
            res = @scraper.content.xvideos.exclude_bad_links_and_add_thumbnail
            if res.present?
              return { links: res, title: @scraper.title }
            else
              return nil
            end
          rescue Exception
            return nil
          end
        end
        private
        def _parse(url)
          # URLへアクセスしページを取得
          begin
            page = OpenURI.open_uri(URI.encode(url))
            content = page.read.to_s.toutf8
            page = nil
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
  def exclude_bad_links_and_add_thumbnail
    links = self.inject(Array.new) do |result, link|
      result ||= []
      xvideos_number = link.scan(/[0-9].+?$/).first.to_i
      url = "http://jp.xvideos.com/video#{xvideos_number}/"
      begin
        page = OpenURI.open_uri(url)
        content = page.read
      rescue Exception
        STDERR.puts "#{link} is not found."
        next
      end
      if content =~ /Sorry, this video is not available/
        STDERR.puts "#{link} is not found."
        next
      else
        STDERR.puts "#{link} is found."
        scraper = Hpricot content
        thumbnail = scraper.search("div#videoTabs ul.tabButtons li#tabVote img").first[:src].to_s.toutf8
        result.push({link: link, thumbnail: thumbnail})
      end
    end
    page = nil
    content = nil
    scraper = nil
    links
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
