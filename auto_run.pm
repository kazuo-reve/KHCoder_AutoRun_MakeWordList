# コマンドラインから「kh_coder.exe -auto_run テキストファイル名」のように起動すると、以下を実行する。
# 1. KH Coderでプロジェクトを作成
# 2. 複合語リストを作成
# 3. 抽出語リストの作成
# プロジェクトを削除すると抽出語リストが削除されてしまうため、プロジェクトの削除処理は一旦コメントアウトしている。

import csv;

package auto_run;

sub plugin_config{

	# 自動処理を行うかどうか判断
	if ( defined($ARGV[0]) && defined($ARGV[1]) && $ARGV[0] eq '-auto_run' && -e $ARGV[1] ){
		
		# ファイル名指定
		my $file_target = $ARGV[1];
		my $file_save   = 'net.png';

		# プロジェクト新規作成
		my $new = kh_project->new(
		    target => $file_target,
		    comment => 'auto',
		) or die("could not create a project\n");
		kh_projects->read->add_new($new) or die("could not save the project\n");

		# 新規作成したプロジェクトを開く
		$new->open or die("could not open the project\n");
		$::project_obj->morpho_analyzer_lang( 'jp' );
		$::project_obj->morpho_analyzer( 'chasen' );

		# 複合語リストを作成する
		use mysql_hukugo;
		mysql_hukugo->run_from_morpho;
		
		# 複合語リストのExcelファイルをCSVファイルに変換
		my $target_excel = $::project_obj->file_HukugoList;
		my $file_vars = "hukugo.txt";
		use screen_code::rde_excel_to_csv;
		use rde_kh_spreadsheet;
		my $sheet_obj = rde_kh_spreadsheet->new($target_excel);
		my $header = screen_code::rde_excel_to_csv::save_excel_to_csv(
			$sheet_obj,
			filev    => $file_vars
		);
		
		# 複合語リストのCSVファイルを読み加工し、強制抽出する語のリストを作成する
		my @row;
		my @records;
		my $filename = "hukugo.txt";
		open (IN, "./$filename") or die("could not read file: $filenamer\n");
		while(<IN>){
			chomp;
			push(@row, $_);
		}
		close(IN);
		# タイトル行を削除し、1列目のみ抽出する（頻出数の列を削除し複合語の列のみにする）
		shift(@row);
		foreach(@row){
			my @column = split(/,/, $_);
			push(@records, "$column[0]");
		}
		# 複合語を逆順にソートする
		@records = sort {$b cmp $a} @records;
		# 複合語リストのCSVファイルに書き戻す
		open(DATA, ">./$filename");
		print DATA "$_\n" foreach(@records);
		close(DATA);
		
		# ファイルからの読み込みでの強制抽出する語の指定をする
		my $win = gui_window::dictionary->open;
		$win->config->words_mk_file_chk(1);
		$win->config->words_mk_file("./$filename");
		$win->config->save;

		# 前処理実行
		my $wait_window = gui_wait->start;
		&gui_window::main::menu::mc_morpho_exec;
		$wait_window->end(no_dialog => 1);
		
		# 抽出語リストをExcelで開く
		my $target_file = mysql_words->word_list_custom(
			type  => 'def',
			num   => 'tf',
			ftype => 'xls',
		);
		gui_OtherWin->open($target_file);

		# プロジェクトを閉じる
		$::main_gui->close_all;
		undef $::project_obj;

		# プロジェクトを削除
		#（最後に追加したプロジェクトの削除）
		# my $win_opn = gui_window::project_open->open;
		# my $n = @{$win_opn->projects->list} - 1;
		# $win_opn->{g_list}->selectionClear(0);
		# $win_opn->{g_list}->selectionSet($n);
		# $win_opn->delete;
		# $win_opn->close;

		# KH Coderを終了
		exit;
	
	}

	return undef;
}

1;
