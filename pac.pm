#!perl
###############################################################
# Perl Non OO call & OO instantiation/method call example
# Devesh Mohnani (c) 2010
###############################################################
package pac;

if ($var =~ /value/)
{
print  __LINE__ ."\nIn pac Matches ------- pac :$var\n";

}

print "\n". __LINE__ .In pac ------- pac :$pac::var\n";
print "\n". __LINE__ .In pac just priting : $var\n";


sub a{
	print "\n". __LINE__ . In pac in a: $var\n";

}

use pac;
