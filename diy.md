# 作業メモ
自分の操作のメモを途中からだがつけていく。

# コマンドなどのメモ

## 0. テストを実行できるようにする。  
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
scaffoldコマンドに1．データベースをMySQLに指定、2.マイグレーションファイルの作成をしない。としてやってみる。データベースの指定をしたことがなかったのでrailsドキュメントと、[https://zenn.dev/nobokko/articles/tech_ruby_rails_mysql_table](https://zenn.dev/nobokko/articles/tech_ruby_rails_mysql_table)を参考にし
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
あまりよくない方法だが、今回作られたマイグレーションファイルに元のマイグレーションファイルを一部コピーしようと思う。今回はこうするが、いずれ学習してどうすればいする。
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
データベースができた。これでもともとあったファイルと新しく作ったscaffoldにより生成されたファイルが結合できたので(http://localhost:3000/movies)と接続できるはず  
→　OK接続できた。ビューテンプレートで生成されたものが表示されたので一応成功のはず。
この段階で、一度テスト（VSCode上にある　「できた！」を押す）をしてみる。以前は有効なテストがありませんという回答が出た。

今回は違った。失敗と出たが有効なテストができる状態にセットアップできた。  

今回は、scaffoldで土台を作って、もともとあるファイルの内容だけ移植した。あまりよくない方法だが、現状の最善の方法として採用した。加えてルーティングも解決してくれるので最短でセットアップできる点からも、scaffoldは採用したかった。しかし別の方法も重要なので後で調べる。  
(モデルとマイグレーションファイルを別々に作成してそれらを関連づける方法を調べる。)

## 1. station 1
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

結論はデータベースコンテナにログインして、その状態でMySQLで接続といった流れらしい。早速やってみる。
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

#### 1. コントローラの確認。
確認した。以下の通り。(scaffoldで自動生成)
```
  # GET /movies or /movies.json
  def index
    @movies = Movie.all
  end
```
インスタンス変数@moviesにテーブルmoviesのすべてが入っている。今の課題は絞り込みなしですべて映画情報を表示するなのでこの状態のコントローラの設定で問題ない。

コントローラの確認はOK。

#### 2. ビューを編集。(index.html.erb)
app/views/movies/index.html.erb を編集する。始めの方に表で表示するとしていたので、その方向で進めていく。

その前に一度現在の状態（ビューを編集する前）のコミットを作成しておく。今回リポジトリは自分のアカウントにフォークしているのでそのリポジトリにプッシュする。  
（認識が間違っていたら修正。フォークリポジトリにプッシュするのはOK。プルリクエストを送らなければ元のリポジトリが変になることはない。また、プルリクエストを送ってしまったとしても管理者が許可しない限り大丈夫。加えてフォーク元のリポジトリにプッシュしたとしても権限がないので問題は発生しないはず。）  
このあたりの知識が少ないので少し不安だが今回のケースは大丈夫だと思う。ゆえに実行する。

コミットをしたらなぜかテストが実行された。実行されても一応は問題ないので今回は無視する。

コミットの作成完了。ここからビューを編集していく。

自動生成されたビューは以下の通り。
```
<p id="notice"><%= notice %></p>

<h1>Movies</h1>

<table>
  <thead>
    <tr>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @movies.each do |movie| %>
      <tr>
        <td><%= link_to 'Show', movie %></td>
        <td><%= link_to 'Edit', edit_movie_path(movie) %></td>
        <td><%= link_to 'Destroy', movie, method: :delete, data: { confirm: 'Are you sure?' } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to 'New Movie', new_movie_path %>
```
不要そうなところがあるのでそれは消しておく。編集しようと思ったらまた権限がなかった。いつも通り変更する。  
また、表には枠があったほうがわかりやすいので、以下を参考に枠をつける。
> - [https://www.sejuku.net/blog/83489](https://www.sejuku.net/blog/83489)  

また、今回使用するデータは、nameキーとimage_urlキーである。ゆえにまずそれぞれを文字として表示する。erbファイルなのでコードは以下の通り。
```
    <% @movies.reverse.each do |movie| %>
      <tr>
        <td><%= movie.image_url %></td>
        <td><%= movie.name %></td>
      </tr>
    <% end %>
```
これで表示してみたところうまくいった。うまく0から順に上から表示され登録した文字列を文字としてきちんと表示することができた。  
あとは、URLを設定し、src属性で画像として表示する。画像は問題文の通りpicsum.photosを使用してみる。以下参考
> - [Lorem Picsum　〜とりあえず画像が欲しいあなたへ〜](https://qiita.com/MeJamoLeo/items/9c6b4f454f5531ead0c4)  

このサイトは公式サイトからとってきたものだが、
```
    https://picsum.photos/200/300
```
というURLを指定することで幅200、高さ300の画像をランダムに表示してくれる。これをデータベースに流すことで今回は対応しようと思う。

movies.ymlのimage_urlのデータを上記のURLに変更する。

内容を変更したので変更を反映する。
```
    docker compose exec web rails db:fixtures:load FIXTURES=movies
```
ブラウザで映画イメージの列が変わっているか確認する。  
→　OK。URLとして表示されている。次はタブの属性をsrcにする。

src属性の書き方を忘れた。以下参考。
> - [https://qumeru.com/magazine/462](https://qumeru.com/magazine/462)  

うまくいったが、3つとも同じ画像が出てきて変なので、少し変える。以下参考。
> - [【備忘録】ダミー画像「Lorem Picsum」でよく使う画像のID集](https://www.d-grip.com/blog/seisaku/5744)  

一応、これでタイトルと画像をデータベースに登録している数（3つ）だけすべて表示することができた。

これでテストしてみる。  
→　OKクリアできた。

### station 1 クリア
完全にrubyとRuby on Rails初見だったのでかなり時間がかかった。それ以外にも、docker composeとMySQLについても経験がなかったので調べるのにかなり時間がかかってしまった。しかし、一番初めの何を書いているか一切わからないといった状態からは抜け出すことができた？と思うので良しとしようと思う。

## staion 2
### 1. データベースの編集
テーブルにキーが追加されていたのでマイグレーションファイルを変更する。

わからないことがあったので調べた以下参考。
> - [Rails 5から導入されたmigration versioingについて](https://y-yagi.tumblr.com/post/137935511450/rails-5%E3%81%8B%E3%82%89%E5%B0%8E%E5%85%A5%E3%81%95%E3%82%8C%E3%81%9Fmigration-versioing%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6)  

```
ActiveRecord::Migration[6.1]
```
この6.1はバージョンを表していて本質的な意味はないようだ。  

また、マイグレーションファイルのカラム名は元のファイルを使用していたが、書き方が調べてた内容（railsドキュメント）と合わなかったので修正した。  
サーバに接続したところ問題なく表示されたのでOK。

マイクレーションファイルに登録日時と更新日時を追加する。データ型はstring型でいいだろうか？ひとまずは公開年とおなじ型にする。  
> - [マイグレーション(migration)](https://railsdoc.com/migration)  
利用可能なメソッドに型を指定して作成するメソッドがあるのでそれを参考にする。

また、最初のマイグレーションファイルのlimitは文字数（厳密には桁数）、commentはカラムのコメント、nullはNULL値を許可するかどうかでデフォルトはtrueである。それをもとに編集する。

編集後、マイグレーションファイルを実行して更新する。
```
  docker compose exec web rails db:migrate
```
フィクスチャファイルの編集がまだであったが、データベースを確認すると以下の通りになった。
```
mysql> use app_development
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> select * from movies;
+-----------+---------+------------+------------------------+----------------------------------+------------+----------------------------+----------------------------+
| id        | name    | year       | description            | image_url                        | is_showing | created_at                 | updated_at                 |
+-----------+---------+------------+------------------------+----------------------------------+------------+----------------------------+----------------------------+
| 100400098 | movie_2 | xxxx-yy-zz | description of movie_2 | https://picsum.photos/id/188/300 |          1 | 2022-08-27 15:16:47.833425 | 2022-08-27 15:16:47.833425 |
| 485665370 | movie_1 | xxxx-yy-zz | description of movie_1 | https://picsum.photos/id/180/300 |          1 | 2022-08-27 15:16:47.833425 | 2022-08-27 15:16:47.833425 |
| 737516241 | movie_0 | xxxx-yy-zz | description of movie_0 | https://picsum.photos/id/42/300  |          1 | 2022-08-27 15:16:47.833425 | 2022-08-27 15:16:47.833425 |
+-----------+---------+------------+------------------------+----------------------------------+------------+----------------------------+----------------------------+
3 rows in set (0.00 sec)
```
規定値？が入っている。おそらくキー属性に```null: false```にしていしているからであると思うが、規定値の設定はどこだろうか？  
以下参考。
> - [Docker で MySQL 起動時にデータの初期化を行う](https://qiita.com/moaikids/items/f7c0db2c98425094ef10)  

今回は、この問題はあまり考えないことにする。とりあえず何かしらの時間らしき文字列が入力されることととらえる。

これで一応データベースの方の設定はOKだとする。（少し解せないところはあるが、そこは本質ではなさそうなので飛ばす）

### 2. adminコントローラ
問題文を見ると、
 - `GET /admin/movies`で現在表示されているmoviesの内容をすべて表示する。

一応以下参考。
> - [rails g コマンドが行なっていること](https://diveintocode.jp/blogs/Technology/RailsGenerateCommand)  

 しかし心配なのは以下を実行するとコントローラ名が複数形になりそうだがどうなるだろうか？
 ```
 docker compose exec web rails generate controller admin
```
ルーティングを確認する。  
→　何もない。

本を参考にルーティングを設定。最適ではないが以下を設定する。
```
match ':controller/:action', via: [ :get, :post, :patch ]
```
その後、コントローラを設定。次を設定。
```
    #moviesデータベースと接続してデータを取り出す。
    def movies
        @movies = Movie.all
    end
```
と思ったが、ヒントをみたが意味が正確に理解できないので調べた。
> - [【初心者向け】管理者ユーザーと管理者用controllerの追加方法[Ruby, Rails]](https://qiita.com/sazumy/items/7ce8826615f1af605164)  
これも少し違う感じがする。

ゆえにadminコントローラの追加の仕方がちょっと変みたい。一度削除して再作成する。
```
docker compose exec web rails destroy controller admin
```

以下の記事を参考に次を試す。
> - [コントローラとビューの生成](https://railsdoc.com/page/rails_generate_controller)  

```
docker compose exec web rails generate controller 'admin/movie'
```
これでうまくいったかもしれない。書き込み権限をつける。
```
sudo chmod 666 movie_controller.rb
```
ルーティングの設定はresourcesメソッドでとりあえず設定して、コントローラの設定movieモデルと同じにしてやってみる。

これでコントローラからデータベースに接続ができるはずなので、station1のビューをコピーしてブラウザで表示してみる。  
ルーティングの設定でエラーが出たので調べた。
> - [https://qiita.com/ryosuketter/items/9240d8c2561b5989f049](https://qiita.com/ryosuketter/items/9240d8c2561b5989f049)  

どうやらnamespaceで反復するのがいいらしい。とりあえず以下を試してみる。
```
  namespace :admin do
    resources :movies
  end
```
しかしエラーが出た。以下参考。
> - [uninitialized constantのエラーをどう解決すべきか](https://qiita.com/imotan/items/c73fab5ee230114a08b6)  

単語の複数形がしっかりと指定できていない。調整する。
```
以下をリネーム
./app/controllers/admin/movie_contrller.rb → ./app/controllers/admin/movies_contrller.rb
./views/admin/movie → ./views/admin/movies
class Admin::MovieController < ApplicationController　を　class Admin::MoviesController < ApplicationController
```
これで一応表示ができた。  
表示ができたのでとりあえずはAdmin::MoviesControllerの作成はできた。

### 3. ビューの編集
表示内容を変える。

その前に一度テストを実行してみた。前回は有効なテストがないとエラーが出たがとりあえずテストが実行できる環境（Admin::MoviesControllerの設定？）ができた。おそらく各ステーションごとに何かしらテストを実行できるための設定があるのだろうか？

spec/station_Xを見に行く。
./spec/station02を見ると案の定`Admin::MoviesController`があったのでテストをするための設定はstationディレクトリのテストファイルを確認しに行くのがいいだろう。

ひとまず、現状の段階で記録をつけておく。

#### 表を作っていく
以下参考。ハイパーリンクの書き方を忘れていた。
> - [HTMLアンカーリンク（a hrefタグ）とは～使い方と別ページ（target blank）について](https://seolaboratory.jp/44165/#:~:text=%E3%82%A2%E3%83%B3%E3%82%AB%E3%83%BC%E3%83%AA%E3%83%B3%E3%82%AF%EF%BC%88a%E3%82%BF%E3%82%B0%EF%BC%89%E3%81%A8%E3%81%AF%E3%80%81%20HTML%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%AB,%E3%81%A6%E3%82%88%E3%81%8F%E5%88%A9%E7%94%A8%E3%81%95%E3%82%8C%E3%81%BE%E3%81%99%E3%80%82)  

と思ったが、railsはlink_toメソッドがあるのを忘れていた。以下参考。
> - [link_toメソッドを使ったリンクの作成](https://www.javadrive.jp/rails/template/index8.html)  

リンクの作成と表の列を増やす操作をした。

この状態でテストを実行  
→　OKクリアできた。

### station 2クリア
新しいコントローラの作成、既存のモデルとの連携、名前空間で同一アクションを区別する、そういった要素を実践する内容だった。一番難しかったのは名前空間付きでコントローラを作成するところだった。読んでいた本でもそういったことはなかった（はず…。）なので少し迷った。しかしネットで調べて何とかなったので良かった。

## 3. station 3
### バックエンド側の設定。
前のstationではコントローラを単体で作成した。ゆえに始めのようにnewアクションやcreateアクション、destroyアクションは作成されていない。ゆえにこれらに対して実装を施すことでクリアできると思う。

このヒントはstation 1で作成した、scafffoldによって自動生成されたものが参考になるだろう。```./app/views/movies/new.html.erb```が新しいデータを登録するためのテンプレートファイルである。

そのためまずは、始めの./app/views/movies/new.html.erb をコピーする。
```
sudo cp -v movies/new.html.erb admin/movies/
cd admin/movies/
sudo chmod 666 new.html.erb 
```
ルーティングは前回 `resources`メソッドを設定しているので、コントローラにnewアクションを設定すれば良いと思う。  
```
./config/routes.rb　の設定の一部
  namespace :admin do
    resources :movies
  end
```
念のため `./app/controllers/movies_controller.rb`を確認するとつぎのような設定だった。
```
  # GET /movies/new
  def new
    @movie = Movie.new
  end
```
これと同じ内容を設定する。(@movieが単数形になっているのが見落としてしまいそうだった。)  
とりあえずバックエンド側の設定は以上である。ここからはビューの設定をしていく。

### フロント側の設定。
ビューファイルをコピーしていたが、部分テンプレートの部分をコピーしていなかったのでコピーする。一応ビューの内容を表示する。
```
./app/views/admin/movies/new.html.erbの内容
<h1>New Movie</h1>

<%= render 'form', movie: @movie %>

<%= link_to 'Back', movies_path %>
```
部分テンプレートは、`sudo cp -v movies/_form.html.erb admin/movies/`でコピーしてきて、内容は
```
./app/views/admin/movies/_form.html.erbの内容

<%= form_with(model: movie) do |form| %>
  <% if movie.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(movie.errors.count, "error") %> prohibited this movie from being saved:</h2>

      <ul>
        <% movie.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```
といったようになっている。テンプレートの内容にデータベースのキーが入っていないのはscaffold機能で主キーを指定せずに作成したためであると考えられる。ゆえにまずこの部分テンプレートを編集して行こうと思う。

一度`http://localhost:3000/admin/movies/new`に接続すると単純なページが表示されていることが確認できた。ゆえに部分テンプレートファイル、_form.html.erbを編集してデータベースにデータを追加できるように設定する。  
railsの本を読んでるときに生成した_form.html.erbを開いて、参考にして記述する。

ひとまず最低限のフォームの作成はできた。仕様に合わせて、概要はテキストエリア、上映中はチェックボックス、公開年は数値、登録・更新日時は年月日と時間を指定できるように設定した。そのほかは改行なしのテキスト入力を受け付けるようにした。

ゆえにビューはできたはずだが、試しに実行したところエラーが出た。  
```
ActiveModel::ForbiddenAttributesError in MoviesController#create
ActiveModel::ForbiddenAttributesError
```
どうやらバックエンド側の設定が完了していると思ったがそうではないそうだ。再度バックエンドの設定をしていく。

### バックエンドの設定(再)
おそらく、adminの名前空間中にcreateメソッドが記述されていないことが原因だと思われる。そのため、始めに作ったmovieコントローラからcreateメソッドをコピーして持ってくるとうまくいくのではないだろうか？早速やってみる。

一応内容を記述する。
```
  # POST /movies or /movies.json
  def create
    @movie = Movie.new(movie_params)

    respond_to do |format|
      if @movie.save
        format.html { redirect_to @movie, notice: "Movie was successfully created." }
        format.json { render :show, status: :created, location: @movie }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end
```
やってみたが違うそうだ。エラーを見るとAdmin::MoviesController ではなく、 MoviesController  が呼び出されている。それが原因だと思われる。  
これは、おそらくビューで作成しているcrateボタンのURLが原因だと思われる。その周辺をしっかりと確認してみようと思う。

ページのソースを確認するとアクションの指定が間違っていた。正しく合わせられるように調整する。以下参考。
> - [モデルなどからフォームタグを生成](https://railsdoc.com/page/form_with)  

上記を参考に部分テンプレートの上部を以下のように編集。
```
<%= form_with(model: movie, url: "/admin/movies") do |form| %>
```
上記の内容で提出すると、以下のエラーが出る。
```
NameError in Admin::MoviesController#create
undefined local variable or method `movie_params' for #<Admin::MoviesController:0x0000000000f6e0>
```
これで指定のAdmin::MoviesControllerを使用することができたことはわかったが、以前のコピーがうまくいってない感じだった。エラー文を読むとmovie_paramsがないといっている。ゆえに元のMovieコントローラからその部分をコピーしてくる。以下に記す。
```
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_movie
      @movie = Movie.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def movie_params
      params.fetch(:movie, {})
    end
```
これでmovie_paramsの定義ができているはずなのでうまくいくはずだがどうだろう？

エラーが出る。以下エラー文
```
ActiveModel::ForbiddenAttributesError in Admin::MoviesController#create
ActiveModel::ForbiddenAttributesError
```
始めのエラーと同じエラーが出た。コントローラの設定がおかしいと思ったので別で実行して作成したコントローラと見比べるとmovie_paramsの書き方とcreateメソッドの書き方が違った。修正していこうと思う。

現在の状況を記録するために一度コミットとプッシュを行う。