#!/usr/bin/perl
#d:ptkdb


# TEST Swift Message Generation based on Sample (Swift) messages stored in the Table
# and Send to the Swift Alliance Access Message Queue
# Developer: Devesh Mohnani

#Libraries
use Env;
use File::Basename;
use Date::Parse;
use Time::HiRes qw(gettimeofday);
use Getopt::Long;
use IO::Handle;
use warnings;

$write=1;
$| = 1;
$time_stamp=`date +%m-%d-%Y_%H:%M:%S`;
chomp($time_stamp);
my $me=`basename $0`;
chomp ($me);
my $uid=`whoami`;
chomp($uid);
my $pwd=`pwd`;
chomp($pwd);

%Q=( 
  QMGR  => 'MYQM',
  ENT1 => { 
			 SND => 'ENT1.SND',
			 RCV => 'ENT1.RCV',
			 ERR => 'ENT1.ERR',
			 entity => "test1"
			 },
  ENT2 =>{ 
			 SND => 'ENT2.SND',
			 RCV => 'ENT2.RCV',
			 ERR => 'ENT2.ERR',
			 entity => "test2"
			 },
  ENT3 =>{ 
			 RCV => 'ENT3.RCV',
			 entity => "test3"
		  }
);

my $num_arg = scalar(@ARGV);
my @cmd_line = @ARGV;
my $msg_ids=undef;
my $dbconnection=undef;
my $src_test_bic=undef,
my $dest_test_bic=undef,
my $entity=undef;
my $msg_types=undef;
my @msg_type_list=();
my @msg_id_list=();
my $date=undef;
my $num_msgs=undef;
my @sql;
my $select;
my $DBHANDLE;
my $DIR;
my $OUT;
my $branch='BRANCH';
my $MSG_DIR = "$ENV{UNIX_DATA}/swift/mq_secure/$Q{$branch}{entity}";
my $prevFilename;
my %test_bic_map=();
my $mi;
my $ml;
my $ext='si';

if ( $num_arg == 0 ) {
	&help();
} else {
    # Else we parse the command line and
    # extract the values.
    GetOptions(
                  'msg_ids|i=s' => \$msg_ids,
                'msg_types|t=s' => \$msg_types,
                     'date|d=s' => \$date,
                 'num_msgs|n=s' => \$num_msgs,
	         'criteria|w=s' => \$criteria,
                   'entity|E=s' => \$entity,
	       'Source_Bic|S=s' => \$src_test_bic,
	  'Destination_Bic|D=s' => \$dest_test_bic,
	     'dbconnection|c=s' => \$dbconnection
    );
    if( ($msg_types ne undef && $msg_ids ne undef)   ||  ($msg_ids ne undef && $date ne undef )   ||
	($msg_types ne undef && $date eq undef)      ||  ($msg_types eq undef && $date ne undef ) ||
	($msg_types eq undef && $date eq undef       &&  $msg_ids eq undef && $criteria eq undef) ||
	($criteria  ne undef && ($msg_types ne undef || $date ne undef || $msg_ids ne undef) ) ) {
	&help();
    }else{
	# Setting Defaults
	if (!(defined $dbconnection )) {$dbconnection =$DSQUERY}
	if (!(defined $entity) || !($entity eq 'test1' || $entity eq 'test2' || $entity eq 'test3')) {$entity ="test4"}
	if (!(defined $src_test_bic )) {$src_test_bic   ='YYYYUS40XXXX'}
	if (!(defined $dest_test_bic)) {$dest_test_bic  ='YYYYUS40XXXX'}
	if (defined $num_msgs) {
		$select = "SELECT top $num_msgs ";
	}else{
		$select = "SELECT ";
	}
	&start_filelog();
	&filelog (STDERR, "\nStarting Message Generation....in Directory\n");
    }
}

&populate_test_bic_map;

