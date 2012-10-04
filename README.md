TweetAnalyze
============

2012/10/04

■ このプログラムは？

Twitterとオリンピックの関係

Twitter上でオリンピックに関してつぶやかれています。
どのような話題がつぶやかれているのか、分析してみました。
グラフは、いっしょにつぶやかれているキーワードを線で結んだものです。

■ 必要なもの

- ruby
- rubyライブラリ
  - rubygems
  - tempfile
  - nkf
  - sqlite3
  - twitter
- sqlite
- Mecab

rubygems, tempfileは標準的なrubyのインストールの場合、いっしょにインストールされているはず。

■ 設定

TweetAnalyze.rbの
  tweets.get_tweet("#オリンピック")
でオリンピックのハッシュタグのTweetのみをTwitterから取り込みます。
取り込むTweet数は
  def get_tweet(tag)
内で指定します。(iとrpp)

取り込んだTweetをSqliteを使ってDBに格納した後、TF-IDFによりキーワードを抽出、キーワード間の相関ルールを作成します。

結果を.net形式で出力します。
.net形式は、グラフソフトPajekのフォーマットですが、gephiなど他のグラフソフトでも参照できるかと思います。

■ 使い方

./TweetAnalyze.rb

実行すると、カレントディレクトリに日時を元にしたファイル名の.sqliteファイルと.netファイルが作成されます。
.sqliteファイルは、取り込んだTweetデータを格納したデータベースです。
.netファイルが、結果であるキーワードをノード、共起関係をリンクで表現したグラフのファイルです。.net形式は、グラフソフトPajekのフォーマットですが、gephiなど他のグラフソフトでも参照できるかと思います。

■ アルゴリズム

TweetAnalyze.rbの
  tweets.get_tweet("#オリンピック")
でオリンピックのハッシュタグのTweetのみをTwitterから取り込みます。
取り込むTweet数は
  def get_tweet(tag)
内で指定します。(iとrpp)

取り込んだTweetをSqliteを使ってDBに格納した後、TF-IDFによりキーワードを抽出、キーワード間の相関ルールを作成します。

相関ルールを下に、キーワードをノード、共起関係をリンクとしたグラフを作成します。

結果を.net形式で出力します。
.net形式は、グラフソフトPajekのフォーマットですが、gephiなど他のグラフソフトでも参照できるかと思います。
