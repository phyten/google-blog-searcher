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
          useragent = 'Mac Safari'
          @mechanize = Mechanize.new
          @mechanize.read_timeout = 20
          @mechanize.max_history = 1
          @mechanize.user_agent_alias = useragent
          @scraper = Scraper::Core.new
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
          @scraper.url = link.to_s.toutf8
          begin
            @scraper.reload
            res = exclude_bad_links_and_add_thumbnail(@scraper.content.xvideos)
            if res.present?
              return { links: res, title: @scraper.title }
            else
              return nil
            end
          rescue Exception
            return nil
          end
        end
        def exclude_bad_links_and_add_thumbnail(before_links)
          links = before_links.inject(Array.new) do |result, link|
            result ||= []
            xvideos_number = link.scan(/[0-9].+?$/).first.to_i
            url = "http://jp.xvideos.com/video#{xvideos_number}/"
            begin
              page = @mechanize.get(url)
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
              scraper = Hpricot content
              thumbnail = scraper.search("div#videoTabs ul.tabButtons li#tabVote img").first[:src].to_s.toutf8
              result.push({link: link, thumbnail: thumbnail})
            end
          end
          scraper = nil
          links
        end
        private
        def _parse(url)
          # URLへアクセスしページを取得
          begin
            page = @mechanize.get(url)
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
