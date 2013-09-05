# -*- coding: utf-8 -*-
require 'rubygems'
require 'bundler/setup'
$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'google/blog/searcher'

describe Google::Blog::Searcher::Parser do
  describe '#parse' do
    let(:parser){ Google::Blog::Searcher::Parser }
    it "can parse with words" do
      parser.parse(["coffee", "delicious"]) {should be_kind_of Array}
    end
  end
end