if ($msg_ids eq undef && $msg_types ne undef && $criteria eq undef) {
	if($msg_types eq "0") # ALL MESSAGE TYPES
	{
		@msg_type_list= map {"'".$_."'"} (536,548,537,544,547,545,535,541,543,599,
					300,320,395,900,910,935,940,942,950,992,999); # ALL
	} else {
	    if ($msg_types =~ /[0-9]xx/) 
	    {
		if ($msg_types =~ /5xx/) 
		{
			push @msg_type_list, map {"'".$_."'"} (536,548,537,544,547,545,535,541,543,599);
		}
		if ($msg_types =~ /3xx/) 
		{
			push @msg_type_list, map {"'".$_."'"} (300,320,395);
		}
		if ($msg_types =~ /9xx/) 
		{
			push @msg_type_list, map {"'".$_."'"} (900,910,935,940,942,950,992,999);
		}
             }	
	     else
	     {
		@msg_type_list=split(/,/,$msg_types) if ($msg_types =~ /,/);
		$msg_type_list[0]=$msg_types if ($msg_types !~ /,/);
		#@msg_type_list=map { s/ //g } @msg_type_list;
		@msg_type_list=map {"'".$_."'"} @msg_type_list;
	     }
	}
	$ml=join(',',@msg_type_list);
	print "\nMessage Type(s) for Message Generation: $ml";
	print "\nDate for Message Generation: $date". "\n";
	&generate_using_msg_type_and_date();
} elsif ($criteria eq undef) {
	@msg_id_list=split(/,/,$msg_ids) if( $msg_ids =~ /,/);
	$msg_id_list[0]=$msg_ids if ($msg_ids !~ /,/);
	$mi=join(',',@msg_id_list);
	print "\nMessage id(s) for Message Generation: $mi". "\n";
	&generate_using_msg_ids();
} elsif (defined $criteria) {
	&filelog (STDERR, "$criteria");
	&generate_using_criteria;
}
exit 0;

#End Main Program
#-----------------------------------------
sub help
#-----------------------------------------
{
	print "\n\tIncorrect or No options specified.\n".
	"\n This Program Generates Swift Message File under /dev_data/swift/mq_secure/<entity>/SWLogger, with extension .si \n".
	"\nUsage:".
	"\n$me -i <msg_ids|0> |-t <msg_types> -d <date YYYYMMDD>|-w <where clause> [-n msg count] [-c DB_Instance] [-S test_bic] [-D test_bic] [-E entity]".
	"\n\n     *  -i <MSG_IDS> can be a single msg_id or comma separated values.".
	"\n     *  -t <MSG_TYPES> can be a single msg type or comma separated values.".
	"\n     *  -w <WHERE CLAUSE> is a valid SQL clause enclosed in \"double quotes\" ".
	"\n     *  -n <MESSAGE_COUNT> is a number".
	"\n     *  -c <DB_INSTANCE> is name of DB Instance Ex. SYBASE1".
	"\n     *  -S <TEST_BIC_FOR_SOURCE> is desired SRC Bic in the Test Message (Default Source Test Bic is YYYYUS40XXXX)".
	"\n     *  -D <TEST_BIC_FOR_DESTINATION> is desired DEST Bic in the Test Message (Default Destination Bic is YYYYUS40XXXX)".
	"\n     *  -E <ENTITY> one of test1,test2,test3 [Default is test1] -> to select output Directory".
	"\n     *  Rules:".
	"\n		-t and -d both must be specified.".
	"\n		-t and -i are Mutually Exclusive.".
	"\n		-d and -i are Mutually Exclusive.".
	"\n		-w is Exclusive.".
	"\n		-n, -c, -S, -D, -E are optional and compatible with other options.\n".
	"\nExamples:".
	"\n       $me -w \"msg_type='540'".
	"\n       $me -w \"msg_type like '5%'\" -n 10".
	"\n       $me -w \"msg_type like '5%' and in_out='O'\" -n 10".
        "\n       $me -w \"msg_type='518' and in_out='I' and mq_time > '29sep11' and src_bic='GRNWUS33XXX'\" -n 100 -c SYBB_DB1 -E gcm -D ABNAUS30XXXX".
	"\n       $me -w msg_id=7034562".
	"\n".
	"\n       $me -t 0 #All Types".
	"\n       $me -t 5xx -d 20110609 -n 10".
	"\n       $me -t 541,542 -d 20110609".
	"\n".
	"\n       $me -i 7034562 -c SYBB_DB1".
	"\n".
	"\nExit Code 1.\n\n";
	exit 1;
}

