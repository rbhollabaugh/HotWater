awk -F: '
NF == 6 {
if($5 > 0) {
	avg = $4/$5
	diff = $3-avg
	if(diff > 10 )
		print $4, avg
}
}' tt.out

