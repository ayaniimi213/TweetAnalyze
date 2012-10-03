TweetAnalyze
============

Twitterとオリンピックの関係

Twitter上でオリンピックに関してつぶやかれています。
どのような話題がつぶやかれているのか、分析してみました。
グラフは、いっしょにつぶやかれているキーワードを線で結んだものです。

TweetAnalyze.rbの
  tweets.get_tweet("#オリンピック")
でオリンピックのハッシュタグのTweetのみをTwitterから取り込みます。
取り込むTweet数は
  def get_tweet(tag)
内で指定します。(iとrpp)

取り込んだTweetをSqliteを使ってDBに格納した後、TF-IDFによりキーワードを抽出、キーワード間の相関ルールを作成します。

結果を.net形式で出力します。
.net形式は、グラフソフトPajekのフォーマットですが、gephiなど他のグラフソフトでも参照できるかと思います。

