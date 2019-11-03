#!perl
###############################################################
# Perl Non OO call & OO instantiation/method call example
# Devesh Mohnani (c) 2010
###############################################################

package Child;
#Class declaration
#A class is just a namespace created using the package keyword. It is usually implemented in a module having the same name. 
#For example the class My::Date would be implemented in a file called Date.pm located in a directory called My having the following content:package Child;

#The 1; at the end is needed to indicate successful loading of the file.
#https://perlmaven.com/oop
#This code isn't really a class without a constructor.

use Parent;      # needed to call Function in Package Mode
@ISA=qw(Parent); # Needed for SUPER()

#use parent 'Parent';
#When we call the new method on 'Child' Perl will see that 'Child' does not have a 'new' function and it will look at at the next #module in the inheritance chain. In this case it will look at the 'Parent' module and call new there.
#The same will happen when we call say_hi.
#On the other hand when we call say_hello perl will already find it in the 'Child' and call it.
#Instead of the parent directive, old school code uses the base directive
#use base 'Parent';

#Inheritance
#You can declare inheritance using the parent directive which replaced the older base directive. 
#In the end they are both just manipulating the @ISA array that defines the inheritance.

#The main script loads a module, calls its constructor and then calls two methods on it:


$j=10;
$i=25;

sub pri 
{
	my $myself = shift;
	print "\nLine=". __LINE__ ." Inside Package =" . __PACKAGE__ ." Invokded from : $myself";
    if (defined $myself)
	{
	   $myself->SUPER::sec();
	}
}	

sub sec
{
my $myself=shift;
print "\nLine=". __LINE__ ." Inside Package =" . __PACKAGE__ ." Invokded from : $myself";
}

# Constructor
#Instance / Object
#An instance or object is a blessed reference. In the most common case, as described in this article, 
#it is a blessed reference to a hash
sub new {
    my ($myself) = @_;
	return $myself->SUPER::new();
	#print("\nCC\n");	
    #return bless {}, $myself;
}
#Destructor
#Perl automatically cleans-up objects when they go out of scope, or when the program ends and usually there is no need to implement a destructor. With that said, there is a special function called DESTROY. If it is implemented, it will be called just before the object is destroyed and memory reclaimed by Perl

sub DESTROY {
   my ($self) = @_;
 }
 
 
1;

