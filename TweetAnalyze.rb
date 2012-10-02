#!/usr/bin/env ruby -Ku
# -*- coding: utf-8 -*-
require "rubygems"
require "twitter"
require 'nkf'
require 'sqlite3'

require_relative 'easymecab'
require_relative 'InitDB'

# Rubyで半角カタカナを全角カタカナに、全角英数字を半角英数字に変換する
# from http://d.hatena.ne.jp/haroperi/20110804/1312469988
class String
  def normalize
    # -W1: 半カナ->全カナ, 全英->半英,全角スペース->半角スペース
    # -Ww: specify utf-8 as  input and output encodings
    NKF::nkf('-Z1 -Ww', self)
  end
end

class TweetAnalyze
  def initialize(dbfile)
    #sqliteまわりの設定
    initdb = InitDB.new(dbfile) unless FileTest.file?(dbfile)
    @db = SQLite3::Database.new(dbfile)
    @db.cache_size = 80000 # PRAGMA page_countを見て、とりあえずそれより大きい値を設定
  end
  
  def closeDB
    @db.close
  end


  def get_tweet(tag)
    #「#オリンピック」をキーワードで検索して日本語のもののみ取得する
    for i in 1..15
#    for i in 1..2
     Twitter.search(tag, :lang=>"ja", :page=>i, :rpp=>100).results.map do |r|
#      Twitter.search(tag, :lang=>"ja", :page=>i, :rpp=>10).results.map do |r|
#        p "#{r.created_at}:#{r.from_user}:#{r.text.normalize}"
        #    p "#{r.text.normalize}"
        store("#{r.created_at}:#{r.from_user}:#{r.text.normalize}", r.text.normalize)
      end
    end
  end

  def wakati(text) # 分かち書き
    m = MeCab.new("")
#    n = m.parse(text)
#    words = m.strip_by_wordclass(n)
#    p words
    return m.parse(text)
  end

  def store(fulltext, text)
    doc_id = setDocId(fulltext)
    words = wakati(text)
    words.each{|word|
      # 原型を取りたい
      next if word["feature"] == "の"
      next if word["feature"] == "で"
      next if word["feature"] == "が"
      next if word["feature"] == "。"
      next if word["feature"] == "、"
      next if word["feature"] == "."
      next if word["feature"] == ","
      next if word["feature"] == "EOS"
      next if word["wordclass"] =~ /括弧/
      next if word["wordclass"] =~ /句点/
      next if word["wordclass"] =~ /読点/
      next if word["wordclass"] =~ /数/
      next if word["wordclass"] =~ /代名詞/
#      next unless word["wordclass"] =~ /名詞/
      kw_id = setKeywordId(word["feature"])
#      print kw_id, word_feature["feature"], "\n"
      storeTF(kw_id)
      storeDocBody(doc_id, kw_id)
    }
    
  end

  def setDocId(tweet)
    # DocIDを割り付ける
    doc_id = 0
    @db.transaction do
      sql = "insert into docs(tweet) values(:tweet)"
      @db.execute(sql, :tweet => tweet)
      sql = "select LAST_INSERT_ROWID()"
      doc_id = @db.get_first_value(sql)
    end

    return doc_id
  end
  
  def setKeywordId(keyword)
    # KeywordIDを割り付ける
    kw_id = 0
    @db.transaction do
      sql = "select kw_id from keywords where word = :word"
      kw_id = @db.get_first_value(sql, :word => keyword)
      if kw_id == nil then
        sql = "insert into keywords(word) values(:word)"
        @db.execute(sql, :word => keyword)
        sql = "select LAST_INSERT_ROWID()"
        kw_id = @db.get_first_value(sql)
      end
    end
    
    return kw_id
  end
  
  def storeDocBody(doc_id, kw_id)
    @db.transaction do
      sql = "insert into bodytext values(:doc_id, :kw_id)"
      @db.execute(sql, :doc_id => doc_id, :kw_id => kw_id)
    end
  end
  
  def storeTF(kw_id)
    @db.transaction do
      sql = "select count from tf where kw_id = :kw_id"
      count = @db.get_first_value(sql, :kw_id => kw_id)
      if count == nil then
        count = 1
        sql = "insert into tf(kw_id, count) values(:kw_id, :count)"
        @db.execute(sql, :kw_id => kw_id, :count => count)
      else
        count = count + 1
        sql = "update tf set count = :count where kw_id = :kw_id"
        @db.execute(sql, :kw_id => kw_id, :count => count)
      end
#      print kw_id, ",", count, "\n"
    end
  end
  
  def setDF_table(db)
    db.execute("delete from df")
    sql = <<SQL
insert into df(kw_id, count)
 select kw_id, count(*) as count from
(select DISTINCT * from bodytext)
 group by kw_id;
SQL
    db.execute(sql)
  end
  
  def showTF(filename)
    File.open(filename, "w"){|f|
      f.print "show TF\n"
      @db.execute("select keywords.word, tf.count from tf, keywords where tf.kw_id = keywords.kw_id order by tf.count desc"){|word, count|
        f.print word, ",", count, "\n"
      }
    }
  end

  def showDF
    print "show DF\n"
    @db.execute("select * from df"){|doc_id, count|
      print doc_id, ",", count, "\n"
    }
  end

  def showBodyText
    print "show bodytext"
    @db.execute("select * from bodytext"){|doc_id, kw_id|
      print doc_id, ",", kw_id, "\n"
    }
  end

  def outputNet(filename)
    outputVertices(filename);
    outputEdges(filename);
  end

  def outputVertices(filename)
    File.open(filename, "w"){|f|
      @db.transaction do
        sql = "select count from tf"
        count = @db.get_first_value(sql)
        f.print "*Vertices ", count, "\n";
        
        @db.execute("select keywords.kw_id, keywords.word, tf.count from tf, keywords where tf.kw_id = keywords.kw_id order by tf.count desc"){|id, word, count|
          f.print id, " \"", word, " \"\n"
        }
      end
      f.print "\n"
    }
  end
  
  def outputEdges(filename)
    File.open(filename, "a"){|f|
      edges = Hash.new()
      @db.execute("select b1.kw_id, b2.kw_id from bodytext as b1, bodytext as b2 where b1.kw_id < b2.kw_id and b1.doc_id = b2.doc_id"){|kw_id1, kw_id2|
        if edges.has_key?(kw_id1.to_s + " " + kw_id2.to_s)
          edges[kw_id1.to_s + " " + kw_id2.to_s] =  edges[kw_id1.to_s + " " + kw_id2.to_s] + 1
        else
          edges[kw_id1.to_s + " " + kw_id2.to_s] = 1
        end
      }
      f.print "*Edges\n"
      edges.each{|edge, count|
        f.print edge, " ", count.to_f, "\n"
      }
    }
  end
end

if $0 == __FILE__

  day = Time.now
  basefilename = "tweets" + day.strftime("%Y%m%d%H%M%S")
  tweets = TweetAnalyze.new(basefilename + ".sqlite")
  tweets.get_tweet("#オリンピック")

  tweets.showTF(basefilename + ".txt")
#  tweets.showBodyText()
#  tweets.showDF()
#  tweets.showTFIDF()
  tweets.outputNet(basefilename + ".net")

#  tweets.closeDB()
end
