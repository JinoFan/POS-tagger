#词性标注
print "Reading data...\n";
if ( ReadProb("lex.txt","transfer.txt") == -1 ){
	return;
}

while(1){#读取输入
	print "Pls input sentence(press q to exit!):\n";
	$Sent=<STDIN>;
	chomp($Sent);
	if ( $Sent eq "q" ){
		exit;
	}
	$TaggingResult=();
	POSTagging($Sent,\$TaggingResult);
	print "$TaggingResult\n";
}

sub ReadProb{#读取并存储转移概率及发射概率
	my($LexProb,$TransProb)=@_;
	open(FileIn,"$LexProb") or return -1;
	my $Word=();
	my %hashLexProb=();
	while(<FileIn>){
		chomp;
		if ( /^\#(.*)/ ){#词
			if ( length($Word) > 0 ){
				my %hashLexProbTmp=%hashLexProb;
				$LexiconProb{$Word}=\%hashLexProbTmp;
			}
			%hashLexProb=();
			$Word=$1;
		}else{
			if ( /(\S+) (\S+)/){#词性与发射概率
				$hashLexProb{$1}=$2;
			}
		}
	}
	
	$LexiconProb{$Word}=\%hashLexProb;#最后一个词的发射概率
	close(FileIn);
	
	open(FileIn,"$TransProb") or return -1;
	while(<FileIn>){
		chomp;
		if ( /(.*)\t(.*)/){
			$TransitionProb{$1}=$2;#转移概率
		}
	}
	close(FileIn);
	return 1;
}

sub POSTagging{#词性标注
	my ($Sent,$ResultRef)=@_;
	my @Lattice;
	BuildLattice($Sent,\@Lattice);#建立候选网格
	
	for($i=1;$i<@Lattice;$i++){
		my $PrevRef=$Lattice[$i-1];#@Column  每个Column对应一个词
		my $CurrRef=$Lattice[$i];#@Column
		
		for($j=0;$j<@{$CurrRef};$j++){#找候选词性
			my $MaxScore=-1.0e10;
			my $PrevIndex;
			my $CurrNode=${$CurrRef}[$j];#@Element
			for($k=0;$k<@{$PrevRef};$k++){
				my $PrevNode=${$PrevRef}[$k];#@Element
				$Score=GetTransitionProb($PrevNode->[1],$CurrNode->[1])+GetLexProb($CurrNode->[0],$CurrNode->[1])+$PrevNode->[2];#求解概率最大值
				if ( $Score > $MaxScore ){
					$MaxScore=$Score;
					$PrevIndex=$k;#记录这个@Element在@Column数组中的下标
				}
			}
			$CurrNode->[2]=$MaxScore;#概率
			$CurrNode->[3]=$PrevRef->[$PrevIndex];#回退指针,指向前一个@Column中的@Element
		}
	}
	
	BackWard(\@Lattice,$ResultRef); 
}
sub BuildLattice{#建立候选网格 (三维数组)
	my($Sent,$LatticeRef)=@_;
	@Words=split(" ",$Sent);#将输入的句子转为词的数组
	unshift(@Words,'^BEGIN');
	push(@Words,'$END');
	
	foreach $OneWord(@Words){
		my @Column;
		my @POSs;
		GetPOS($OneWord,\@POSs);#获取每个词出现过的词性数组
		foreach $OnePOS(@POSs){
			my @Element;
			push(@Element,$OneWord);#词
			push(@Element,$OnePOS);#词性
			push(@Element,0);#概率
			push(@Element,0);
			push(@Column,\@Element);
		}
		push(@{$LatticeRef},\@Column);
	}
}
sub BackWard{#回退
	my ( $LatticeRef,$ResultRef)=@_;
	$LatticeLen=@$LatticeRef;
	my @WordPOSs=();
	$BackwardPointer=$LatticeRef->[$LatticeLen-1]->[0]->[3];#回退指针,指向前一个@Column中的@Element
	#由于最后一个词为$END,实际上输出从倒数第二个词开始
	while( $BackwardPointer->[3] != 0 ){#回退指针不为空时
		$WordPOS=$BackwardPointer->[0]."/".$BackwardPointer->[1];
		$BackwardPointer=$BackwardPointer->[3];#指针前移
		unshift(@WordPOSs,$WordPOS);
	}
	${$ResultRef}=join(" ",@WordPOSs);
}
sub GetPOS{
	my($Word,$POSRef)=@_;
	if ( defined $LexiconProb{$Word} ){
		$TmpRef=$LexiconProb{$Word};
		@{$POSRef}=keys(%$TmpRef);
	}else{
		if ( $Word=~/\d+/ ){
			push(@{$POSRef},"CD");#基数
		}else{
			push(@{$POSRef},"NN");#名词
		}
	}
}
sub GetTransitionProb{#转移概率
	my($PrevPOS,$CurrPOS)=@_;
	my $POSBig=$PrevPOS." ".$CurrPOS;
	if ( defined $TransitionProb{$POSBig} ){
		return $TransitionProb{$POSBig};
	}
	return -1.0e10;
}
sub GetLexProb{#发射概率
	my($Word,$POS)=@_;
	if ( defined $LexiconProb{$Word} ){
		$POSRef=$LexiconProb{$Word};
		if ( defined $POSRef->{$POS} ){
			return $POSRef->{$POS};
		}else{
			return 1.0e-10;
		}
	}	
	return -1.0e10;
}
