#!perl
###############################################################
# Perl Non OO call & OO instantiation/method call example
# Devesh Mohnani (c) 2010
###############################################################
#Parent
package Parent;


$i=10;
sub sec
{
    # Implicit Argument (ref) gets passed when Package Function is invoked using Class/ref Notation ->.
    my $myself=shift;
    print "\nLine=". __LINE__ ." Inside Package =" . __PACKAGE__ ." Invokded from : $myself";
}
1;
# End of Package #


# Constructor
#Instance / Object
#An instance or object is a blessed reference. In the most common case, as described in this article, 
#it is a blessed reference to a hash
sub new {
    my ($myself) = @_;
	print("\nPC\n");
    return bless {}, $myself;
}
