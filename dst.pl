my $year = 2011;
my $res = (1.0 + (($year-2000.0)*5.0/4.0))+.5;

my $beginDSTdayofmonth = 14-$res%7;
my $endDSTdayofmonth = 7-$res%7;

printf("res=%d beginDOM=%d endDOM=%d\n", $res, $beginDSTdayofmonth, $endDSTdayofmonth);
