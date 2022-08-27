# 作業メモ
自分の操作のメモを途中からだがつけていく。

## コマンドなどのメモ

0. テストを実行できるようにする。
フォークしたリポジトリからクローンして、README.mdの通りセットアップ。  

scaffoldでひな形を作る。
マイグレーションファイルがあったが、とりあえずそれを無視してやってみる。以下を実行
```
    docker compose exec web rails  generate scaffold movie name:string year:string description:text image_url:string is_showing:boolean
```
これで一通り土台はできた。localhost:3000で接続しようとしたがエラーが出た。調べたら以下が出た。
> -  [https://k-koh.hatenablog.com/entry/2020/02/06/103517](https://k-koh.hatenablog.com/entry/2020/02/06/103517)  
db:migrateしたら解決するらしい。早速やる。
```
    docker compose exec web rails db:migrate
    == 20220826173354 CreateMovies: migrating =====================================
    -- create_table(:movies)
    rails aborted!
    StandardError: An error has occurred, all later migrations canceled:
    Mysql2::Error: Table 'movies' already exists
    /app/db/migrate/20220826173354_create_movies.rb:3:in `change'
    /app/bin/rails:5:in `<top (required)>'
    /app/bin/spring:10:in `block in <top (required)>'
    /app/bin/spring:7:in `tap'
    /app/bin/spring:7:in `<top (required)>'
    Caused by:
    ActiveRecord::StatementInvalid: Mysql2::Error: Table 'movies' already exists
    /app/db/migrate/20220826173354_create_movies.rb:3:in `change'
    /app/bin/rails:5:in `<top (required)>'
    /app/bin/spring:10:in `block in <top (required)>'
    /app/bin/spring:7:in `tap'
    /app/bin/spring:7:in `<top (required)>'
    Caused by:
    Mysql2::Error: Table 'movies' already exists
    /app/db/migrate/20220826173354_create_movies.rb:3:in `change'
    /app/bin/rails:5:in `<top (required)>'
    /app/bin/spring:10:in `block in <top (required)>'
    /app/bin/spring:7:in `tap'
    /app/bin/spring:7:in `<top (required)>'
    Tasks: TOP => db:migrate
    (See full trace by running task with --trace)
```
失敗が2点、データベースがsqlite3になっている（デフォルトのままだった）。当然前にあったマイグレーションファイルと衝突する。なので作り直す。  
作り直しの際の参考。
> - [https://mebee.info/2021/01/24/post-28301/](https://mebee.info/2021/01/24/post-28301/)  
以下を実行
```
    docker compose exec web rails destroy scaffold  movie
```
scaffoldが消えた。＋最初のマイグレーションファイルは維持。  
scaffoldコマンドに1．データベースをMySQLに指定、2.マイグレーションファイルの作成をしない。としてやってみる。データベースの指定をしたことがなかったのでrailsドキと、[https://zenn.dev/nobokko/articles/tech_ruby_rails_mysql_table](https://zenn.dev/nobokko/articles/tech_ruby_rails_mysql_table)を参考にし
```
    docker compose exec web rails  generate scaffold movie -db=mysql -migration false
```
これだとほとんど何も動かなかった。以下を試す。
```
    docker compose exec web rails  generate scaffold movie name:string year:string description:text image_url:string is_showing:boolean -db=mysql ration false
```
上でも変だった。最後のfalseの前に=をつけるとうまくいった。もう一度以下を試す。
```
    docker compose exec web rails  generate scaffold movie -db=mysql -migration=false
```
うまくいった。と思ったら、普通にマイグレーションファイルが生成されている。キーだけない。  
あまりよくない方法だが、今回作られたマイグレーションファイルに元のマイグレーションファイルを一部コポーしようと思う。今回はこうするが、いずれ学習してどうすればいする。
マイグレーションファイルを書き込もうとしたが権限がなかった。ゆえに書き込みに行く。  
書き込みにログインしてvimを起動しようとしたがvimがなかった。一時的に権限を変えてみる。以下参考
> - [https://qiita.com/shisama/items/5f4c4fa768642aad9e06](https://qiita.com/shisama/items/5f4c4fa768642aad9e06)
```
    chmod 644 20220826181018_create_movies.rb
```
これはダメだったので、sudo で試す。
```
    sudo chmod 644 20220826181018_create_movies.rb 
```
一応通ったが、クライアント側だということを忘れていた。そのため変化がなかった。以下を試す。
```
    sudo chmod 666 20220826181018_create_movies.rb 
    -rw-rw-rw- 1 root    20220826181018_create_movies.rb
```
OKだが、後で以下をして元に戻す。
```
    sudo chmod 644 20220826181018_create_movies.rb
```
もともとあったマイグレーションファイルは、テーブルが衝突するので削除する。（gitでファイルの存在は守られているのでOKとする）
```
    rm -v 20190105082551_create_movie.rb
```
データベースを再度作り直す。
```
    docker compose exec web rails db:drop とタイプすると以下が出た。
        Dropped database 'app_development'
        Dropped database 'app_test'
```
データベースを作る。始めのREADME.mdを参考に、以下を実行。
```
    docker compose exec web rails db:create
    docker compose exec web rails db:migrate
```
データベースができた。これでもともとあったファイルと新しく作ったscaffoldにより生成されたファイルが結合できたのでhttp://localhost:3000/moviesと接続できるは
→　OK接続できた。ビューテンプレートで生成されたものが表示されたので一応成功のはず。
この段階で、一度テスト（VSCode上にある　「できた！」を押す）をしてみる。以前は有効なテストがありませんという回答が出た。

今回は違った。失敗と出たが有効なテストができる状態にセットアップできた。  

今回は、scaffoldで土台を作って、もともとあるファイルの内容だけ移植した。あまりよくない方法だが、現状の最善の方法として採用した。加えてルーティングも解決してくれるので最短でセットアップできる点からも、scaffoldは採用したかった。しかし別の方法も重要なので後で調べる。  
(モデルとマイグレーションファイルを別々に作成してそれらを関連づける方法を調べる。)

1. station 1
前述で最低限の土台を作ることができた。ここからは仕様に従って実装を進める。

仕様によれば、映画のタイトルと画像を絞り込みなしにすべて表示するとある。ビューの作りこみなどは指定されていないのでここでは簡単に表に並べて表示してみる。

### データの準備と中身の確認(CLIでデータベースの中身を見る)
その前に、データがないと始まらないのでデータを用意する。  
と思ったがフィクスチャファイルがなかった。scaffoldで用意されるはずだが、なぜかない。マイグレーションファイルを除外した影響だろうか？一度やり直してみる。
```
docker compose exec web rails destroy scaffold movie
docker compose exec web rails  generate scaffold movie -db=mysql
docker compose exec web rails db:drop
docker compose exec web rails db:create
docker compose exec web rails db:migrate
```
これでも生成されなかった。調べたところどうやらconfig/application.rbで設定されているそうだ。しかしその設定の内容がテストなどを記述する設定とかぶっているらしいので自分で作るのがいいと思う。
```
touch test/fixtures/movies.yml 
```

このymlファイルを編集してデータベースにデータを流し込む。書き方は以下を参考。  
> - [https://qiita.com/itkrt2y/items/ca34fea17fc7dde56b7a](https://qiita.com/itkrt2y/items/ca34fea17fc7dde56b7a)
> - [https://circleci.com/ja/blog/what-is-yaml-a-beginner-s-guide/](https://circleci.com/ja/blog/what-is-yaml-a-beginner-s-guide/)

要約すると以下の通りに書く。
```
active_record_name:
    key0: value0
    key1: value1
    key2: value2
        .
        .
        .
    key_n: value_n
```
権限を確認すると書き込み権限がないので前と同様に権限を変える。
```
    cd test/fixtures/
    sudo chmod 666 movies.yml
```
とりあえず適当に次の内容を書き込んだ。
```
movie_0:
  name: "movie_0"
  year: "xxxx-yy-zz"
  description: "description of movie_0"
  image_url: "URL_0"
  is_showing: true

movie_1:
  name: "movie_1"
  year: "xxxx-yy-zz"
  description: "description of movie_1"
  image_url: "URL_1"
  is_showing: true

movie_2:
  name: "movie_2"
  year: "xxxx-yy-zz"
  description: "description of movie_2"
  image_url: "URL_2"
  is_showing: true
```
フィクチャファイルができたのでデータを書き込みに行く。
```
    docker compose exec web rails db:fixtures:load FIXTURES=movies
```
とりあえず問題なく実行できた。うまくいっているか確認する。  http://localhost:3000/movies.json に接続して見る。

それらしいものは出たがデータの内容がよく見えなかったのでMySQLで直接コンソールから見てみる。
```
    docker compose exec web rails dbconsole
```
しかしうまくいかなかった。
```
    Couldn't find database client: mysql, mysql5. Check your $PATH and try again.
```
一度README.mdのコマンドを実行してみる。
```
    docker compose exec db mysql -uroot -ppassword -e 'show databases;';
```
結果は、README.mdの通り以下が出た。
```
mysql: [Warning] Using a password on the command line interface can be insecure.
+--------------------+
| Database           |
+--------------------+
| app_development    |
| app_test           |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
```
とりあえず調べたら以下がヒットした。
> - [https://zenn.dev/ryouzi/articles/a4fdff3c18e32a](https://zenn.dev/ryouzi/articles/a4fdff3c18e32a)  
結論はデータベースコンテナいログインして、その状態でMySQLで接続といった流れらしい。早速やってみる。
```
docker compose ps
NAME                   COMMAND                  SERVICE             STATUS              PORTS
rails-stations-db-1    "docker-entrypoint.s…"   db                  running             0.0.0.0:3306->3306/tcp, 33060/tcp
rails-stations-web-1   "entrypoint.sh bash …"   web                 running             0.0.0.0:3000->3000/tcp
```
データベースサーバはサービス名がdbなので以下を実行。
```
    docker compose exec db /bin/bash # -itを入れるとエラーが出た。
    #dbサーバにログイン完了。
    root@2f7a9d361d68:/# mysql -uroot -ppassword
    mysql: [Warning] Using a password on the command line interface can be insecure.
    Welcome to the MySQL monitor.  Commands end with ; or \g.
    Your MySQL connection id is 34
    Server version: 8.0.22 MySQL Community Server - GPL

    Copyright (c) 2000, 2020, Oracle and/or its affiliates. All rights reserved.

    Oracle is a registered trademark of Oracle Corporation and/or its
    affiliates. Other names may be trademarks of their respective
    owners.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    mysql> 
```
とりあえずログインはできた。一度データベースサーバに入るという操作が面倒なのでdocker composeで入れないだろうか？始めのREADME.mdを参考に以下を試す。
```
    docker compose exec db mysql -uroot -ppassword
```
うまくいった。あとはMySQLの使い方を調べてテーブルを確認してみる。手元の本（MySQL徹底入門）と以下を参考にコマンドを実行する。
> - [https://www.javadrive.jp/mysql/table/index2.html](https://www.javadrive.jp/mysql/table/index2.html)  

以下のコマンドを実行。
```
mysql> show tables;
ERROR 1046 (3D000): No database selected #データベースを選択？
```
データベースを選択とあるが、どれだろうと思いdocker-compose.ymlを見てみる。
```app_test```がデータベース名だろうか。追加で以下を調べた。
> - [http://mysql.javarou.com/dat/000393.html](http://mysql.javarou.com/dat/000393.html)  

以下のコマンドを試してみる。
```
show tables from app_test;
Empty set (0.00 sec)
```
データベースにデータを流したはずなのに表にデータがないといわれる。以下を調べた。
> - [https://www.javadrive.jp/mysql/database/index2.html](https://www.javadrive.jp/mysql/database/index2.html)  

```
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| app_development    |
| app_test           |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
6 rows in set (0.06 sec)
```
6つのデータベースがあるらしい。どれだろう？docker-compose.ymlのデータベース名であるapp_testは見えた。しかしデータがない。  
わからないので全部確認してみる。
```
mysql> show tables from app_development;
+---------------------------+
| Tables_in_app_development |
+---------------------------+
| ar_internal_metadata      |
| movies                    |
| schema_migrations         |
+---------------------------+
3 rows in set (0.06 sec)
```
と思ったが、始めのほうでmoviesがあった。なのでテーブルの中身を見てみる。参考は以下。
> - [https://oreno-it3.info/archives/853](https://oreno-it3.info/archives/853)  

コマンドは基本情報で勉強した内容とほとんど一緒だった。
```
mysql> select * from movies;
ERROR 1046 (3D000): No database selected
```
データベース選んでなかった。以下を参考。
> - [https://www.javadrive.jp/mysql/database/index3.html](https://www.javadrive.jp/mysql/database/index3.html)

```
mysql> use app_development;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> select * from movies;
+-----------+---------+------------+------------------------+-----------+------------+----------------------------+----------------------------+
| id        | name    | year       | description            | image_url | is_showing | created_at                 | updated_at                 |
+-----------+---------+------------+------------------------+-----------+------------+----------------------------+----------------------------+
| 100400098 | movie_2 | xxxx-yy-zz | description of movie_2 | URL_2     |          1 | 2022-08-27 06:01:01.275034 | 2022-08-27 06:01:01.275034 |
| 485665370 | movie_1 | xxxx-yy-zz | description of movie_1 | URL_1     |          1 | 2022-08-27 06:01:01.275034 | 2022-08-27 06:01:01.275034 |
| 737516241 | movie_0 | xxxx-yy-zz | description of movie_0 | URL_0     |          1 | 2022-08-27 06:01:01.275034 | 2022-08-27 06:01:01.275034 |
+-----------+---------+------------+------------------------+-----------+------------+----------------------------+----------------------------+
3 rows in set (0.01 sec)
```

とりあえず、データベースサーバへの接続、データベースの中身の表示と確認ができた。ひとまずフィクチャファイルの内容がしっかりと反映されていたので一安心。このデータベースをしっかりと選択して表示すれば問題ないはずなので引き続き取り組んでいこうと思う。

一応データベースに接続ということでメモをしておく。  
今回は、```docker compose exec db mysql -uroot -ppassword```でログインした。直接MySQLにログインした。その状態で```quit```した場合、直接ターミナルに戻ってきたのでこれはうれしかった。デーだベースサーバのターミナルを経由されるといったことがなかったので、今後接続するときは、```docker compose exec db mysql -uroot -ppassword```でログインして操作していきたいと思う。

これでデータの準備、中身の確認ができた。

### テーブルmoviesの中身をすべて表にして表示する
この操作は大きく2つの操作をする。
1. コントローラの確認。
2. ビューを編集。(index.html.erb)

上記の通り作業を進める。  

1. コントローラの確認。
確認した。以下の通り。(scaffoldで自動生成)
```
  # GET /movies or /movies.json
  def index
    @movies = Movie.all
  end
```
インスタンス変数@moviesにテーブルmoviesのすべてが入っている。今の課題は絞り込みなしですべて映画情報を表示するなのでこの状態のコントローラの設定で問題ない。

コントローラの確認はOK。

2. ビューを編集。(index.html.erb)
app/views/movies/index.html.erb を編集する。始めの方に表で表示するとしていたので、その方向で進めていく。

その前に一度現在の状態（ビューを編集する前）のコミットを作成しておく。今回リポジトリは自分のアカウントにフォークしているのでそのリポジトリにプッシュする。  
（認識が間違っていたら修正。フォークリポジトリにプッシュするのはOK。プルリクエストを送らなければ元のリポジトリが変になることはない。また、プルリクエストを送ってしまったとしても管理者が許可しない限り大丈夫。加えてフォーク元のリポジトリにプッシュしたとしても権限がないので問題は発生しないはず。）  
このあたりの知識が少ないので少し不安だが今回のケースは大丈夫だと思う。ゆえに実行する。
