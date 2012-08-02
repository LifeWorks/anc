######################################################################################
# File:     Set.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: An ordered, indexed set of object of a specified class.
######################################################################################
# Detailed Description:
# ---------------------
#
######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Set;
use Class::Std::Storable;
#use base qw();
{
    use Carp;

    use Utils;

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %elements_ref_of      :ATTR(get => 'elements_ref', set => 'elements_ref');
    my %element_class_of     :ATTR(get => 'element_class', set => 'element_class');
    my %element_count_ref_of :ATTR(get => 'element_count_ref', set => 'element_count_ref');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# INIT element_class
	my $element_class = $arg_ref->{element_class} || "UNDEF";  # pick up the init arg if defined
	# if the element_class was not specified in the call to new(), it may also be specified in the class data
	if ($element_class eq "UNDEF") {
	    if ($self->isa("ClassData")) {  # does it have class data?
		my $class = ref $self;
		$element_class = $class->get_class_data("ELEMENT_CLASS") || "UNDEF";
	    }
	}
	confess "ERROR: element_class is not defined\n" if ($element_class eq "UNDEF");
	$element_class_of{$obj_ID} = $element_class;
	my @element_classes = split(",",$element_class);

	# INIT elements_ref
	$elements_ref_of{$obj_ID} = $arg_ref->{elements_ref} || [];  # pick up the init arg if defined
	for (my $i=0; $i < @{$elements_ref_of{$obj_ID}}; $i++) {
	    my $element_ref = $elements_ref_of{$obj_ID}->[$i];
	    # check initializers to make sure they have the specified class
	    my $element_ref_class = ref $element_ref;

	    if (!grep($_ eq $element_ref_class, @element_classes)) {
		my $class = ref $self;
		confess "ERROR: cannot have elements of class ".(ref $element_ref).
		" in this object (of class $class, whose elements must have class $element_class)\n";
	    }
	    # tell element which set it has been added to
	    if ($element_ref->isa("SetElement")) {
		$element_ref->added_to_set($self, $i);
	    }
	}
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: clear_elements
    # Synopsys: Clear all elements.
    #--------------------------------------------------------------------------------------
    sub clear_elements {
	my $self = shift; my $obj_ID = ident $self;

	my $num_SetElements = grep {$_->isa('SetElement')} @{$elements_ref_of{$obj_ID}};
	confess "ERROR: not IMPLEMENTED (need to call SetElement::remove_from_set on $num_SetElements elements)" if $num_SetElements != 0;

	@{$elements_ref_of{$obj_ID}} = ();
	%{$element_count_ref_of{$obj_ID}} = ();
    }

    #--------------------------------------------------------------------------------------
    # Function: add_element
    # Synopsys: Add an element to the set.
    #--------------------------------------------------------------------------------------
    sub add_element {
	my $self = shift; my $obj_ID = ident $self;
	my $element_ref = shift;

	my $element_class = $element_class_of{$obj_ID};
	my $element_ref_class = ref $element_ref;
	if (grep($_ eq $element_ref_class, split(",", $element_class))) {
	    push @{$elements_ref_of{$obj_ID}}, $element_ref;
	    # tell element which set it has been added to
	    if ($element_ref->isa("SetElement")) {
		$element_ref->added_to_set($self, $#{$elements_ref_of{$obj_ID}});
	    }
	} else {
	    my $class = ref $self;
	    confess "ERROR: cannot add elements of class ".(ref $element_ref).
		" to this object (of class $class, whose elements must have class $element_class)\n";
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_element
    # Synopsys: Get a set element given index.
    #--------------------------------------------------------------------------------------
    sub get_element {
	my $self = shift;
	my $index = shift;

	return $elements_ref_of{ident $self}->[$index];
    }

    #--------------------------------------------------------------------------------------
    # Function: get_elements
    # Synopsys: Get all elements in the set.
    #--------------------------------------------------------------------------------------
    sub get_elements {
	my $self = shift;

	return @{$elements_ref_of{ident $self}};
    }

    #--------------------------------------------------------------------------------------
    # Function: get_element_by_name
    # Synopsys: Get a set element given name (regexp match).
    #--------------------------------------------------------------------------------------
    sub get_element_by_name {
	my $self = shift;
	my $name = shift;

	my @elements = @{$elements_ref_of{ident $self}};
	@elements = grep {$_->get_name() =~ /$name/} @elements;

	if (@elements > 1) {
	    confess "ERROR: found more than 1 matching element with name $name:".join ",",@elements;
	}
	confess "ERROR: couldn't find an element matching $name" if @elements != 1;

	my $element_ref = $elements[0];
	return $element_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: num_elements
    # Synopsys: Get the number of elements in the set.
    #--------------------------------------------------------------------------------------
    sub get_num_elements {
	my $self = shift;

	return scalar(@{$elements_ref_of{ident $self}});
    }

    #--------------------------------------------------------------------------------------
    # Function: get_last_element_index
    # Synopsys: Get the index number of the last element.
    #--------------------------------------------------------------------------------------
    sub get_last_element_index {
	my $self = shift;

	return $#{$elements_ref_of{ident $self}};
    }

    #--------------------------------------------------------------------------------------
    # Function: get_last_element
    # Synopsys: Get the last element in the set.
    #--------------------------------------------------------------------------------------
    sub get_last_element {
	my $self = shift;
	my $obj_ID = ident $self;

	return $elements_ref_of{$obj_ID}[$#{$elements_ref_of{$obj_ID}}];
    }

    #--------------------------------------------------------------------------------------
    # Function: get_element_count
    # Synopsys: Given element_ref, compute, cache and return the count how many times that
    #           element occurs in complex.
    #--------------------------------------------------------------------------------------
    sub get_element_count {
	my $self = shift;
	my $element_ref = shift;

	my $element_count_ref = $element_count_ref_of{ident $self};

	if (!defined $element_count_ref) {
	    foreach my $ref ($self->get_elements()) {
		$element_count_ref->{$ref}++;
	    }
	}

	return defined $element_count_ref->{$element_ref} ? $element_count_ref->{$element_ref} : 0;
    }

    #--------------------------------------------------------------------------------------
    # Function: concat_subset  (CUMULATIVE)
    # Synopsys: Concatenate a subset of the given set onto self, checking if class of
    #           elements is appropriate.  Order of elements in subset is significant, 
    #           so this routine can also be used to re-arrange a Set.
    #           Note that the set elements are not cloned, and so the set elements
    #           point to the original element objects if they are references.
    #--------------------------------------------------------------------------------------
    sub concat_subset : CUMULATIVE {
	my $self = shift; my $obj_ID = ident $self;
	my %args = @_;

	confess "ERROR: invalid argument -- use 'subsets' not 'subset'" if (exists $args{subset});
	confess "ERROR: subsets must contain a list of refs" if (exists $args{subsets} && !(ref $args{subsets}->[0]));

	if (!(exists $args{Set}) || $args{Set}) {
	    my $elements_ref = $elements_ref_of{$obj_ID};
	    my $offset = @$elements_ref;

	    my @refs = @{$args{refs}};
	    for (my $i=0; $i < @refs; $i++) {
		my $ref = $refs[$i];
		my @subset = (exists $args{subsets}) ? @{$args{subsets}->[$i]} : (0..($ref->get_num_elements()-1));

		foreach my $j (@subset) {
		    push @{$elements_ref}, $ref->get_element($j);
		}
	    }

	    # check elements to make sure they have the specified class
	    my $element_class = $element_class_of{$obj_ID};
	    my @element_classes = split(",",$element_class);
	    foreach my $element_ref (@{$elements_ref}[$offset..$#{$elements_ref}]) {
		my $element_ref_class = ref $element_ref;
		if (!grep($_ eq $element_ref_class, @element_classes)) {
		    confess "ERROR: Class of the elements of this set must be one of -> $element_class";
		}
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: concat
    # Synopsys: An alias for concat_subset (which is CUMULATIVE).
    #--------------------------------------------------------------------------------------
    sub concat {
	my $self = shift;

	$self->concat_subset(@_);
    }

    #--------------------------------------------------------------------------------------
    # Function: get_nested_element
    # Synopsys: Get a nested element given address (i.e. a list of indexes).
    # Details:  Arguments are the successive (sub)indexes of the desired nested element.
    # Example:
    #          get_nested_element(1,3,2)       # gets nested sub-element  (1,3,2)
    #--------------------------------------------------------------------------------------
    sub get_nested_element {
	my $self = shift;
	my @address = @_;

	my $obj_ID = ident $self;
	my $elements_ref = $elements_ref_of{$obj_ID};

	confess "ERROR: pass a list, not a reference" if (ref $address[0]);
	confess "ERROR: internal error, no address bits in call\n" if (!@address);

	my $msi = shift @address;
	confess "ERROR: index ($msi) out of range\n" if ($msi > $#{$elements_ref});
	my $element_ref = $elements_ref->[$msi];

	if (@address > 0) {
	    return $element_ref->get_nested_element(@address);
	} else {
	    return $element_ref;
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: get_nested_elements_and_addresses
    # Synopsys: Returns a subset (or all) nested elements in a set and their addresses.
    # Details:  Each argument is an address formatted as a comma-separated
    #           string of (sub)indexes.  A wildcard character "*" instead of an integer is
    #           accepted for an index, in which case all matching elements are returned.
    #           Finally, the keyword "ALL" as an address, will return all nested leaf
    #           sub-elements.  Useful if depth is unknown or variable.
    # Example:
    #          get_nested_elements(1,3,2)         # gets sub-elements 1, 3, and 2
    #          get_nested_elements([1,3,2])       # gets nested sub-element  (1,3,2)
    #          get_nested_elements([1,"*"], [0,"1"])  # gets nested sub-elements (1,*) and (0,1)
    #          get_nested_elements("ALL")         # gets everything
    #          get_nested_elements([1,"ALL"])       # gets everything nested in element 1
    #--------------------------------------------------------------------------------------
    sub get_nested_elements_and_addresses {
	my $self = shift;

	my @instances = ();
	my @instance_addresses = ();

	ADDRESS : while (@_) {
	    my $address_ref = shift;
	    confess "ERROR: internal error, undefined address in call\n" if (!defined $address_ref);
	    my @address = ref $address_ref ? @{$address_ref} : ($address_ref);
	    confess "ERROR: internal error, no address bits in call\n" if (!@address);

	    while (@address) {
		my $address_subindex = shift @address;
		if ($address_subindex eq "*" || $address_subindex eq "ALL") {
		    my $last_element = $self->get_last_element_index();
		    foreach my $unrolled_address_subindex (0..$last_element) {
			my $unrolled_address_ref;
			if ($address_subindex eq "ALL") {
			    if ($self->get_element($unrolled_address_subindex)->isa("Set")) {
				$unrolled_address_ref = [$unrolled_address_subindex, "ALL"];
			    } else {
				$unrolled_address_ref = [$unrolled_address_subindex];
			    }
			} else {  # i.e.  $address_subindex eq "*"
			    $unrolled_address_ref = [$unrolled_address_subindex, @address];
			}
			# printn "xxx $unrolled_address";
			my $tmp_ref = $self->get_nested_elements_and_addresses($unrolled_address_ref);
			push @instances, @{$tmp_ref->{instances}};
			push @instance_addresses, @{$tmp_ref->{addresses}};
		    }
		    next ADDRESS;
		}
		if (@address > 0) {
		    my $tmp_ref = $self->get_element($address_subindex)->get_nested_elements_and_addresses(\@address);
		    push @instances, @{$tmp_ref->{instances}};
		    # prepend current index to returned addresses
		    map {unshift @$_, $address_subindex} @{$tmp_ref->{addresses}};
		    push @instance_addresses, @{$tmp_ref->{addresses}};
		    next ADDRESS;
		} else {
		    push @instances, $self->get_element($address_subindex);
		    push @instance_addresses, [$address_subindex];
		    next ADDRESS;
		}
	    }
	}
	return {instances => \@instances, addresses => \@instance_addresses};
    }

    #--------------------------------------------------------------------------------------
    # Function: get_nested_elements
    # Synopsys: Returns a subset (or all) nested elements in a set.
    # Details:  Each argument is an address formatted as a comma-separated
    #           string of (sub)indexes.  A wildcard character "*" instead of an integer is
    #           accepted for an index, in which case all matching elements are returned.
    # Example:
    #          get_nested_elements(1,3,2)         # gets sub-elements 1, 3, and 2
    #          get_nested_elements([1,3,2])       # gets nested sub-element  (1,3,2)
    #          get_nested_elements([1,"*"], [0,1])  # gets nested sub-elements (1,*) and (0,1)
    #--------------------------------------------------------------------------------------
    sub get_nested_elements {
	my $self = shift;

	my @instances = ();

	ADDRESS : while (@_) {
	    my $address_ref = shift;
	    confess "ERROR: internal error, undefined address in call\n" if (!defined $address_ref);
	    my @address = ref $address_ref ? @{$address_ref} : ($address_ref);
	    confess "ERROR: internal error, no address bits in call\n" if (!@address);

	    while (@address) {
		my $address_bit = shift @address;
		if ($address_bit eq "*") {
		    my $last_element = $self->get_last_element_index();
		    foreach my $unrolled_address_bit (0..$last_element) {
			my $unrolled_address_ref = [$unrolled_address_bit, @address];
			# printn "xxx $unrolled_address";
			push @instances, $self->get_nested_elements($unrolled_address_ref);
		    }
		    next ADDRESS;
		}
		if (@address > 0) {
		    push @instances, $self->get_element($address_bit)->get_nested_elements(\@address);
		    next ADDRESS;
		} else {
		    push @instances, $self->get_element($address_bit);
		    next ADDRESS;
		}
	    }
	}
	return @instances;
    }

    #######################################################################################
    # Function: sprint_elements
    # Synopsys: Recursively print out elements of a set and it's sub-elements.
    #######################################################################################
    sub sprint_elements {
	my $self = shift;
	my $prefix = shift;

	$prefix = (defined $prefix) ? $prefix : "";

	my $indent = "  ";

	my $name = $self->isa('Named') ? $self->get_name() : "(anonymous)";

	my @element_refs = $self->get_elements();

	my $string;

	$string .= "$prefix$name\n";
	foreach my $element_ref (@element_refs) {
	    my $element_name = $element_ref->isa('Named') ? $element_ref->get_name() : "(anonymous)";
	    if ($element_ref->isa("Set")) {
		$string .= $element_ref->sprint_elements("$prefix$indent");
	    } else {
		$string .= "$prefix$indent$element_name\n";
	    }
	}

	return $string;
    }

    #--------------------------------------------------------------------------------------
    # Function: STORABLE_freeze_pre, STORABLE_freeze_post, etc.
    # Synopsys: Hooks provided by Class::Std::Storable.
    #--------------------------------------------------------------------------------------
    sub STORABLE_thaw_post: CUMULATIVE {
 	my ($self, $clone_flag) = @_;
	my $obj_ID = ident $self;
	for (my $i=0; $i < @{$elements_ref_of{$obj_ID}}; $i++) {
	    my $element_ref = $elements_ref_of{$obj_ID}->[$i];
	    # tell element which set it has been added to
	    if ($element_ref->isa("SetElement")) {
		$element_ref->added_to_set($self, $i);
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: xxx
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub xxx {
	my $self = shift;
    }
}


sub run_testcases {
    use Null;

    use Globals;
    $verbosity = 2;

    printn "run_testcases: Set package";
    my $set1 = Set->new({
	elements_ref => [Null->new({name => "N1"}), Null->new({name => "N2"})],
	element_class => "Null",
       });

    $set1->add_element(Null->new({name => "N3"}));
    printn "SET1 : ".join ",", (map($_->get_name, $set1->get_elements));

    my $set2 = Set->new({
	elements_ref => [Null->new({name => "N4"}), Null->new({name => "N5"})],
	element_class => "Null",
       });
    printn "SET2 : ".join ",", (map($_->get_name, $set2->get_elements));

    my $set3 = Set->new({
	elements_ref => [],
	element_class => "Null",
       });
    $set3->concat(refs => [$set1, $set2]);
    printn "SET3 : ".join ",", (map($_->get_name, $set3->get_elements));

    my $set4 = Set->new({
	element_class => "Null",
       });
    $set4->concat(refs => [$set1, $set3]);
    printn "SET4 : ".join ",", (map($_->get_name, $set4->get_elements));

    my $nested_set1 = Set->new({
	elements_ref => [$set1, $set2, $set3, $set4],
	element_class => "Set",
    });
    printn $nested_set1->sprint_elements();

    printn "TEST get_nested_element() :";
    printn $nested_set1->get_nested_element(1,0)->_DUMP();

    printn "TEST get_nested_elements() :";
    foreach my $nested_element_ref ($nested_set1->get_nested_elements([1,0])) {
	printn $nested_element_ref->_DUMP();
    }

    printn "TEST get_nested_elements() some more :";
    foreach my $nested_element_ref ($nested_set1->get_nested_elements([1,"*"], ["*",1], 2, 3)) {
	printn $nested_element_ref->_DUMP();
    }

    printn "TEST get_nested_elements_and_addresses :";
    {  # 
	my $nested_elements_ref = $nested_set1->get_nested_elements_and_addresses(["*","*"]);
	for (my $i = 0; $i < @{$nested_elements_ref->{instances}}; $i++) {
	    printn "@{$nested_elements_ref->{addresses}->[$i]}  ".$nested_elements_ref->{instances}->[$i]->get_name();
	}
    }

    # should gave the same result
    {
	printn "TEST get_nested_elements_and_addresses with \"ALL\" keyword:";
	my $nested_elements_ref = $nested_set1->get_nested_elements_and_addresses("ALL");
	for (my $i = 0; $i < @{$nested_elements_ref->{instances}}; $i++) {
	    printn "@{$nested_elements_ref->{addresses}->[$i]}  ".$nested_elements_ref->{instances}->[$i]->get_name();
	}
    }

    # test variable-depth nesting with ALL keyword
    printn "TEST get_nested_elements_and_addresses with variable-depth nesting and \"ALL\" keyword:";
    my $var_nested_set = Set->new({
	elements_ref => [$nested_set1, $set2, $set3, $set4],
	element_class => "Set",
    });
    {
	my $nested_elements_ref = $var_nested_set->get_nested_elements_and_addresses("ALL");

	for (my $i = 0; $i < @{$nested_elements_ref->{instances}}; $i++) {
	    printn "@{$nested_elements_ref->{addresses}->[$i]}  ".$nested_elements_ref->{instances}->[$i]->get_name();
	}
    }

    # test concat_subset
    my $set5 = Set->new({
	element_class => "Null",
    });
    $set5->concat(refs => [$set3], subsets => [[1, 4]]);
    printn "SET5 : ".join ",", (map($_->get_name, $set5->get_elements));

}


# Package BEGIN must return true value
return 1;

