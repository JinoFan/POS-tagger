#由pos.out输出转移概率和发射概率
open(In,"pos.out");
while(<In>){
	chomp;
	@Sent=$_=~/(\S+)\/\S+/g;
	@Pos=$_=~/\S+\/(\S+)/g;
	for($i=0;$i<@Sent;$i++){
		$hash_t{$Pos[$i]}++;#以某个词性标注的词的总的个数
		print "$Pos[$i]\n";
		if($i>0){
			$str=$Pos[$i-1]." ".$Pos[$i];
			$hash_tt{$str}++;#某两个词性相连的情况出现的次数
			${$hash_wt{$Sent[$i]}}{$Pos[$i]}++;#某个词 作为 某个词性 出现的次数
		}
	}
}
close(In);

open(Out,">transfer.txt");#输出转移概率
foreach $bi(sort keys %hash_tt){
	if($bi=~/(\S+) \S+/){
		$val=log($hash_tt{$bi}/$hash_t{$1});
		print Out "$bi\t$val\n";
	}
}
close(Out);

open(Out,">lex.txt");#输出发射概率
foreach $w(sort keys %hash_wt){
	print Out "#$w\n";
	$ref=$hash_wt{$w};
	
	foreach $t(sort keys %{$ref}){
		$val=log(${$hash_wt{$w}}{$t}/$hash_t{$t});
		print Out "$t $val\n";
	}
}
close(Out);