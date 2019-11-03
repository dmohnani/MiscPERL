#!perl   ## oop.pl
sub Cow::speak 
{
	my $class = shift;
	$Cow::name="Gauri";
	print "a $class goes moooo!\n";
}

sub Horse::speak 
{
	my $class = shift;
	$Horse::name="Sultan";
	print "a $class goes neigh!\n";
}

sub Sheep::speak 
{
	my $class = shift;
	$Sheep::name="Bhed";
	print "a Sheep goes baaaah!\n"
}

@pasture = qw(Cow Cow Horse Sheep Sheep);

foreach $animal (@pasture) 
{
	$animal->speak;
	print ${$animal."::name"};
	print "\n";
}

__END__

Output:
a Cow goes moooo!
Gauri
a Cow goes moooo!
Gauri
a Horse goes neigh!
Sultan
a Sheep goes baaaah!
Bhed
a Sheep goes baaaah!
Bhed