#-----------------------------------------
sub get_db_connection 
#-----------------------------------------
{
	#Connections
	$DBHANDLE = new SybaseConn($dbconnection,$DB_DFLT_USR,$DB_DFLT_PWD,"'mast','hist','inv'");
}

#-----------------------------------------
sub start_filelog
#-----------------------------------------
{
	$DIR=$pwd;
	$DIR=~ s/shell/output\//g;

	$DIR .="$Q{$branch}{entity}";
	$OUT="$DIR"; 

	$me =~ s/\.pl//g;
	$OUT=$pwd if ($pwd !~ /$APPS/);
	open(STDERR,"> $OUT/$me.err") || die "Could NOT redirect STDERR to $OUT/$me.err\n";
}

#-----------------------------------------
sub filelog 
#-----------------------------------------
{
    my $filelogfd = shift;
    my $arg   = shift;
    my $time  = localtime();

    my $timestamp;

    # following checks are added to error out when
    # filelogfd is not defined or when it is not a file handle
    #
    if ( !defined $filelogfd ) {
        print "ERROR from filelog(): filelogfd not defined" . longmess();
        return;
    }
    else {
        if ( fileno($filelogfd) eq undef ) {
            print "ERROR from filelog(): filelogfd not a filehandle" . longmess();
            return;
        }
    }

    if ( !defined $level ) {
        $level = 0;
    }
    (
       $second,  $minute,    $hour,      $dayofmonth, $month,
       $yearoff, $dayofweek, $dayofyear, $dst
    ) = localtime();

    $yearoff = $yearoff + 1900;
    $month   = $month + 1;

    $timestamp = sprintf( "\(%04d/%02d/%02d-%02d:%02d:%02d\): ",
                    $yearoff, $month, $dayofmonth, $hour, $minute, $second );

    print $filelogfd $timestamp;
    print $filelogfd "$arg\n";
    $filelogfd->autoflush(1);
}

#-----------------------------------------
sub populate_test_bic_map 
#-----------------------------------------
{
	my @sql="SELECT * from mast..test_bic_map";
	&get_db_connection();
	&filelog (STDERR, "Starting Query , @sql");
        my $res = $DBHANDLE->doSelectReturnHash(\@sql);
        if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to mast..test_bic_map failed:\n@sql\n"); }
        &filelog (STDERR,"Done");
        my $scal=scalar(@{$res});
        &filelog (STDERR , "Num of Records in Result: $scal");
        foreach my $row (@$res) {
		$test_bic_map{$row->{bic_code}} = $row->{test_bic_code};	
		&filelog (STDERR, "BIC = $row->{bic_code}   TEST BIC = $test_bic_map{$row->{bic_code}}"); 
	}
my %test_bic_map_wiki= (
	'ZZZZUS33'	 => 'KKKKUS30',
	'ZZZZUS3C'	 => 'KKKKUS30',
	'ZZZZUS3G'	 => 'KKKKUS30',
	'ZZZZUS3E'	 => 'KKKKUS30',
	'ZZZZUS33'	 => 'KKKKUS30',
	'ZZZZUS4C'	 => 'KKKKUS40',
	'ZZZZUS40'   => 'KKKKUS40',
	'ZZZZCATT' 	 => 'KKKKUS30'
	);

	# Now Wiki has more preference
	foreach my $k (keys(%test_bic_map_wiki)){
		delete $test_bic_map{$k};
	}
	%test_bic_map=(%test_bic_map,%test_bic_map_wiki);
}

