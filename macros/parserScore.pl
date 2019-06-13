################################################################################
# WeBWorK Online Homework Delivery System
# Copyright &copy; 2000-2018 The WeBWorK Project, http://openwebwork.sf.net/
# $CVSHeader$
# 
# This program is free software; you can redistribute it and/or modify it under
# the terms of either: (a) the GNU General Public License as published by the
# Free Software Foundation; either version 2, or (at your option) any later
# version, or (b) the "Artistic License" which comes with this package.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See either the GNU General Public License or the
# Artistic License for more details.
################################################################################

=head1 NAME

F<parserScore.pl> - Implements a Score Math Object, intended for use by an applet
that scores something and inserts a score into a hidden answer blank.

=head1 DESCRIPTION

This file implements a Score Math Object class. Its value is always 1.
Its checker returns whatever was submitted in the answer blank, after checking it is a real in [0,1].
The idea is that some javascript applet would insert a number like 0 or 1 into a hidden
answer blank, and the student hits submit and gets whatever score was inserted.

=cut


loadMacros("MathObjects.pl");

sub _parserScore_init {
  main::PG_restricted_eval('sub Score {Score->new(@_)}');
}

package Score;
our @ISA = ('Value::Real');

sub new {
  my $self = shift;
  my $score = $self->SUPER::new(@_);
  Value::Error("A score must be a real number between 0 and 1") unless (Value::isReal($score) && ($score->value >= 0 || $score->value <= 1));
  $score->{isReal} = $score->{isValue} = $score->{isScore} = 1;
  return $score;
}

#
#  Override the class name to get better error messages
#
sub cmp_class {"a Score Value"}

sub cmp_defaults {(
  (shift)->SUPER::cmp_defaults,
  checker => sub {
    my ($correct, $student, $ansHash) = @_;
    Value::Error('A score must be a real number between 0 and 1')
      if !($student >= 0 && $student <= 1);
    return $student;
},
)}


1;
