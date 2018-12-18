use Win32::OLE qw( in );
use Win32::OLE::Variant;

$Machine = "\\\\.";

# WMI Win32_Process class
$CLASS = "winmgmts:{impersonationLevel=impersonate}$Machine\\Root\\cimv2";
$WMI = Win32::OLE->GetObject( $CLASS ) || die;
my @procs = in $WMI->InstancesOf( "Win32_Process" );
foreach my $Proc (@procs)
{
  printf( "% 5d) %s ", $Proc->{ProcessID}, "\u$Proc->{Name}" );
  print "( $Proc->{ExecutablePath} )" if( "" ne $Proc->{ExecutablePath} );
  print "\n";
  if($Proc->{Name} =~ m/^DAQFactory.*/) {
	printf("Found DAQ\n");
  }
}
#foreach my $Proc ( sort {lc $a->{Name} cmp lc $b->{Name}} in( $WMI->InstancesOf( "Win32_Process" ) ) )