#-----------------------------------------
sub generate_using_msg_ids
#-----------------------------------------
{
	&filelog (STDERR , "msg_ids : $mi");
	foreach my $mid(@msg_id_list){
		my @q = "SELECT src_bic,dest_bic,flag=datediff(mi,'10/7/2011 1:23:45 AM',mq_time),".
                        "mq_time0=dateadd(mi, -2, mq_time), mq_time1=dateadd(mi, 2, mq_time) ".
                        "from hist..swift_message_header where msg_id in ($mid)";
		&filelog (STDERR, "\t Now Starting Query , @q");
		my $f = $DBHANDLE->doSelectReturnHash(\@q);

		if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to swift_msg_fields failed:\n@q\n"); }
		&filelog (STDERR,"Done");

		my $flag     = $f->[0]->{flag};
		my $msg_id0  = $f->[0]->{msg_id};
		my $mq_time  = $f->[0]->{mq_time};
		my $mq_time0 = $f->[0]->{mq_time0};
		my $mq_time1 = $f->[0]->{mq_time1};
		my $dest_bic = $f->[0]->{dest_bic};
		my  $src_bic = $f->[0]->{src_bic};

		$dest_bic=substr($dest_bic,0,8).'.'.substr($dest_bic,8,3);
		$src_bic=substr($src_bic,0,8).'.'.substr($src_bic,8,3);

		&filelog(STDERR,"msg_id:$msg_id0|DestBic:$dest_bic|SrcBic:$src_bic|flag:$flag|mq_time:$mq_time|mq_time0:$mq_time0|mq_time1:$mq_time1");

		my @q = "SELECT * from hist..swift_message_fields where msg_id in ($mid) and mq_time>='$mq_time0' and mq_time<='$mq_time1' order by seq_id";
		&filelog (STDERR, "\t Now Starting Query , @q");
		my $f = $DBHANDLE->doSelectReturnHash(\@q);
		if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to swift_msg_fields failed:\n@q\n"); }
		&filelog (STDERR,"Done");
		my $scal1=scalar(@{$f});
		&filelog (STDERR , "Num of Records in Result: $scal1");
		my @message=();
		my $prev_tag='';
                foreach my $rec(@{$f}) {
                        if($rec->{field} eq 'headerRec' ){
                                $tmp=$rec->{content};
				$tmp =~ s/$dest_bic/$dest_test_bic/g;
				$tmp =~ s/$src_bic/$src_test_bic/g;
                                #foreach my $k(keys %test_bic_map) { $tmp=~s/$k/$test_bic_map{$k}/g }
                                push (@message, $tmp . "\r\n");
                        }elsif($rec->{field} eq 'trailerRec'){
                                $tmp=$rec->{content};
                                push (@message, $tmp);
                        }else{
				if($flag < 0) { # This message came before conversion
					if ($prev_tag eq $rec->{field}) {
						push (@message, $rec->{content} . "\r\n");
					} else {
						push (@message, ':' . $rec->{field} . ':' . $rec->{content} . "\r\n");
					}
					$prev_tag=$rec->{field};
				}else{ # This message came after conversion , Insert all lines unconditionally
					push (@message, $rec->{content} . "\r\n");
				}
                        }
                }
		my $swiftmsg=join('',@message);
		&write_to_file($swiftmsg) if ($write);
		&filelog (STDERR, "$swiftmsg" );
		#print "$swiftmsg\n";
	}
}


