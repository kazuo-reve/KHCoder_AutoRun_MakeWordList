# ���ޥ�ɥ饤�󤫤��kh_coder.exe -auto_run �ƥ����ȥե�����̾�פΤ褦�˵�ư����ȡ��ʲ���¹Ԥ��롣
# 1. KH Coder�ǥץ������Ȥ����
# 2. ʣ���ꥹ�Ȥ����
# 3. ��и�ꥹ�Ȥκ���
# �ץ������Ȥ����������и�ꥹ�Ȥ��������Ƥ��ޤ����ᡢ�ץ������Ȥκ�������ϰ�ö�����ȥ����Ȥ��Ƥ��롣

import csv;

package auto_run;

sub plugin_config{

	# ��ư������Ԥ����ɤ���Ƚ��
	if ( defined($ARGV[0]) && defined($ARGV[1]) && $ARGV[0] eq '-auto_run' && -e $ARGV[1] ){
		
		# �ե�����̾����
		my $file_target = $ARGV[1];
		my $file_save   = 'net.png';

		# �ץ������ȿ�������
		my $new = kh_project->new(
		    target => $file_target,
		    comment => 'auto',
		) or die("could not create a project\n");
		kh_projects->read->add_new($new) or die("could not save the project\n");

		# �������������ץ������Ȥ򳫤�
		$new->open or die("could not open the project\n");
		$::project_obj->morpho_analyzer_lang( 'jp' );
		$::project_obj->morpho_analyzer( 'chasen' );

		# ʣ���ꥹ�Ȥ��������
		use mysql_hukugo;
		mysql_hukugo->run_from_morpho;
		
		# ʣ���ꥹ�Ȥ�Excel�ե������CSV�ե�������Ѵ�
		my $target_excel = $::project_obj->file_HukugoList;
		my $file_vars = "hukugo.txt";
		use screen_code::rde_excel_to_csv;
		use rde_kh_spreadsheet;
		my $sheet_obj = rde_kh_spreadsheet->new($target_excel);
		my $header = screen_code::rde_excel_to_csv::save_excel_to_csv(
			$sheet_obj,
			filev    => $file_vars
		);
		
		# ʣ���ꥹ�Ȥ�CSV�ե�������ɤ߲ù�����������Ф����Υꥹ�Ȥ��������
		my @row;
		my @records;
		my $filename = "hukugo.txt";
		open (IN, "./$filename") or die("could not read file: $filenamer\n");
		while(<IN>){
			chomp;
			push(@row, $_);
		}
		close(IN);
		# �����ȥ�Ԥ�������1���ܤΤ���Ф�����ѽп����������ʣ������Τߤˤ����
		shift(@row);
		foreach(@row){
			my @column = split(/,/, $_);
			push(@records, "$column[0]");
		}
		# ʣ����ս�˥����Ȥ���
		@records = sort {$b cmp $a} @records;
		# ʣ���ꥹ�Ȥ�CSV�ե�����˽��᤹
		open(DATA, ">./$filename");
		print DATA "$_\n" foreach(@records);
		close(DATA);
		
		# �ե����뤫����ɤ߹��ߤǤζ�����Ф����λ���򤹤�
		my $win = gui_window::dictionary->open;
		$win->config->words_mk_file_chk(1);
		$win->config->words_mk_file("./$filename");
		$win->config->save;

		# �������¹�
		my $wait_window = gui_wait->start;
		&gui_window::main::menu::mc_morpho_exec;
		$wait_window->end(no_dialog => 1);
		
		# ��и�ꥹ�Ȥ�Excel�ǳ���
		my $target_file = mysql_words->word_list_custom(
			type  => 'def',
			num   => 'tf',
			ftype => 'xls',
		);
		gui_OtherWin->open($target_file);

		# �ץ������Ȥ��Ĥ���
		$::main_gui->close_all;
		undef $::project_obj;

		# �ץ������Ȥ���
		#�ʺǸ���ɲä����ץ������Ȥκ����
		# my $win_opn = gui_window::project_open->open;
		# my $n = @{$win_opn->projects->list} - 1;
		# $win_opn->{g_list}->selectionClear(0);
		# $win_opn->{g_list}->selectionSet($n);
		# $win_opn->delete;
		# $win_opn->close;

		# KH Coder��λ
		exit;
	
	}

	return undef;
}

1;
