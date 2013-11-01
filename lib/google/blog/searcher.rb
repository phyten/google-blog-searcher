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
        attr_accessor :result, :scraper, :hpricot_scraper
        def initialize
          useragent = 'Mac Safari'
          @mechanize = Mechanize.new
          @mechanize.read_timeout = 60
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
          rescue Exception => e
            puts e
            return nil
          end
        end
        def fc2_with_title(link)
          @scraper.url = link.to_s.toutf8
          begin
            @scraper.reload
            res = exclude_bad_links_and_add_thumbnail_for_fc2(@scraper.content.fc2)
            if res.present?
              return { links: res, title: @scraper.title }
            else
              return nil
            end
          rescue Exception => e
            puts e
            return nil
          end
        end
        def exclude_bad_links_and_add_thumbnail(before_links)
          links = Array.new
          before_links.each do |link|
            xvideos_number = link.scan(/[0-9].+?$/).first.to_i
            url = "http://jp.xvideos.com/video#{xvideos_number}/"
            begin
              page = @mechanize.get(url)
              content = page.content.to_s.toutf8
            rescue Exception => e
              STDERR.puts "#{link} is fucked.#{e}"
              next
            end
            if content =~ /Sorry, this video is not available/
              STDERR.puts "#{link} is not found."
              next
            else
              STDERR.puts "#{link} is found."
              @hpricot_scraper = Hpricot content
              thumbnail = scraper.search("div#videoTabs ul.tabButtons li#tabVote img").first[:src].to_s.toutf8
              links.push({link: link, thumbnail: thumbnail})
            end
          end
          links
        end
        def exclude_bad_links_and_add_thumbnail_for_fc2(before_links)
          links = Array.new
          before_links.each do |link|
            url = link
            begin
              page = @mechanize.get(url)
              content = page.content.to_s.toutf8
            rescue Exception
              STDERR.puts "#{link} is not found."
              next
            end
            if content =~ /このコンテンツは既に削除されているか、あるいは作成者によって公開禁止に設定されています。/
              STDERR.puts "#{link} is not found."
              next
            else
              STDERR.puts "#{link} is found."
              scraper = Hpricot content
              thumbnail = scraper.search('meta[@content*="thumb"]').first[:content].to_s.toutf8
              links.push({link: link, thumbnail: thumbnail})
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
    def fc2
      # res = search('object embed[@src*="video.fc2.com"]').map do |embed|
      #   embed[:src].to_s.scan(/flv2\.swf\?i=([a-zA-Z0-9].+?)/).first.toutf8
      # end
      # res.concat(
      #            search('script[@url*="video.fc2.com"]').map do |script|
      #              script[:url].to_s.scan(/ja\/a\/content\/([a-zA-Z0-9].+?)/).first.toutf8
      #            end
      #            )
      search('script[@url*="video.fc2.com"]').map do |script|
        "http://video.fc2.com/ja/a/content/" + script[:url].to_s.scan(/content\/([a-zA-Z0-9].+?)\//).first.first.toutf8
      end
    end
  end
end
