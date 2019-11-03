#!perl
###############################################################
# Perl Non OO call & OO instantiation/method call example
# package TEST
# Devesh Mohnani (c) 2010
###############################################################
use Parent;
use Child;
print ("####################  using class/NS notation  ####################\n");
print ("1. Invoking Child [child] ->pri() = member f using class/ns notation");
Child->pri(); 
print ("\n\n");
print ("2. Invoking Child [child] ->sec() = Overidden method using class/ns notation");
Child->sec(); 
print ("\n\n");
print ("3. Invoking Parent [Parent]->sec() = Original Parents's method using class/object notation");
Parent->sec();
print ("\n\n");

print ("########################  using PM notation for func call  ######################\n");
print ("1. Invoking Child library f [child]::pri() = using PM notation");
Child::pri(); 
print ("\n\n");
print ("2. Invoking Child library f [child]::sec() = Overidden method using PM notation");
Child::sec(); 
print ("\n\n");
print ("3. Invoking Parent library f [Parent]::sec() = Original Parents's method using package notation");
Parent::sec();
print ("\n\n");

print ("########################  using object notation for func call  ######################\n");
#Instance / Object
#An instance or object is a blessed reference. In the most common case, as described in PerlOO, 
#& it is a blessed reference to a hash
print ("1. Invoking Child Member f Cobj->pri() = member f using object notation");
$obj=Child->new();
print ("\n");print ($obj);print ("\n");
$obj->pri(); #Child Member Func
print ("\n\n");
print ("2. Invoking Parent Member f [Parent] Cobj->sec() = Overidden method using PM notation");
$obj->sec(); # Parent Member Func
print ("\n\n");