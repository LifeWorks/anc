######################################################################################
# File:     Matrix.pm
# Author:   Julien F. Ollivier
#
# Copyright (C) 2005-2010 Julien Ollivier.
#
# This program comes with ABSOLUTELY NO WARRANTY.
# This is free software, and you are welcome to redistribute it
# under certain conditions. See file LICENSE.TXT for details.
#
# Synopsys: Matrix class with common operations.
######################################################################################
# Detailed Description:
# ---------------------
#
# The matrix is a list of references to each row:
#
# $matrix_ref = [ [ x00 x01 x02 x03 ... x0n]
#                 [ x10 x11 x12 x13 ... x1n]
#                         .....
#                 [ xn0 xn1 xn2 xn3 ... xnn]]
#
######################################################################################

#######################################################################################
# TO-DO LIST
#######################################################################################

use strict;
use diagnostics;		# equivalent to -w command-line switch
use warnings;

package Matrix;
use Class::Std::Storable;
use base qw();
{
    use Carp;
    use Utils;

    #######################################################################################
    # CLASS ATTRIBUTES
    #######################################################################################

    #######################################################################################
    # ATTRIBUTES
    #######################################################################################
    my %matrix_ref_of :ATTR(get => 'matrix_ref', set => 'matrix_ref');

    #######################################################################################
    # FUNCTIONS
    #######################################################################################
    sub range { 0 .. ($_[0] - 1) }

    #sub veclen {
    #    my $ary_ref = shift;
    #    my $type = ref $ary_ref;
    #    if ($type ne "ARRAY") { die "$type is bad array ref for $ary_ref" }
    #    return scalar(@$ary_ref);
    #}

    #######################################################################################
    # CLASS METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: mmult
    # Synopsys: Returns a new matrix object which is product of the arguments.
    #--------------------------------------------------------------------------------------
    # From Perl Cookbook, R2.14
    #--------------------------------------------------------------------------------------
    sub mmult {
	my $class = shift;
	my ($m1_ref,$m2_ref) = @_;
	my ($m1rows,$m1cols) = $m1_ref->matdim();
	my ($m2rows,$m2cols) = $m2_ref->matdim();

	unless ($m1cols == $m2rows) { # raise exception
	    die "IndexError: matrices don't match: $m1cols != $m2rows";
	}

	my $result_ref = Matrix->new();

	my $m1_matrix_ref = $matrix_ref_of{ident $m1_ref};
	my $m2_matrix_ref = $matrix_ref_of{ident $m2_ref};
	my $result_matrix_ref = $matrix_ref_of{ident $result_ref};
	
	for my $i (range($m1rows)) {
	    for my $j (range($m2cols)) {
		for my $k (range($m1cols)) {
		    $result_matrix_ref->[$i][$j] += $m1_matrix_ref->[$i][$k] * $m2_matrix_ref->[$k][$j];
		}
	    }
	}

	return $result_ref;
    }


    #--------------------------------------------------------------------------------------
    # Function: madd
    # Synopsys: Return new matrix which is sum of arguments.
    #--------------------------------------------------------------------------------------
    sub madd {
	my $class = shift;
	my ($m1_ref,$m2_ref) = @_;
	my ($m1rows,$m1cols) = $m1_ref->matdim();
	my ($m2rows,$m2cols) = $m2_ref->matdim();

	unless ($m1rows == $m2rows) { # raise exception
	    die "IndexError: matrices don't match: $m1rows != $m2rows";
	}
	unless ($m1cols == $m2cols) { # raise exception
	    die "IndexError: matrices don't match: $m1cols != $m2cols";
	}

	my $result_ref = Matrix->new();

	my $m1_matrix_ref = $matrix_ref_of{ident $m1_ref};
	my $m2_matrix_ref = $matrix_ref_of{ident $m2_ref};
	my $result_matrix_ref = $matrix_ref_of{ident $result_ref};

	for my $i (range($m1rows)) {
	    for my $j (range($m2cols)) {
		$result_matrix_ref->[$i][$j] = $m1_matrix_ref->[$i][$j] + $m2_matrix_ref->[$i][$j];
	    }
	}

	return $result_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: mnonzero
    # Synopsys: Return new matrix with i,j set to 1 if corresponding element of argument is nonzero.
    #--------------------------------------------------------------------------------------
    sub mnonzero {
	my $class = shift;
	my $m1_ref = shift;

	my ($m1rows,$m1cols) = $m1_ref->matdim();
	my $m1_matrix_ref = $matrix_ref_of{ident $m1_ref};

	my $result_ref = Matrix->new();
	my $result_matrix_ref = $matrix_ref_of{ident $result_ref};

	for my $i (range($m1rows)) {
	    for my $j (range($m1cols)) {
		$result_matrix_ref->[$i][$j] = ($m1_matrix_ref->[$i][$j] != 0) ? 1 : 0;
	    }
	}

	return $result_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: msumrow
    # Synopsys: Return new column vector containing row sums of matrix argument.
    #--------------------------------------------------------------------------------------
    sub msumrow {
	my $class = shift;
	my $m1_ref = shift;

	my ($m1rows,$m1cols) = $m1_ref->matdim();
	my $m1_matrix_ref = $matrix_ref_of{ident $m1_ref};

	my $result_ref = Matrix->new();
	my $result_matrix_ref = $matrix_ref_of{ident $result_ref};

	for my $i (range($m1rows)) {
	    $result_matrix_ref->[$i][0] = 0;
	    for my $j (range($m1cols)) {
		$result_matrix_ref->[$i][0] += $m1_matrix_ref->[$i][$j];
	    }
	}
	return $result_ref;
    }

    #--------------------------------------------------------------------------------------
    # Function: XXX
    # Synopsys: 
    #--------------------------------------------------------------------------------------
    sub XXX {
	my $class = shift;
    }

    #######################################################################################
    # INSTANCE METHODS
    #######################################################################################
    #--------------------------------------------------------------------------------------
    # Function: START
    # Synopsys: Create empty matrix by default, check init_arg.
    #--------------------------------------------------------------------------------------
    sub BUILD {
        my ($self, $obj_ID, $arg_ref) = @_;

	# check initializers
	if (defined $arg_ref->{matrix_ref}) {
	    $matrix_ref_of{$obj_ID} = $arg_ref->{matrix_ref};
	    $self->check();
	} else {
	    $matrix_ref_of{$obj_ID} = [];  # empty matrix
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: check
    # Synopsys: Check that matrix is rectangular (or square).
    #--------------------------------------------------------------------------------------
    sub check {
	my $self = shift;

	my $matrix_ref = $matrix_ref_of{ident $self};
	if (@{$matrix_ref}) {  # non-empty??
	    my $num_cols = @{$matrix_ref->[0]};
	    for (my $i = 1; $i < @{$matrix_ref}; $i++) {
		croak "ERROR: variable number of columns in matrix" if ($num_cols != @{$matrix_ref->[$i]});
	    }
	}
    }

    #--------------------------------------------------------------------------------------
    # Function: matdim
    # Synopsys: Return matrix dimension.
    #--------------------------------------------------------------------------------------
    sub matdim {
	my $self = shift;
	my $matrix_ref = $matrix_ref_of{ident $self};
	my $rows = scalar(@{$matrix_ref});
	my $cols = $rows ? scalar(@{$matrix_ref->[0]}) : 0;
	return ($rows, $cols);
    }

    #--------------------------------------------------------------------------------------
    # Function: set_element
    # Synopsys: Set an element.  If element outside current dimensions, fill with zeroes.
    #           Indexes start at 0,0
    #--------------------------------------------------------------------------------------
    sub set_element {
	my $self = shift; my $obj_ID = ident $self;
	my $ii = shift;
	my $jj = shift;
	my $value = shift;
	my $fill = shift || 0;

	my ($dimx, $dimy) = $self->matdim();
	for (my $i = ($jj >= $dimy ? 0 : $dimx); $i <= ($ii > $dimx-1 ? $ii : $dimx-1); $i++) {
	    for (my $j = ($i >= $dimx ? 0 : $dimy); $j <= ($jj > $dimy-1 ? $jj : $dimy-1); $j++) {
		$matrix_ref_of{$obj_ID}->[$i][$j] = $fill;
	    }
	}
	$matrix_ref_of{$obj_ID}->[$ii][$jj] = $value;
    }

    #--------------------------------------------------------------------------------------
    # Function: get_element
    # Synopsys: Get an element.  Indexes start at 0,0
    #--------------------------------------------------------------------------------------
    sub get_element {
	my $self = shift; my $obj_ID = ident $self;
	my $i = shift;
	my $j = shift;
	return $matrix_ref_of{$obj_ID}->[$i][$j];
    }

    #--------------------------------------------------------------------------------------
    # Function: delete_row
    # Synopsys:
    #--------------------------------------------------------------------------------------
    sub delete_row {
	my $self = shift; my $obj_ID = ident $self;
	my $row_index = shift;

	splice @{$matrix_ref_of{$obj_ID}}, $row_index, 1;
    }

    #--------------------------------------------------------------------------------------
    # Function: delete_row
    # Synopsys:
    #--------------------------------------------------------------------------------------
    sub delete_column {
	my $self = shift; my $obj_ID = ident $self;
	my $col_index = shift;

	map {splice @{$_}, $col_index, 1} @{$matrix_ref_of{$obj_ID}};
    }

    #--------------------------------------------------------------------------------------
    # Function: sprint_matrix
    # Synopsys: Print matrix to string, formatting column widths.
    #--------------------------------------------------------------------------------------
    sub sprint_matrix {
	my $self = shift;

	my ($num_rows, $num_cols) = $self->matdim();
	my $matrix_ref = $matrix_ref_of{ident $self};

	my @column_width = ();
	my @elem_width = ();

	# column width is set by largest element in a given column
	for (my $j = 0; $j < $num_cols; $j++) {
	    $column_width[$j] = 4; # make cols at least 4 wide
	    for (my $i = 0; $i < $num_rows; $i++) {
		$column_width[$j] = max_numeric($column_width[$j],length($matrix_ref->[$i][$j]));
	    }
	}

	my $str;
	for (my $i = 0; $i < $num_rows; $i ++) {
	    for (my $j = 0; $j < $num_cols; $j ++) {
		# some elements are lists, some are scalars
		my $elem = $matrix_ref->[$i][$j];
		$elem = (ref $elem) ? (join ",",@{$matrix_ref->[$i][$j]}) : $elem;
		# if an empty list, substitute a placeholder
		$elem = ($elem eq "" ? "-" : $elem);
		$str .= sprintf(" | %-$column_width[$j]s", $elem);
	    }
	    $str .= "\n";
	}
	return $str;
    }
}


sub run_testcases {
    printn "run_testcases: Matrix package";

    my $m1_ref = Matrix->new({
	matrix_ref => [[1, 20000000, 0], [3000000, 4, 5]],
    });
    printn $m1_ref->sprint_matrix();

    my $m2_ref = Matrix->mnonzero($m1_ref);
    printn $m2_ref->sprint_matrix();

    my $m3_ref = Matrix->madd($m1_ref, $m2_ref);
    printn $m3_ref->sprint_matrix();

    my $m4_ref = Matrix->new({
	matrix_ref => [[1, 3, 0],
		       [2, 4, 5]],
    });
    printn $m4_ref->sprint_matrix();

    my $m5_ref = Matrix->new({
	matrix_ref => [[1, 3, 1, 0],
		       [5, 1, 2, 1],
		       [1, 2, 3, 2]],
    });
    printn $m5_ref->sprint_matrix();

    my $m6_ref = Matrix->mmult($m4_ref, $m5_ref);
    printn $m6_ref->sprint_matrix();
    
    my $m7_ref = Matrix->msumrow($m6_ref);
    printn $m7_ref->sprint_matrix();

    $m7_ref->set_element(0,3,11,1);
    printn $m7_ref->sprint_matrix();
    $m7_ref->set_element(3,1,22,2);
    printn $m7_ref->sprint_matrix();
    $m7_ref->set_element(3,5,33,3);
    printn $m7_ref->sprint_matrix();
    $m7_ref->set_element(4,6,44,4);
    printn $m7_ref->sprint_matrix();
    $m7_ref->set_element(6,2,55,5);
    printn $m7_ref->sprint_matrix();

    printn $m7_ref->get_element(3,6);

    $m7_ref->delete_row(1);
    printn $m7_ref->sprint_matrix();
    $m7_ref->delete_column(1);
    printn $m7_ref->sprint_matrix();
}


# Package BEGIN must return true value
return 1;