#-----------------------------------------
sub generate_using_msg_type_and_date
#-----------------------------------------
{
	@q="$select msg_id,src_bic,dest_bic,flag=datediff(mi,'10/7/2011 6:47:36 PM',mq_time),mq_time0=dateadd(mi,-2,mq_time),mq_time1=dateadd(mi,2,mq_time) from hist..swift_message_header where msg_type in ($ml) and convert(date,mq_time) = '$date'";
	&filelog (STDERR, "Starting Query , @q");
	my $res = $DBHANDLE->doSelectReturnHash(\@q);
        if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to swift_msg_header failed:\n@sql\n"); }
        &filelog (STDERR,"Done");
        my $scal=scalar(@{$res});
	&filelog (STDERR , "Num of Records in Result: $scal");
        foreach my $row (@$res) {
		my $dest_bic=$row->{dest_bic};
		my $src_bic=$row->{src_bic};
		my $flag=$row->{flag};
		$dest_bic=substr($dest_bic,0,8).'.'.substr($dest_bic,8,3);
		$src_bic=substr($src_bic,0,8).'.'.substr($src_bic,8,3);
		&filelog (STDERR , "New msg_id : $row->{msg_id} |flag=$row->{flag}|mq_time0 : $row->{mq_time0} | mq_time1 : $row->{mq_time1}");

		my @q = "SELECT * from hist..swift_message_fields where msg_id in ($row->{msg_id}) and mq_time>='$row->{mq_time0}'".
                        "and mq_time<='$row->{mq_time1}' order by seq_id";

		&filelog (STDERR, "\t Now Starting Query , @q");
		my $f = $DBHANDLE->doSelectReturnHash(\@q);
		if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to swift_msg_fields failed:\n@q\n"); }
		&filelog (STDERR,"Done");
		my $scal1=scalar(@{$f});
		&filelog (STDERR , "Num of Records in Result: $scal1");
		my @message=();
		my $prev_tag='';
                foreach my $rec(@{$f}) {
                        if($rec->{field} eq 'headerRec' ){
                                $tmp=$rec->{content};
                                $tmp =~ s/$dest_bic/$dest_test_bic/g;
                                $tmp =~ s/$src_bic/$src_test_bic/g;
                                #foreach my $k(keys %test_bic_map) { $tmp=~s/$k/$test_bic_map{$k}/g }
                                push (@message, $tmp . "\r\n");
                        }elsif($rec->{field} eq 'trailerRec'){
                                $tmp=$rec->{content};
                                push (@message, $tmp);
                        }else{ # Message Body (Excluding Trailer)
                                if($flag < 0) { # This message came before conversion
                                        if ($prev_tag eq $rec->{field}) {
                                                push (@message, $rec->{content} . "\r\n");
                                        } else {
                                                push (@message, ':' . $rec->{field} . ':' . $rec->{content} . "\r\n");
                                        }
                                        $prev_tag=$rec->{field};
                                }else{ # This message came after conversion , Insert all lines unconditionally
                                        push (@message, $rec->{content} . "\r\n");
                                }
                        }
                }
		my $swiftmsg=join('',@message);
		&write_to_file($swiftmsg) if($write);
		&filelog (STDERR, "$swiftmsg\n" );
		#print "$swiftmsg";
	}
}

