KUSANAGIでのRedmine構築方法

1. 事前にredmine以下をcheckoutします。
2. tarballを使う場合は、https://github.com/redmine/redmine/archive/3.4.6.zip からファイルをダウンロードします。
3. Vagrantを使用する場合は、適宜Vagrantの設定(メモリ、使用IPアドレスなど)を変更します。
4. kusanagi init を実施済みの場合は、setup_redmine.shの該当部分をコメントアウトします。
5. Vagrantの場合はvagrant up を実施します。
6. KUSANAGI環境からセットアップするときは、setup_redmine.sh、ar_innodb_row_format.rbなどを配置し、sh で setup_redmine.sh を起動します。