#-----------------------------------------
sub generate_using_criteria
#-----------------------------------------
{
	#-------------------------
	# Apply Supplied Criteria
	#-------------------------
	#ensure criteria values are having message types enclosed in single quotes
	$criteria =~ s/(=)[\s]*([0-9][0-9][0-9])/${1}'${2}'/g if ($criteria !~/'/);
        @q="$select msg_id,src_bic,dest_bic,flag=datediff(mi,'1/1/2009 1:22:33 PM',mq_time),mq_time0=dateadd(mi,-2,mq_time),mq_time1=dateadd(mi,2,mq_time) from hist..swift_message_header where ".$criteria;
        &filelog (STDERR, "Starting Query , @q");
        my $res = $DBHANDLE->doSelectReturnHash(\@q);
        if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to swift_msg_header failed:\n@sql\n"); }
        &filelog (STDERR,"Done");
        my $scal=scalar(@{$res});
        &filelog (STDERR , "Num of Records in Result: $scal");
        foreach my $row (@$res) {
                my  $flag     = $row->{flag};
                my  $mq_time0 = $row->{mq_time0};
                my  $mq_time1 = $row->{mq_time1};
		my  $dest_bic = $row->{dest_bic};
		my  $src_bic  = $row->{src_bic};
		$dest_bic=substr($dest_bic,0,8).'.'.substr($dest_bic,8,3);
		$src_bic=substr($src_bic,0,8).'.'.substr($src_bic,8,3);
                &filelog (STDERR , "New msg_id : $row->{msg_id} | Destination_Bic : $row->{dest_bic} | Src Bic : $row->{src_bic} | mq_time0 : $row->{mq_time0} | mq_time1 : $row->{mq_time1}");
                my @q = "SELECT * from hist..swift_message_fields where msg_id in ($row->{msg_id}) and mq_time>='$row->{mq_time0}' and mq_time<='$row->{mq_time1}' order by seq_id";
                &filelog (STDERR, "\t Now Starting Query , @q");
                my $f = $DBHANDLE->doSelectReturnHash(\@q);
                if ( $DBHANDLE->sqlState() ne $SybaseConn::OK ) { die("Error: query to swift_msg_fields failed:\n@q\n"); }
                &filelog (STDERR,"Done");
                my $scal1=scalar(@{$f});
                &filelog (STDERR , "Num of Records in Result: $scal1");
                my @message=();
                foreach my $rec(@{$f}) {
                        if($rec->{field} eq 'headerRec' ){
                                $tmp=$rec->{content};
                                $tmp =~ s/$dest_bic/$dest_test_bic/g;
                                $tmp =~ s/$src_bic/$src_test_bic/g;
                                #foreach my $k(keys %test_bic_map) { $tmp=~s/$k/$test_bic_map{$k}/g }
                                push (@message, $tmp . "\r\n");
                        }elsif($rec->{field} eq 'trailerRec'){
                                $tmp=$rec->{content};
                                push (@message, $tmp);
                        }else{
                                if($flag < 0) { # This message came before conversion
                                        if ($prev_tag eq $rec->{field}) {
                                                push (@message, $rec->{content} . "\r\n");
                                        } else {
                                                push (@message, ':' . $rec->{field} . ':' . $rec->{content} . "\r\n");
                                        }
                                        $prev_tag=$rec->{field};
                                }else{ # This message came after conversion , Insert all lines unconditionally
                                        push (@message, $rec->{content} . "\r\n");
                                }
                        }
                }
                my $swiftmsg=join('',@message);
                &write_to_file($swiftmsg) if($write);
                &filelog (STDERR, "$swiftmsg\n" );
                #print "$swiftmsg";
        }
}

#-----------------------------------------
sub getUniqueFileName
#-----------------------------------------
{
  my ($dir, $prefix, $extension) = @_;
  my $filename = "";
  do {
	  my $datetime=localtime(time);
	  my ( $sec, $min, $hour, $mday, $mon, $year ) = strptime($datetime);

	  my @ar= Time::HiRes::gettimeofday() ;
	  my $ts=sprintf( "%02d%02d%02d%02d%02d%06d", $mon+1, $mday, $hour, $min, $sec, $ar[1]);
	  my $timeStamp= "7"."$ts";
	  $filename = $dir."/".$prefix.$timeStamp.".".$extension;
		
  } while ( $prevFilename eq $filename ) ;

  $prevFilename=$filename;
  &filelog (STDERR, "New File Name generated = $filename");
  return $filename;
}


#-----------------------------------------
sub write_to_file
#-----------------------------------------
{
	my $swiftmsg=shift;
	my $MSG_DIR="/dev_data/swift/mq_secure/$entity/SWLogger";
	&filelog (STDERR, "calling getUniqueFileName($MSG_DIR, \"ex\", $ext");
	my $filename=getUniqueFileName($MSG_DIR, "ex", $ext);
	&filelog (STDERR, "File : $filename about to be written now!");
	$status=open (FILE, ">$filename") ;
	if ($status > 0) {
		&filelog (STDERR, "Writing Message to File = $filename");
		print FILE $swiftmsg;
		&filelog (STDERR, "Completed Writing Message\n");
	}
	close FILE;
}

